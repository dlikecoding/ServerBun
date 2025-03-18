import { deleteCookie, getSignedCookie, setSignedCookie } from 'hono/cookie';
import type { Context } from 'hono';
import crypto from 'crypto';
import { z } from 'zod';
import { createMiddleware } from 'hono/factory';

const isNotDevMode: boolean = Bun.env.NODE_ENV !== 'dev';

export const sessionStore = new Map(); // In-memory session store

export const userAuthSchema = z.object({
  username: z
    .string()
    .regex(/^[a-zA-Z0-9\s]*$/, 'The string should not contain special characters')
    .optional(),
  email: z.string().email('Invalid email address'),
});

export const setSecureCookie = async (c: Context, name: string, value: object) => {
  await setSignedCookie(c, name, JSON.stringify(value), Bun.env.SECRET_KEY, {
    httpOnly: true,
    maxAge: 15, // Only 15s
    sameSite: isNotDevMode ? 'Strict' : 'Lax',
    secure: isNotDevMode,
  });
};

export const getSecureCookie = async (c: Context, name: string) => {
  const cookie = await getSignedCookie(c, Bun.env.SECRET_KEY, name);
  return cookie && typeof cookie === 'string' ? JSON.parse(cookie) : null;
};

export const clearCookie = (c: Context, name: string) => {
  deleteCookie(c, name);
};

const generateSid = () => crypto.randomBytes(32).toString('hex');

export const createAuthSession = async (c: Context, user: object) => {
  const sessionId = generateSid();

  sessionStore.set(sessionId, { user });

  await setSignedCookie(c, 'auth_token', sessionId, Bun.env.SECRET_KEY, {
    httpOnly: true,
    path: '/',
    maxAge: 24 * 60 * 60, // 1 day expiration
    sameSite: isNotDevMode ? 'Strict' : 'Lax',
    secure: isNotDevMode,
  });
};

export const isAuthenticate = createMiddleware(async (c, next) => {
  const sessionId = await getSignedCookie(c, Bun.env.SECRET_KEY, 'auth_token');
  if (sessionId && sessionStore.has(sessionId)) return await next();
  return c.text('Unauthorized access', 401);
  // serveStatic({ root: './dist' });
  // return serveStatic({ path: './dist/index.html' })(c, next);

  // return c.redirect('./dist/index.html');
});
