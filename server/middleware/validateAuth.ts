import type { Context } from 'hono';
import { getConnInfo } from 'hono/bun';
import { getSignedCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';
import { SESSION_KEY, sessionStore, SET_USER_SESSION, type UserType } from '../routes/authHelper/_cookies';
import { sql } from '../db';

export const getUserBySession = (c: Context): UserType => {
  const sessionId = c.get(SET_USER_SESSION);
  if (!sessionId) return {} as UserType;
  return sessionStore.get(sessionId);
};

export const logUserInDB = (isLoggedIn: boolean = false) =>
  createMiddleware(async (c, next) => {
    try {
      const info = getConnInfo(c);
      const uAgent = c.req.header('user-agent');

      let userLog = { user_agent: uAgent, ip_address: info.remote.address };

      if (isLoggedIn) {
        userLog = { ...userLog, ...{ last_logged_in: 'NOW()' } };
      }
      await sql`INSERT INTO "multi_schema"."UserLog" ${sql(userLog)}`.catch((e) => console.log('Failed to Log User on Login', e));

      return await next();
    } catch (error) {
      console.log('middleware/validate - logUserInDB error');
      return c.json({ error: 'An error occurs while user is trying to sign in' }, 500);
    }
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
