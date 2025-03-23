import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { MAX_UPLOAD_FILE_SIZE } from '..';

const upload = new Hono();

upload.get('/', (c) => {
  return c.json({ uploadpage: 'YOU ARE upload' });
});

upload.post(
  '/upload',
  bodyLimit({
    maxSize: MAX_UPLOAD_FILE_SIZE,
    onError: (c) => {
      return c.json({ error: 'overflow :(' }, 413);
    },
  }),
  async (c) => {
    const body = await c.req.parseBody();
    // const data = body['file']; //Single File
    // const data = body['file[]'] // Multiple files

    if (body['file'] instanceof File) {
      console.log(`Got file sized: ${body['file'].size}`);
    }
    return c.json('pass :)');
  }
);

export { upload };
