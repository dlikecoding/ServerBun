import { Hono } from 'hono';
import { sessionStore, SET_USER_SESSION } from './authHelper/_cookies';
import { createMiddleware } from 'hono/factory';
import { fetchAllUserGuests } from '../db/module/guest';
import { updateAccountStatus } from '../db/module/account';
import { z } from 'zod';
import { validateSchema } from '../modules/validate';

const admin = new Hono();

const userAuthSchema = z.object({
  accountId: z.number(),
  status: z.boolean(),
});

const isAdmin = createMiddleware(async (c, next) => {
  const sessionId = c.get(SET_USER_SESSION);
  const roleType = sessionStore.get(sessionId).roleType;
  if (roleType !== 'admin') return c.json({ error: 'Unauthorized access as admin' }, 401);
  return await next();
});

admin.get('/dashboard', isAdmin, async (c) => {
  const allUsers = await fetchAllUserGuests();
  return c.json(allUsers, 200);
});

admin.put('/changeStatus', isAdmin, validateSchema('json', userAuthSchema), async (c) => {
  try {
    const { accountId, status } = c.req.valid('json');

    const updateStatus = status ? 'active' : 'suspended';
    const updatedUser = await updateAccountStatus(accountId, updateStatus);

    if (!updatedUser) return c.json({ error: 'Failed to update user status' }, 200);

    return c.json('Success!', 200);
  } catch (err) {
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

export default admin;
