import { Hono } from 'hono';
import { findAccountByEmail } from '../db/module/account';

import { sessionStore, SET_USER_SESSION } from './authHelper/_cookies';

const users = new Hono();

users.get('/check', async (c) => {
  const sessionId = c.get(SET_USER_SESSION);

  // const sessionId = await getSignedCookie(c, Bun.env.SECRET_KEY, SESSION_KEY);
  // if (!sessionStore.has(sessionId)) return c.text('Unauthorized access', 200);

  console.log(sessionStore.get(sessionId));
  return c.json(sessionStore.get(sessionId), 200);
});

users.get('/', async (c) => {
  try {
    const user = await findAccountByEmail('i9@mail.com');

    return c.json(user);
  } catch (err) {
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

export default users;
