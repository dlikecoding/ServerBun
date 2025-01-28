import { Hono } from 'hono';

const media = new Hono();

media.get('/:id{[0-9]+}', (c) => {
  return c.json({ homepage: 'YOU ARE HOME' });
});

export default media;
