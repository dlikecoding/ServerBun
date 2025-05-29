import { Hono } from 'hono';

import { clearCookie, SESSION_KEY, sessionStore, SET_USER_SESSION } from './authHelper/_cookies';
import { getUserBySession } from '../middleware/validateAuth';
import { diskCapacity } from '../service/helper';
import { insertErrorLog } from '../db/module/system';
import { sumSizeMediaType } from '../db/module/media';

const user = new Hono();

user.get('/verified', async (c) => {
  const userInfo = getUserBySession(c);
  if (userInfo) return c.json(userInfo, 200);

  await insertErrorLog('routes/user.ts', 'get/verified', 'User infor not found');
  return c.json({ error: 'Failed to verified account' }, 500);
});

user.get('/logout', async (c) => {
  try {
    const sessionId = c.get(SET_USER_SESSION);
    sessionStore.delete(sessionId);
    clearCookie(c, SESSION_KEY);

    return c.json('Successfully logout!', 200);
  } catch (error) {
    console.error(error);
    await insertErrorLog('routes/user.ts', 'get/logout', error);
    return c.json({ error: 'Failed to logout account' }, 500);
  }
});

user.get('/serverCapacity', async (c) => {
  try {
    const diskCap = diskCapacity(Bun.env.MAIN_PATH);
    const sizeFileType = sumSizeMediaType();

    const [diskInfo, typesInfo] = await Promise.all([diskCap, sizeFileType]);
    if (diskInfo && typesInfo) return c.json({ ...diskInfo, ...typesInfo });
  } catch (err) {
    console.error(err);
    await insertErrorLog('routes/user.ts', 'get/logout', err);
  }

  return c.json({ error: 'Failed to fetch Account' }, 500);
});

export default user;
