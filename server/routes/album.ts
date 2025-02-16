import { Hono } from 'hono';
import { createAlbum, fetchAddToAlbum, fetchAlbums } from '../db/module/media';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';

const album = new Hono();

album.get('/', async (c) => {
  return c.json(await fetchAlbums());
});

const addAlbumSchema = z.object({
  mediaIds: z.array(z.number()),
  albumId: z.number().optional(),
  albumTitle: z.string().optional(),
});

album.put(
  '/add',
  zValidator('json', addAlbumSchema, (result, c) => {
    if (!result.success) {
      return c.text('Invalid!', 400);
    }
  }),
  async (c) => {
    const { mediaIds, albumId, albumTitle } = c.req.valid('json');

    if (!albumId && !albumTitle) return c.json({ message: 'Missing albumId or albumTitle' }, 400);

    const targetAlbumId = !albumId && albumTitle ? await createAlbum(albumTitle) : albumId;

    if (targetAlbumId) {
      await fetchAddToAlbum(mediaIds, targetAlbumId);
      return c.json({ message: 'Success' }, 204);
    }
    return c.json({ message: 'Album creation failed' }, 500);
  }
);

export default album;
