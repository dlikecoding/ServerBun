import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod'; // To create a schema to validate post req
import { fetchCameraType, fetchMediaCount, fetchMediaEachYear, fetchMediaOfEachMonth, updateMedias } from '../db/module/media';

const medias = new Hono();

// Make sure all of id is numbers
medias.get('/:id{[0-9]+}', (c) => {
  return c.json({ homepage: 'YOU ARE HOME' });
});

medias.get('/', async (c) => {
  const { year } = c.req.query();

  try {
    let fetchAllMedia;

    if (!year) {
      fetchAllMedia = await fetchMediaEachYear();
    } else if (year === 'all') {
      fetchAllMedia = await fetchMediaOfEachMonth(0);
    } else {
      const yearInt = parseInt(year);
      if (isNaN(yearInt)) {
        return c.json({ error: 'Invalid year parameter' }, 400);
      }
      fetchAllMedia = await fetchMediaOfEachMonth(yearInt);
    }

    return c.json(fetchAllMedia);
  } catch (error) {
    console.error('Error fetching media:', error);
    return c.json({ error: 'Failed to fetch media' }, 500);
  }
});

medias.get('/statistic', async (c) => {
  try {
    return c.json(await fetchMediaCount(), 200);
  } catch (error) {
    console.error('Error fetching media:', error);
    return c.json({ error: 'Failed to fetch media' }, 500);
  }
});

medias.get('/devices', async (c) => {
  try {
    return c.json(await fetchCameraType(), 200);
  } catch (error) {
    console.error('Error fetching media:', error);
    return c.json({ error: 'Failed to fetch media' }, 500);
  }
});

const updateSchema = z.object({
  mediaIds: z.array(z.number()),
  updateKey: z.enum(['Favorite', 'DeletedStatus', 'Hidden']), // If updateKey is not in Favorite, DeletedStatus, Hidden ... return error
  updateValue: z.boolean(),
});

medias.put(
  '/',
  zValidator('json', updateSchema, (result, c) => {
    if (!result.success) {
      return c.text('Invalid!', 400);
    }
  }),
  async (c) => {
    const { mediaIds, updateKey, updateValue } = c.req.valid('json');
    const result = await updateMedias(mediaIds, updateKey, updateValue);

    if (result) return c.json({ message: 'Success' }, 204);
    return c.json({ message: 'Failure' }, 500);
  }
);

export default medias;
