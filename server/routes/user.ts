import { Hono } from 'hono';

import { clearCookie, SESSION_KEY, sessionStore, SET_USER_SESSION } from './authHelper/_cookies';
import { getUserBySession } from '../middleware/validateAuth';

const user = new Hono();

user.get('/verified', async (c) => {
  const userInfo = getUserBySession(c);
  return c.json(userInfo, 200);
});

user.get('/logout', async (c) => {
  const sessionId = c.get(SET_USER_SESSION);
  sessionStore.delete(sessionId);
  clearCookie(c, SESSION_KEY);

  return c.json('Successfully logout!', 200);
});

// user.get('/', async (c) => {
// try {
//   const user = await findAccountByEmail('i9@mail.com');
//   return c.json(user);
// } catch (err) {
//   console.error(err);
//   return c.json({ error: 'Failed to fetch Account' }, 500);
// }
// });

export default user;
