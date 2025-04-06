import { Hono } from 'hono';
import { deleteOldUserSession, IS_IN_PROCESSING } from './authHelper/_cookies';

import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';
import { fetchAllRegisteredUsers, updateAccountStatus } from '../db/module/regUser';
import { countFiles, insertMediaToDB, renameAllFiles } from '../db/main';
import { processMedias } from '../service';
import { processMediaStatus, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';
import { streamText } from 'hono/streaming';
import { isExist } from '../service/fsHelper';

const admin = new Hono();

const userAuthSchema = z.object({
  userEmail: z.string().email(),
});

admin.get('/dashboard', isAdmin, async (c) => {
  const allUsers = await fetchAllRegisteredUsers();
  const isExist = await processMediaStatus();

  return c.json({ users: allUsers, sysStatus: isExist }, 200);
});

admin.get('/import', isAdmin, async (c) => {
  return streamText(c, async (stream) => {
    if (IS_IN_PROCESSING.status) {
      await stream.writeln('❌ Server is currently processing data. Please try again later.');
      return;
    }

    IS_IN_PROCESSING.status = true;

    const userId = getUserBySession(c).userId;

    try {
      stream.onAbort(() => {
        console.warn('Client aborted the stream!');
      });
      await stream.writeln('Processing media files started. Please wait...');

      const isValidDir = isExist(Bun.env.PHOTO_PATH);
      if (!isValidDir) {
        await stream.writeln('Error: Directory not found. Please ensure the directory exists');
        return;
      }

      const totalFiles = await countFiles(Bun.env.PHOTO_PATH);
      if (!totalFiles) {
        await stream.writeln('Warning: No files found in the current directory. Please check if the directory contains media files.');
        return;
      }

      const rename = await renameAllFiles(Bun.env.PHOTO_PATH);
      if (!rename) {
        await stream.writeln('Error: Failed to rename files. Please check file permissions and the files path are valid.');
        return;
      }

      await insertMediaToDB(userId, Bun.env.PHOTO_PATH, stream, totalFiles);

      await processMedias(stream); // create thumbnail and hash keys

      await updateProcessMediaStatus(); // update server status of created media
      await stream.writeln('✅ Finished Importing Multimedia!');

      IS_IN_PROCESSING.status = false;
    } catch (error) {
      await stream.writeln(`Error: 500 Internal Server Error`);
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
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

export default admin;
