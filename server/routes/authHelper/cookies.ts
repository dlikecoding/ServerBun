import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import type { Context } from 'hono';
import { z } from 'zod';

export const userAuthSchema = z.object({
  username: z
    .string()
    .regex(/^[a-zA-Z0-9\s]*$/, 'The string should not contain special characters')
    .optional(),
  email: z.string().email('Invalid email address'),
});

export const setSecureCookie = (c: Context, name: string, value: object, secure = false) => {
  setCookie(c, name, JSON.stringify(value), { httpOnly: true, maxAge: 600, secure });
};

export const getSecureCookie = (c: Context, name: string) => {
  const cookie = getCookie(c, name);
  return cookie ? JSON.parse(cookie) : null;
};

export const clearCookie = (c: Context, name: string) => {
  deleteCookie(c, name);
};
