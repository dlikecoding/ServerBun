import { deleteCookie, getSignedCookie, setSignedCookie } from 'hono/cookie';
import type { Context } from 'hono';
import crypto, { type UUID } from 'crypto';
import { z } from 'zod';
import { isNotDevMode, isProduction } from '../../init_sys';

export const SESSION_KEY = 'auth_token';
export const SET_USER_SESSION = 'user_session_id';

export interface UserType {
  userId: UUID;
  userEmail: string;
  userName: string;
  roleType: string;
  status: string;
}

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
    secure: isProduction,
    ...(isProduction ? { domain: Bun.env.DOMAIN_NAME } : {}),
  });
};

export const getSecureCookie = async (c: Context, name: string) => {
  const cookie = await getSignedCookie(c, Bun.env.SECRET_KEY, name);
  return cookie && typeof cookie === 'string' ? JSON.parse(cookie) : null;
};

export const clearCookie = (c: Context, name: string) => {
  deleteCookie(c, name);
};

export const createAuthSession = async (c: Context, user: UserType) => {
  deleteOldUserSession(user.userEmail);

  const sessionId = generateSid();
  sessionStore.set(sessionId, user);

  await setSignedCookie(c, SESSION_KEY, sessionId, Bun.env.SECRET_KEY, {
    httpOnly: true,
    path: '/',
    maxAge: 24 * 60 * 60, // 1 day expiration
    sameSite: isNotDevMode ? 'Strict' : 'Lax',
    secure: isProduction,
    ...(isProduction ? { domain: Bun.env.DOMAIN_NAME } : {}),
  });
};

const generateSid = () => crypto.randomBytes(32).toString('hex');

/** Remove old session everytime a user relogin to the server */
export const deleteOldUserSession = (userEmail: string) => {
  sessionStore.forEach((userValue: UserType, sessionId: string) => {
    if (userValue.userEmail === userEmail) sessionStore.delete(sessionId); // console.log(`${sessionId}: ${userValue.email}`);
  });
};
