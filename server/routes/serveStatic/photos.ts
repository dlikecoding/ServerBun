import { Hono } from 'hono';
import { serveStatic } from 'hono/bun';

import { streamLargeVid } from '../../middleware/streamLargeVid';

const photos = new Hono();

photos.get('/*', streamLargeVid, serveStatic({ root: Bun.env.MAIN_PATH }));

export default photos;
