import { Hono } from 'hono';
import { z } from 'zod';

import { createAlbum, fetchAlbums, fetchAddToAlbum, fetchRemoveFromAlbum, fetchMediaCount } from '../db/module/media';

import { validateSchema } from '../modules/validateSchema';
import { getUserBySession } from '../middleware/validateAuth';
import { insertErrorLog } from '../db/module/system';

const album = new Hono();

const albumSchema = z.object({
  mediaIds: z.array(z.coerce.number()),
  albumId: z.coerce.number().optional(),
  albumTitle: z.string().optional(),
});

album.get('/', async (c) => {
  try {
    return c.json(await fetchAlbums());
  } catch (error) {
    console.log('fetchAlbums', error);
    await insertErrorLog('album.ts', 'fetchAlbums', error);
    return c.json({ error: 'Error fetch albums' }, 500);
  }
});

album.get('/statistic', async (c) => {
  try {
    return c.json(await fetchMediaCount(), 200);
  } catch (error) {
    console.error('Error fetching statistic:', error);
    await insertErrorLog('album.ts', 'statistic', error);
    return c.json({ error: 'Failed to fetch media' }, 500);
  }
});

album.put('/add', validateSchema('json', albumSchema), async (c) => {
  try {
    const { mediaIds, albumId, albumTitle } = c.req.valid('json');
    if (!albumId && !albumTitle) return c.json({ error: 'Missing Album ID or Album Title' }, 400);

    const userId = getUserBySession(c).userId;
    const targetAlbumId = !albumId && albumTitle ? await createAlbum(userId, albumTitle) : albumId;

    if (!targetAlbumId) return c.json({ error: 'Album creation failed' }, 500);

    const addStatus = await fetchAddToAlbum(mediaIds, targetAlbumId);
    if (addStatus) return c.json(204);
    return c.json(201);
  } catch (error) {
    console.error('add Albums', error);
    await insertErrorLog('album.ts', 'add to album', error);
    return c.json({ error: 'Failed to add media to album' }, 500);
  }
});

album.put('/remove', validateSchema('json', albumSchema), async (c) => {
  try {
    const { mediaIds, albumId } = c.req.valid('json');
    if (!albumId) return c.json({ error: 'Missing Album ID' }, 400);

    const removeStatus = await fetchRemoveFromAlbum(mediaIds, albumId);
    if (removeStatus) return c.json(204);
  } catch (error) {
    console.error('fetchRemoveFromAlbum ', error);
    await insertErrorLog('album.ts', 'remove from album', error);
    return c.json({ error: 'Failed to remove media from album' }, 500);
  }
});

export default album;
