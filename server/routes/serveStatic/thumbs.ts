import path from 'path';

import { Hono } from 'hono';
import { isNotDevMode } from '../../init_sys';

const thumbnails = new Hono();

thumbnails.get(`/*`, async (c) => {
  const reqUrl = new URL(c.req.url);
  const filePath = path.join(Bun.env.MAIN_PATH, reqUrl.pathname);

  const file = Bun.file(filePath);

  if (!(await file.exists())) {
    return c.text('Not Found', 404);
  }

  // Prepare validators
  const etag = path.basename(reqUrl.pathname);
  const lastModified = new Date(file.lastModified).toUTCString();

  let resHeaders = {
    'Access-Control-Allow-Origin': isNotDevMode ? '' : '*',
    ETag: etag,
    'Last-Modified': lastModified,
    'Cache-Control': 'public, max-age=3600',
  };

  if (c.req.header('if-none-match') === etag || c.req.header('if-modified-since') === lastModified) {
    return c.body(null, 304, resHeaders);
  }

  return c.body(file.stream(), 200, {
    ...resHeaders,
    'Content-Type': file.type,
    'Content-Length': file.size.toString(),
  });
});

export default thumbnails;
