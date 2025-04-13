import { Hono } from 'hono';
import { createAlbum, fetchAlbums, fetchAddToAlbum, fetchRemoveFromAlbum } from '../db/module/media';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';
import { getUserBySession } from '../middleware/validateAuth';

const album = new Hono();

album.get('/', async (c) => {
  try {
    return c.json(await fetchAlbums());
  } catch (error) {
    console.log('fetchAlbums', error);
    return c.json({ error: 'Error fetch albums' }, 500);
  }
});

const albumSchema = z.object({
  mediaIds: z.array(z.coerce.number()),
  albumId: z.coerce.number().optional(),
  albumTitle: z.string().optional(),
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
    return c.json({ error: 'Failed to add media to album' }, 500);
  }
});

export default album;
