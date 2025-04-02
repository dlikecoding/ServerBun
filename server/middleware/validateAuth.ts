import { getSignedCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';
import { SESSION_KEY, sessionStore, SET_USER_SESSION, type UserType } from '../routes/authHelper/_cookies';
import type { Context } from 'hono';

export const getUserBySession = (c: Context): UserType => {
  const sessionId = c.get(SET_USER_SESSION);
  return sessionStore.get(sessionId);
};

export const isAuthenticate = createMiddleware(async (c, next) => {
  const sessionId = await getSignedCookie(c, Bun.env.SECRET_KEY, SESSION_KEY);
  if (sessionId && sessionStore.has(sessionId)) {
    c.set(SET_USER_SESSION, sessionId);
    return await next();
  }
  return c.json({ error: 'Warning: Unauthorized Access' }, 401);
});

export const isAdmin = createMiddleware(async (c, next) => {
  const adminInfo: UserType = getUserBySession(c);
  if (adminInfo.roleType !== 'admin') return c.json({ error: 'Warning:  Unauthorized Access Attempt – Permission Denied' }, 403);
  return await next();
});
