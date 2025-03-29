import { zValidator } from '@hono/zod-validator';
import type { ValidationTargets } from 'hono/types';
import type { ZodSchema } from 'zod';

export const validateSchema = (type: keyof ValidationTargets, schema: ZodSchema) =>
  zValidator(type, schema, (result, c) => {
    if (!result.success) return c.json({ error: result.error.errors[0].message }, 400);
  });
