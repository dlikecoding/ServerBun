import { Hono } from 'hono';
import { createAlbum, fetchAddToAlbum, fetchAlbums } from '../db/module/media';
import { z } from 'zod';

import { validateSchema } from '../modules/validate';

const album = new Hono();

album.get('/', async (c) => {
  return c.json(await fetchAlbums());
});

const addAlbumSchema = z.object({
  mediaIds: z.array(z.number()),
  albumId: z.number().optional(),
  albumTitle: z.string().optional(),
});

album.put('/add', validateSchema('json', addAlbumSchema), async (c) => {
  const { mediaIds, albumId, albumTitle } = c.req.valid('json');

  if (!albumId && !albumTitle) return c.text('Missing Album ID or Album Title', 400);

  const targetAlbumId = !albumId && albumTitle ? await createAlbum(albumTitle) : albumId;

  if (targetAlbumId) {
    await fetchAddToAlbum(mediaIds, targetAlbumId);
    return c.text('Success', 204);
  }
  return c.text('Album creation failed', 500);
});

export default album;
