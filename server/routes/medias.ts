import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod'; // To create a schema to validate post req
// import { getConnInfo } from 'hono/bun';
import { fetchCameraType, fetchMediaEachYear, fetchMediaOfEachMonth, markFavorite } from '../db/module/media';
const medias = new Hono();

// Using z to validate if input in valid
const postSchema = z.object({
  homepage: z.string(),
});

// Make sure all of id is numbers
medias.get('/:id{[0-9]+}', (c) => {
  return c.json({ homepage: 'YOU ARE HOME' });
});

// medias.get('/', (c) => {
//   // const info = getConnInfo(c);
//   // console.log(c.req.header());
//   // console.log(info);
//   return c.json({ homepage: 'YOU ARE HOME' });
// });

medias.post('/', zValidator('json', postSchema), (c) => {
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

medias.get('/devices', async (c) => {
  return c.json(await fetchCameraType());
});

// Validate input from update data to database.
const updateSchema = z.object({
  mediaIds: z.array(z.string()),
  updateKey: z.string(),
  updateValue: z.boolean(),
});

medias.put('/', zValidator('json', updateSchema), async (c) => {
  const { mediaIds, updateKey, updateValue } = await c.req.json();
  // If updateKey is not in Favorite, DeletedStatus, Hidden ... return error
  //
  const result = await markFavorite(mediaIds, updateKey, updateValue);
  if (result) return c.json({ message: 'Success' }, 204);
  return c.json({ message: 'Failure' }, 500);
});

export default medias;
