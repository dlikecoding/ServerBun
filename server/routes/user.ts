import { Hono } from 'hono';

import { sessionStore, SET_USER_SESSION } from './authHelper/_cookies';

const user = new Hono();

user.get('/verified', async (c) => {
  const sessionId = c.get(SET_USER_SESSION);

  const userInfo = sessionStore.get(sessionId);
  return c.json(userInfo, 200);
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
