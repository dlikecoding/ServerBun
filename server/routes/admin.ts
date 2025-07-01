import { sql } from '../db';
import * as fs from 'fs/promises';
import path from 'path';

import { Hono } from 'hono';
import { streamText } from 'hono/streaming';
import { deleteOldUserSession } from './authHelper/_cookies';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';

import { updateAccountStatus } from '../db/module/regUser';
import { insertErrorLog, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession } from '../middleware/validateAuth';

import { isCaptioningRunning, markTaskEnd, markTaskStart, taskStatusMiddleware } from '../middleware/isRuningTask';
import { importExternalPath, streamingImportMedia } from './importHelper/_imports';
import { preprocessMedia, processCaptioning, thumbAndHashGenerate } from '../service';
import { backupFiles, backupToDB, restoreToDB } from '../db/main';
import { deleteFile, isExist, removeEmptyDirs } from '../service/helper';

import { mediaUpdate, reduceFPS } from '../service/generators/reduceFps';

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

admin.get('/dashboard', async (c) => {
  try {
    const sysStatus = sql`
      SELECT process_medias, last_restore_time FROM multi_schema."ServerSystem" LIMIT 1`;

    const allUsers = sql`
      SELECT user_name, user_email, status, reg_user_id FROM multi_schema."RegisteredUser" reg WHERE role_type = 'user'`;

    const countMissed = sql`
      SELECT 
        COUNT(media_id) FILTER (WHERE thumb_created = FALSE) AS thumbnail,
        COUNT(media_id) FILTER (WHERE hash_code IS NULL) AS hashcode,
        COUNT(media_id) FILTER (WHERE caption IS NULL OR caption = '') AS caption
      FROM multi_schema."Media"`;

    const [[sys], users, [count]] = await Promise.all([sysStatus, allUsers, countMissed]);

    let lastbackupTime = 'N/A';

    const stat = (await isExist(Bun.env.DB_BACKUP)) ? await fs.stat(Bun.env.DB_BACKUP) : '';
    if (stat && stat.mtime) lastbackupTime = stat.mtime.toLocaleString();

    return c.json({ users: users, sysStatus: sys.process_medias, lastBackup: lastbackupTime, lastRestore: sys.last_restore_time, missedData: count }, 200);
  } catch (error) {
    console.log('admin.ts', 'dashboard', error);
    await insertErrorLog('admin.ts', 'dashboard', error);
    return c.json({ error: 'Failed to fetch dashboard admin' }, 500);
  }
});

admin.post('/internal', taskStatusMiddleware('importing'), isCaptioningRunning(), validateSchema('json', internalSchema), async (c) => {
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

admin.post('/external', taskStatusMiddleware('importing'), isCaptioningRunning(), validateSchema('json', externalSchema), async (c) => {
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

admin.get('/reindex', taskStatusMiddleware('importing'), isCaptioningRunning(), async (c) => {
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

admin.get('/backup', async (c) => {
  return streamText(c, async (stream) => {
    try {
      // Clean unuse camera type
      await cleanUpCameraType();

      // Remove empty Dirs which does not have any file in upload de
      await removeEmptyDirs(Bun.env.UPLOAD_PATH);

      // Backup database to a sql file
      const backupStatus = await backupToDB();
      const verifyBackup = await isExist(Bun.env.DB_BACKUP);

      if (!backupStatus || !verifyBackup) {
        await stream.writeln(`❌ Failed to backup data`);
        return;
      }

      if (!(await backupFiles(stream))) return;

      await stream.writeln(`✅ Backup processing had been completed successfully`);
      await stream.close();

      return;
    } catch (error) {
      console.log('admin.ts', 'admin.post/reindex', error);

      await stream.writeln(`❌ 500 Internal Server Error`);
      await insertErrorLog('admin.ts', 'admin.post/reindex', error);
    } finally {
      if (!stream.closed) await stream.close();
    }
  });
});

admin.get('/restore', async (c) => {
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
    await insertErrorLog('admin.ts', 'get/restore', err);
    console.error(err);
    return c.json({ error: 'Failed to restore data' }, 500);
  }
});

admin.put('/changeStatus', validateSchema('json', userAuthSchema), async (c) => {
  try {
    const { userEmail } = c.req.valid('json');

    const updatedUser = await updateAccountStatus(userEmail);
    if (!updatedUser) return c.json({ error: 'Failed to update user status' }, 500);

    deleteOldUserSession(userEmail);

    return c.json('Success!', 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'put/changeStatus', err);
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

admin.get('/all-logs', async (c) => {
  try {
    const sysLogs = sql`SELECT * FROM multi_schema."ErrorLog" ORDER BY mark_at DESC`;
    const userLogs = sql`SELECT * FROM multi_schema."UserLog" ORDER BY logged_at DESC`;

    const result = await Promise.all([sysLogs, userLogs]);

    if (!result) return c.json({ error: 'Failed to get logs System or User' }, 500);

    return c.json({ system: result[0], user: result[1] }, 200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'get/all-logs', err);
    console.error(err);
    return c.json({ error: 'Failed to get logs System and User' }, 500);
  }
});

const logsSchema = z.object({
  ids: z.array(z.coerce.number().min(1)),
  logType: z.enum(['system', 'user']),
});

admin.delete('/all-logs', validateSchema('json', logsSchema), async (c) => {
  try {
    const { ids, logType } = c.req.valid('json');

    const logIdsDeleted =
      logType === 'system'
        ? await sql`DELETE FROM multi_schema."ErrorLog"
        WHERE error_log_id IN ${sql(ids)} RETURNING error_log_id`
        : await sql`DELETE FROM multi_schema."UserLog"
        WHERE user_log_id IN ${sql(ids)} RETURNING user_log_id`;

    if (ids.length === logIdsDeleted.length) return c.json(204);
    return c.json(500);
  } catch (err) {
    await insertErrorLog('admin.ts', 'delete/all-logs', err);
    console.error(err);
    return c.json({ error: 'Failed to delete logs System/Account' }, 500);
  }
});

admin.get('/storageOptimize', taskStatusMiddleware('importing'), async (c) => {
  return streamText(c, async (stream) => {
    try {
      const userId = getUserBySession(c).userId;
      markTaskStart('importing', userId);

      const largeVideos = await sql`SELECT media_id, source_file, duration FROM multi_schema."Media" WHERE frame_rate > 60`;

      if (!largeVideos.length) {
        await stream.writeln(`✅ Finished Importing Multimedia!`);
        return;
      }

      for (const each of largeVideos) {
        // Reduce fps of each video, remove old file with a new one
        const originalSource = path.join(Bun.env.MAIN_PATH, each.source_file);

        const convertedPath = await reduceFPS(originalSource, stream);
        if (!convertedPath) {
          await stream.writeln(`❌ ${each.media_id}`);
          continue;
        }

        const mediaObj = mediaUpdate(convertedPath);
        await sql`UPDATE multi_schema."Media" SET ${sql(mediaObj)} WHERE media_id = ${each.media_id}`;

        // Delete old file
        await deleteFile(originalSource);
      }

      await stream.writeln(`✅ Finished Optimizing Multimedia's Storage!`);
      return;
    } catch (error) {
      console.log('admin.ts', 'admin.get/storageOptimize', error);

      await stream.writeln(`❌ 500 Internal Server Error`);
      await insertErrorLog('admin.ts', 'admin.get/storageOptimize', error);
    } finally {
      if (!stream.closed) await stream.close();
      markTaskEnd('importing');
    }
  });
});

admin.get('/rescan-thumb', async (c) => {
  try {
    const medias = await sql`SELECT media_id, source_file, thumb_path, file_type, selected_frame, duration FROM multi_schema."Media"`;
    console.log(medias.count);
    let count = 0;

    for (const media of medias) {
      const output = path.join(Bun.env.MAIN_PATH, media.thumb_path);

      if (await isExist(output)) continue;
      await thumbAndHashGenerate(media);

      console.log(++count);
    }

    return c.json(200);
  } catch (err) {
    await insertErrorLog('admin.ts', 'delete/all-logs', err);
    console.error(err);
    return c.json({ error: 'Failed to delete logs System/Account' }, 500);
  }
});

export default admin;

const cleanUpCameraType = async () => {
  return await sql`
    DELETE FROM multi_schema."CameraType" AS cm 
    WHERE cm.camera_id = (
        SELECT cm.camera_id FROM multi_schema."CameraType" AS cm 
        LEFT JOIN multi_schema."Media" AS md ON md.camera_type = cm.camera_id
        WHERE media_id IS NULL
    )`;
};
