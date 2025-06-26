import { serveStatic } from 'hono/bun';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { csrf } from 'hono/csrf';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';

// ===============================
import { getDirName } from './service/helper';
import { isNotDevMode } from './init_sys';
import { isAdmin, isAuthenticate } from './middleware/validateAuth';

import auth from './routes/auth';

import user from './routes/user';
import album from './routes/album';
import admin from './routes/admin';
import upload from './routes/upload';
import search from './routes/search';
import media from './routes/media';
import medias from './routes/medias';
import photoView from './routes/stream';

import thumbs from './routes/serveStatic/thumbs';

import { streamLargeVid } from './middleware/streamLargeVid';

const app = new Hono();

/////////// IMPORTANT Security allow connection //////////////////////////////
app.use('*', logger());

// CORS should be called before the route // DEV MODE - NEED TO REMOVE CORS In DEPLOY
if (!isNotDevMode) {
  app.use(
    '/*',
    cors({
      origin: Bun.env.ORIGIN_URL,
      allowHeaders: ['X-Custom-Header', 'Upgrade-Insecure-Requests'],
      allowMethods: ['POST', 'GET', 'PUT', 'DELETE'],
      exposeHeaders: ['Content-Length', 'X-Kuma-Revision'],
      maxAge: 600,
      credentials: true,
    })
  );
}

app.use(
  csrf({
    origin: Bun.env.ORIGIN_URL, // For Post method, does not work if does not sspecify Orgin
  })
);

app.use(secureHeaders()); // https://hono.dev/docs/middleware/builtin/secure-headers#secure-headers-middleware

///////////////////////////////////////////////////
// import test from './routes/testAPI';
// if (!isNotDevMode) {
//   app.route('/test', test);
// }
/////////////////////////////////////////////
app
  // .basePath('api/v1')
  .route('api/v1/auth', auth)
  .use(isAuthenticate) // Apply authentication only to API routes after '/auth'
  .route('api/v1/search', search)
  .route('api/v1/upload', upload)
  .route('api/v1/stream', photoView)
  .route('api/v1/user', user)
  .route('api/v1/medias', medias)
  .route('api/v1/media', media)
  .route('api/v1/album', album)

  .route(getDirName(Bun.env.THUMB_PATH), thumbs)

  .use(isAdmin)
  .route('api/v1/admin', admin);

// Catch-all for protected API routes
app.on(
  'GET',
  [`${getDirName(Bun.env.PHOTO_PATH)}/*`, `${getDirName(Bun.env.UPLOAD_PATH)}/*`],
  isAuthenticate,
  streamLargeVid, // If file request is images or small video serveStatic

  serveStatic({ root: Bun.env.MAIN_PATH })
);

// Serve static files first (without authentication)
app.get('*', serveStatic({ root: './dist' }));
app.get('*', serveStatic({ path: './dist/index.html' }));

export default app;

// export type ApiRoutes = typeof apiRoutes;

// // use bcrypt
// const bcryptHash = await Bun.password.hash(password, {
//   algorithm: 'bcrypt',
//   cost: 4, // number between 4-31
// });

// console.log(bcryptHash);
// const isMatch = await Bun.password.verify(password, argonHash); // => true
// console.log(isMatch);

/////////////////////////////////

// app.on('message', (message) => {
//   if (message.topic === '/hello') {
//     hono.publish({
//       topic: message.topic,
//       data: 'Hello from Hono!',
//     });
//   }
// });
