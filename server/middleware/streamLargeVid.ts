import path from 'path';
import * as fs from 'fs';
import { createMiddleware } from 'hono/factory';

const VIDEO_EXT = ['.mov', '.mp4']; //, '.3gp', '.m4v',

const MB = 1024 * 1024;
const RESPONSE_IN_MB = 20 * MB;

export const streamLargeVid = createMiddleware(async (c, next) => {
  const reqUrl = new URL(c.req.url);
  const isVideo = VIDEO_EXT.some((ext) => c.req.url.toLowerCase().endsWith(ext));

  // if not a large video, serveStatic file.
  // Ignore all of images and video are not mov, just serve as static file.
  if (!isVideo) return await next();

  const filePath = path.join(Bun.env.MAIN_PATH, reqUrl.pathname);
  const videoFile = Bun.file(filePath);

  if (!(await videoFile.exists())) return c.json({ error: 'File not found' }, 404);

  const fileSize = videoFile.size;

  if (videoFile.size < RESPONSE_IN_MB) return await next();

  const range = c.req.header('range') || '';
  const match = range.match(/bytes=(\d+)-(\d*)/);

  // const isEOF = videoFile.size - 1
  if (!match) return c.text('Invalid Range Header', 416);

  const [_, startStr, endStr] = match;

  const start = parseInt(startStr, 10);
  const getEnd = endStr ? parseInt(endStr, 10) : fileSize - 1;

  const end = Math.min(getEnd, start + RESPONSE_IN_MB - 1);

  // console.log('start: ', start, ' - end: ', end);
  // if (start === 0 && end === 1) return new Response(videoFile.slice(start, end));

  if (start >= fileSize || end >= fileSize || start > end) {
    return c.text('Requested Range Not Satisfiable', 416);
  }

  const chunkSize = end - start + 1;
  const fileStream = fs.createReadStream(filePath, { start, end });
  // TODO for Bun.file.slice: Need to prevent it download from 0 to start for example: if start is 1000000, end > start, it will load the video from 0 - start
  // return new Response(videoFile.slice(start, end), {
  return new Response(fileStream as unknown as BodyInit, {
    status: 206,
    headers: {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Content-Length': chunkSize.toString(),
      'Content-Type': videoFile.type,
      'Accept-Ranges': 'bytes',
      'Cache-Control': 'public, max-age=3600, immutable',
    },
  });
});

// if (!range) {
//   return new Response(file.stream(), {
//     status: 200,
//     headers: {
//       'Content-Type': mimeType,
// 'Content-Length': fileSize.toString(),
//       'Accept-Ranges': 'bytes',
//       'Cache-Control': 'public, max-age=3600, immutable',
//     },
//   });
// }

// const match = range.match(/bytes=(\d+)-(\d*)/);
// if (!match) return c.text('Invalid Range header', 416);

// const [_, startStr, endStr] = match;
// const start = parseInt(startStr, 10);
// const end = endStr ? parseInt(endStr, 10) : fileSize - 1;

// if (start >= fileSize || end >= fileSize || start > end) {
//   return c.text('Requested Range Not Satisfiable', 416);
// }

// const chunkSize = end - start + 1;
// const partialFile = Bun.file(filePath, { start, end: end + 1 });

// return new Response(partialFile.stream(), {
//   status: 206,
//   headers: {
//     'Content-Range': `bytes ${start}-${end}/${fileSize}`,
//     'Accept-Ranges': 'bytes',
// 'Content-Length': chunkSize.toString(),
//     'Content-Type': mimeType,
//     'Cache-Control': 'public, max-age=86400, immutable',
//   },
// });

// ========================================

// return c.body(fileStream as unknown as BodyInit, 201, {
//   'Content-Range': `bytes ${start}-${end}/${fileSize}`,
//   'Content-Length': (end - start + 1).toString(),
//   'Content-Type': mimeType,
//   'Accept-Ranges': 'bytes',
//   'Cache-Control': 'public, max-age=3600, immutable',
// });

// import { ALLOWED_MIME_TYPES } from './validateFiles';

// const MIME_TYPES: Record<string, string> = {
//   '.mp4': 'video/mp4',
//   '.webm': 'video/webm',
//   '.ogg': 'video/ogg',
//   '.mov': 'video/mov',
// };
