import { Hono } from 'hono';

import { z } from 'zod'; // To create a schema to validate post req
import { deleteMedias, fetchCameraType, fetchMediaCount, fetchMediaEachYear, fetchMediaOfEachMonth, updateMedias } from '../db/module/media';
import { validateSchema } from '../modules/validate';

const medias = new Hono();

// Make sure all of id is numbers
// medias.get('/:id{[0-9]+}', (c) => {
//   return c.json({ homepage: 'YOU ARE HOME' });
// });

const yearSchema = z.object({
  year: z
    .string()
    .regex(/^(\d{4}|0)$/, 'Invalid year format') // Matches 0 or 4 digits
    .optional(),
});

const updateSchema = z.object({
  mediaIds: z.array(z.number()),
  updateKey: z.enum(['Favorite', 'Deleted', 'Hidden']), // If updateKey is not in Favorite, Deleted, Hidden ... return error
  updateValue: z.boolean(),
});

const deleteSchema = z.object({
  mediasToDel: z.array(z.number()),
});

medias.get('/', validateSchema('query', yearSchema), async (c) => {
  const { year } = c.req.valid('query');

  try {
    const yearInt = parseInt(year, 10);

    // In the case year = 0 or 2020, it will fect all months or all months within 2020 // otherwise, fetch all years.
    const mediaData = !isNaN(yearInt) ? await fetchMediaOfEachMonth(yearInt) : await fetchMediaEachYear();

    return c.json(mediaData, 200);
  } catch (error) {
    return c.text('Failed to fetch media', 500);
  }
});

medias.get('/statistic', async (c) => {
  try {
    const result = await fetchMediaCount();

    return c.json(result, 200);
  } catch (error) {
    console.error('Error fetching media:', error);
    return c.text('Failed to fetch media', 500);
  }
});

medias.get('/devices', async (c) => {
  try {
    return c.json(await fetchCameraType(), 200);
  } catch (error) {
    console.error('Error fetching media:', error);
    return c.text('Failed to fetch media', 500);
  }
});

medias.put('/', validateSchema('json', updateSchema), async (c) => {
  const { mediaIds, updateKey, updateValue } = c.req.valid('json');
  const result = await updateMedias(mediaIds, updateKey, updateValue);

  if (result) return c.text('Success', 204);
  return c.text('Failed to fetch media', 500);
});

medias.delete('/', validateSchema('json', deleteSchema), async (c) => {
  const { mediasToDel } = c.req.valid('json');

  const result = await deleteMedias(mediasToDel);
  if (result) return c.text('Success', 204);

  return c.text('Failed to fetch media', 500);
});

export default medias;
