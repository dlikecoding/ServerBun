import { Hono } from 'hono';
import { deleteOldUserSession } from './authHelper/_cookies';

import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';
import { fetchAllRegisteredUsers, updateAccountStatus } from '../db/module/regUser';
import { insertMediaToDB } from '../db/maintain';
import { deleteImportMedia } from '../db/module/media';
import { processMedias } from '../service';
import { processMediaStatus, updateProcessMediaStatus } from '../db/module/system';
import { getUserBySession, isAdmin } from '../middleware/validateAuth';

const admin = new Hono();

const userAuthSchema = z.object({
  userEmail: z.string().email(),
});

admin.get('/dashboard', isAdmin, async (c) => {
  const allUsers = await fetchAllRegisteredUsers();
  return c.json(allUsers, 200);
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

admin.get('/import', isAdmin, async (c) => {
  const isExist = await processMediaStatus();
  if (isExist === 1) return c.json('System has already been initialized', 200);
  await updateProcessMediaStatus();

  const userId = getUserBySession(c).userId;

  const exitCode = await insertMediaToDB(userId, Bun.env.PHOTO_PATH);
  if (exitCode !== 0) return c.json({ error: 'Failed to Import media to account' }, 400);

  await processMedias();

  await deleteImportMedia();

  // await backupToDB();

  return c.json('Success', 200);
});

// admin.get('/test', async (c) => {
//   const isInitSys = await processMediaStatus();
//   console.log(isInitSys === 1);
//   return c.json('Success', 200);
// });

export default admin;
