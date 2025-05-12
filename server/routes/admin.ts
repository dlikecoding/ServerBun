import { Hono } from 'hono';
import { streamText } from 'hono/streaming';
import { deleteOldUserSession } from './authHelper/_cookies';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';

import { fetchAllUsers, updateAccountStatus } from '../db/module/regUser';
import { insertErrorLog, processMediaStatus, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';

import { markTaskEnd, markTaskStart, taskStatusMiddleware } from '../middleware/isRuningTask';
import { importExternalPath, streamingImportMedia } from './importHelper/_imports';
import { processCaptioning } from '../service';
import { backupToDB, restoreToDB } from '../db/main';
import { isExist } from '../service/helper';

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
    const allUsers = await fetchAllUsers();
    const isMainImportExist = await processMediaStatus();

    return c.json({ users: allUsers, sysStatus: isMainImportExist }, 200);
  } catch (error) {
    await insertErrorLog('admin.ts', 'dashboard', error);
    return c.json({ error: 'Failed to fetch users' }, 500);
  }
});

admin.post('/internal', isAdmin, taskStatusMiddleware('importing'), validateSchema('json', internalSchema), async (c) => {
  return streamText(c, async (stream) => {
    const userId = getUserBySession(c).userId;
    const { aimode } = c.req.valid('json');

    try {
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
    const userId = getUserBySession(c).userId;
    const { sourcePath, aimode } = c.req.valid('json');
    try {
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

admin.get('/backup', isAdmin, async (c) => {
  try {
    const backupStatus = await backupToDB();
    return c.json({ status: backupStatus }, 200);
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
    return c.json({ status: restoreStatus }, 200);
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

export default admin;
