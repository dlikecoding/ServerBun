import type { Context } from 'hono';
import { getConnInfo } from 'hono/bun';
import { getSignedCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';
import { SESSION_KEY, sessionStore, SET_USER_SESSION, type UserType } from '../routes/authHelper/_cookies';

export const getUserBySession = (c: Context): UserType => {
  const sessionId = c.get(SET_USER_SESSION);
  return sessionStore.get(sessionId);
};

export const logUserInDB = createMiddleware(async (c, next) => {
  const info = getConnInfo(c);
  console.log(info);
  return await next();
});

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
  if (adminInfo && adminInfo.roleType === 'admin') return await next();

  return c.json({ error: 'Warning:  Unauthorized Access Attempt – Permission Denied' }, 403);
});
