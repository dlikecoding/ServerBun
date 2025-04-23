import { Hono } from 'hono';
import { deleteOldUserSession } from './authHelper/_cookies';

import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';
import { fetchAllUsers, updateAccountStatus } from '../db/module/regUser';
import { countFiles, insertMediaToDB, renameAllFiles } from '../db/main';
import { processMedias } from '../service';
import { insertErrorLog, processMediaStatus, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';
import { streamText } from 'hono/streaming';
import { isExist } from '../service/fsHelper';

const admin = new Hono();

const userAuthSchema = z.object({
  userEmail: z.string().email(),
});

admin.get('/dashboard', isAdmin, async (c) => {
  try {
    const allUsers = await fetchAllUsers();
    const isExist = await processMediaStatus();

    return c.json({ users: allUsers, sysStatus: isExist }, 200);
  } catch (error) {
    await insertErrorLog('admin.ts', 'dashboard', error);
    return c.json({ error: 'Failed to fetch users' }, 500);
  }
});

admin.get('/import', isAdmin, async (c) => {
  return streamText(c, async (stream) => {
    const userId = getUserBySession(c).userId;

    try {
      stream.onAbort(() => {
        console.warn('Client aborted the stream!');
      });
      await stream.writeln('Processing media files started. Please wait...');

      const isValidDir = isExist(Bun.env.PHOTO_PATH);
      if (!isValidDir) {
        await stream.writeln('❌ Directory not found. Please ensure the directory exists');
        return;
      }

      const totalFiles = await countFiles(Bun.env.PHOTO_PATH);
      if (!totalFiles) {
        await stream.writeln('❌ No files found in the current directory. Please check if the directory contains media files.');
        return;
      }

      const rename = await renameAllFiles(Bun.env.PHOTO_PATH);
      if (!rename) {
        await stream.writeln('❌ Failed to rename files. Please check file permissions and the files path are valid.');
        return;
      }

      const insertStatus = await insertMediaToDB(userId, Bun.env.PHOTO_PATH);
      if (!insertStatus) {
        await stream.writeln('❌ Failed to importing medias to database.');
        return;
      }

      const processSts = await processMedias(stream); // create thumbnail and hash keys
      if (!processSts) {
        await stream.writeln('❌ Failed to create thumb for medias');
        return;
      }

      await updateProcessMediaStatus(); // update server status of created media
      await stream.writeln('✅ Finished Importing Multimedia!');
    } catch (error) {
      await stream.writeln(`❌ 500 Internal Server Error`);
      console.log(error);
      await insertErrorLog('admin.ts', 'import', error);
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
