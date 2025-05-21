import { Hono } from 'hono';
import { streamText } from 'hono/streaming';
import { deleteOldUserSession } from './authHelper/_cookies';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';

import { updateAccountStatus } from '../db/module/regUser';
import { insertErrorLog, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';

import { markTaskEnd, markTaskStart, taskStatusMiddleware } from '../middleware/isRuningTask';
import { importExternalPath, streamingImportMedia } from './importHelper/_imports';
import { preprocessMedia, processCaptioning } from '../service';
import { backupToDB, restoreToDB } from '../db/main';
import { isExist } from '../service/helper';
import { sql } from '../db';
import * as fs from 'fs/promises';

const admin = new Hono();

const userAuthSchema = z.object({
  userEmail: z.string().email(),
});

const sourcePathSchema = z
  .string()
  .max(256, 'Path too long')
  .regex(/^\/(Volumes|home|Users)(\/[a-zA-Z0-9_-]+)*\/?$/, 'Path must be under /Volumes or /home and contain valid characters')
  .refine((p) => !p.includes('..'), {
    message: 'Path must not contain parent directory traversal',
  })
  .optional();

const internalSchema = z.object({
  aimode: z.coerce.number().min(0).max(1).default(0).optional(),
});

const externalSchema = z.object({
  aimode: z.coerce.number().min(0).max(1).default(0).optional(),
  sourcePath: sourcePathSchema,
});

admin.get('/dashboard', isAdmin, async (c) => {
  try {
    const sysStatus = sql`
      SELECT process_medias, last_restore_time FROM multi_schema."ServerSystem" LIMIT 1`;

    const allUsers = sql`
      SELECT user_name, user_email, status, reg_user_id FROM multi_schema."RegisteredUser" reg WHERE role_type = 'user'`;

    const countMissed = sql`
      SELECT 
        COUNT(media_id) FILTER (WHERE thumb_height IS NULL) AS thumbnail,
        COUNT(media_id) FILTER (WHERE hash_code IS NULL OR hash_code = '') AS hashcode,
        COUNT(media_id) FILTER (WHERE caption IS NULL OR caption = '') AS caption
      FROM multi_schema."Media"`;

    const [[sys], users, [count]] = await Promise.all([sysStatus, allUsers, countMissed]);

    const stat = await fs.stat(Bun.env.DB_BACKUP);

    return c.json({ users: users, sysStatus: sys.process_medias, lastBackup: stat.birthtime, lastRestore: sys.last_restore_time, missedData: count }, 200);
  } catch (error) {
    console.log('admin.ts', 'dashboard', error);
    await insertErrorLog('admin.ts', 'dashboard', error);
    return c.json({ error: 'Failed to fetch dashboard admin' }, 500);
  }
});

admin.post('/internal', isAdmin, taskStatusMiddleware('importing'), validateSchema('json', internalSchema), async (c) => {
  return streamText(c, async (stream) => {
    try {
      const userId = getUserBySession(c).userId;
      const { aimode } = c.req.valid('json');

      markTaskStart('importing', userId);
      const importing = await streamingImportMedia(Bun.env.PHOTO_PATH, userId, stream);
      if (!importing) return;

      await updateProcessMediaStatus(); // update server status of created media

      await stream.writeln(`✅ Finished Importing Multimedia! ${aimode ? 'Images Analysis is running in background...' : ''}`);
      await stream.close();

      if (!aimode) return; //Finished Importing

      // Generate captions for medias in the background
      return await processCaptioning();
    } catch (error) {
      console.log(error);

      await stream.writeln(`❌ 500 Internal Server Error`);
      await insertErrorLog('admin.ts', 'admin.post/import', error);
    } finally {
      if (!stream.closed) await stream.close();
      markTaskEnd('importing');
    }
  });
});

admin.post('/external', isAdmin, taskStatusMiddleware('importing'), validateSchema('json', externalSchema), async (c) => {
  return streamText(c, async (stream) => {
    try {
      const userId = getUserBySession(c).userId;
      const { sourcePath, aimode } = c.req.valid('json');

      const processPath = await importExternalPath(sourcePath, stream);
      if (!processPath) return;
      markTaskStart('importing', userId);

      const importing = await streamingImportMedia(processPath, userId, stream);
      if (!importing) return;

      await updateProcessMediaStatus(); // update server status of created media

      await stream.writeln(`✅ Finished Importing Multimedia! ${aimode ? 'Images Analysis is running in background...' : ''}`);
      await stream.close();

      if (!aimode) return; //Finished Importing

      // Generate captions for medias in the background
      return await processCaptioning();
    } catch (error) {
      console.log('admin.ts', 'admin.post/import', error);

      await stream.writeln(`❌ 500 Internal Server Error`);
      await insertErrorLog('admin.ts', 'admin.post/import', error);
    } finally {
      if (!stream.closed) await stream.close();
      markTaskEnd('importing');
    }
  });
});

admin.get('/reindex', isAdmin, taskStatusMiddleware('importing'), async (c) => {
  return streamText(c, async (stream) => {
    try {
      const userId = getUserBySession(c).userId;
      markTaskStart('importing', userId);

      await preprocessMedia(stream);
      await stream.writeln(`✅ Finished Importing Multimedia!`);
      await stream.close();

      return await processCaptioning();
    } catch (error) {
      console.log('admin.ts', 'admin.post/reindex', error);

      await stream.writeln(`❌ 500 Internal Server Error`);
      await insertErrorLog('admin.ts', 'admin.post/reindex', error);
    } finally {
      if (!stream.closed) await stream.close();
      markTaskEnd('importing');
    }
  });
});

admin.get('/backup', isAdmin, async (c) => {
  try {
    const backupStatus = await backupToDB();
    if (!backupStatus) return c.json({ error: 'Failed to backup data' }, 500);

    const verifyBackup = await isExist(Bun.env.DB_BACKUP);
    if (!verifyBackup) return c.json({ error: 'Backup data is not exist' }, 500);

    return c.json({ message: 'Backup data successfully!' }, 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'backup', err);
    console.error(err);
    return c.json({ error: 'Failed to backup data' }, 500);
  }
});

admin.get('/restore', isAdmin, async (c) => {
  try {
    // Restore to database if backup database exists
    if (!(await isExist(Bun.env.DB_BACKUP))) return c.json({ error: 'Backup before restore file' }, 200);

    const restoreStatus = await restoreToDB();
    if (!restoreStatus) return c.json({ error: 'Failed to restore data' }, 500);

    await sql`
      UPDATE multi_schema."ServerSystem" SET last_restore_time = NOW() 
      WHERE system_id = (
        SELECT system_id FROM multi_schema."ServerSystem" LIMIT 1)`;

    return c.json({ message: 'Restore data successfully!' }, 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'restore', err);
    console.error(err);
    return c.json({ error: 'Failed to restore data' }, 500);
  }
});

admin.put('/changeStatus', isAdmin, validateSchema('json', userAuthSchema), async (c) => {
  try {
    const { userEmail } = c.req.valid('json');

    const updatedUser = await updateAccountStatus(userEmail);
    if (!updatedUser) return c.json({ error: 'Failed to update user status' }, 500);

    deleteOldUserSession(userEmail);

    return c.json('Success!', 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'changeStatus', err);
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

admin.get('/cleanup', isAdmin, async (c) => {
  try {
    // Get all camera id does not relate to any photo
    const cleanUpCameraType = sql`
      DELETE FROM multi_schema."CameraType" AS cm 
        WHERE cm.camera_id = (
          SELECT cm.camera_id FROM "CameraType" AS cm 
          LEFT JOIN "Media" AS md ON md.camera_type = cm.camera_id
        WHERE media_id IS NULL)`;

    // remove all empty StoreUpload directories
    const [cleanCM] = await Promise.all([cleanUpCameraType]);

    return c.json('Success!', 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'changeStatus', err);
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

export default admin;
