import { Hono } from 'hono';
import { createAlbum, fetchAddToAlbum, fetchAlbums } from '../db/module/media';
import { z } from 'zod';

import { validateSchema } from '../modules/validateSchema';
import { getUserBySession } from '../middleware/validateAuth';

const album = new Hono();

album.get('/', async (c) => {
  return c.json(await fetchAlbums());
});

const addAlbumSchema = z.object({
  mediaIds: z.array(z.coerce.number()),
  albumId: z.coerce.number().optional(),
  albumTitle: z.string().optional(),
});

album.put('/add', validateSchema('json', addAlbumSchema), async (c) => {
  const { mediaIds, albumId, albumTitle } = c.req.valid('json');
  if (!albumId && !albumTitle) return c.json({ error: 'Missing Album ID or Album Title' }, 400);

  const userId = getUserBySession(c).userId;
  const targetAlbumId = !albumId && albumTitle ? await createAlbum(userId, albumTitle) : albumId;

  if (!targetAlbumId) return c.json({ error: 'Album creation failed' }, 500);

  const addStatus = await fetchAddToAlbum(mediaIds, targetAlbumId);
  if (addStatus) return c.json('Success', 204);

  return c.json({ error: 'Failed to add media to album' }, 500);
});

export default album;
