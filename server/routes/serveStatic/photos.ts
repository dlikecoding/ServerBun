import { Hono } from 'hono';
import { streamLargeVid } from '../../middleware/streamLargeVid';

const photos = new Hono();

photos.get('/*', streamLargeVid);

export default photos;
