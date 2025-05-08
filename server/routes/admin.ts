import { Hono } from 'hono';
import { streamText } from 'hono/streaming';
import { deleteOldUserSession } from './authHelper/_cookies';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';

import { fetchAllUsers, updateAccountStatus } from '../db/module/regUser';
import { insertErrorLog, processMediaStatus, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';

import { markTaskEnd, markTaskStart, taskImportStatusMiddleware } from '../middleware/isRuningTask';
import { prepareExternalImporting, streamingImportMedia } from './importHelper/_imports';
import { processCaptioning } from '../service';

const admin = new Hono();

const userAuthSchema = z.object({
  userEmail: z.string().email(),
});

const sourcePathSchema = z
  .string()
  .max(256, 'Path too long')
  .regex(/^\/(Volumes|home)(\/[a-zA-Z0-9_-]+)*\/?$/, 'Path must be under /Volumes or /home and contain valid characters')
  .refine((p) => !p.includes('..'), {
    message: 'Path must not contain parent directory traversal',
  })
  .optional();

const isAiModeSchema = z.object({
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

admin.post('/import', isAdmin, taskImportStatusMiddleware, validateSchema('json', isAiModeSchema), async (c) => {
  return streamText(c, async (stream) => {
    const userId = getUserBySession(c).userId;
    const { sourcePath, aimode } = c.req.valid('json');
    try {
      const processPath = sourcePath ? await prepareExternalImporting(sourcePath, stream) : Bun.env.PHOTO_PATH;
      if (!processPath) return;

      markTaskStart('importing');
      // await stream.writeln('⏳ Processing media files started. Please wait...');

      const importing = await streamingImportMedia(stream, userId, processPath);
      if (!importing) return;

      await updateProcessMediaStatus(); // update server status of created media
      await stream.writeln('✅ Finished Importing Multimedia!');
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

// if (IS_IN_PROCESSING.status) {
//   await stream.writeln('❌ Server is currently processing data. Please try again later.');
//   return;
// }
