import { Hono } from 'hono';
import { findAccountByEmail } from '../db/module/account';

const users = new Hono();

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
