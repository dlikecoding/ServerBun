import { serveStatic } from 'hono/bun';
// import { getConnInfo } from 'hono/bun';

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { csrf } from 'hono/csrf';
import { logger } from 'hono/logger';
// import { compress } from 'hono/compress';
import { secureHeaders } from 'hono/secure-headers';

// ===============================
import { isAuthenticate } from './routes/authHelper/_cookies';
import auth from './routes/auth';

import users from './routes/users';
import streamApi from './routes/stream';
import medias from './routes/medias';
// import media from './routes/media';
import album from './routes/album';

const app = new Hono();

app.use(csrf());

// DEV MODE - NEED TO REMOVE CORS ///////////////////////////////////
// CORS should be called before the route
app.use(
  '/*',
  cors({
    origin: 'http://localhost:7979',
    allowHeaders: ['X-Custom-Header', 'Upgrade-Insecure-Requests'],
    allowMethods: ['POST', 'GET', 'PUT', 'DELETE'],
    exposeHeaders: ['Content-Length', 'X-Kuma-Revision'],
    maxAge: 600,
    credentials: true,
  })
);

// https://hono.dev/docs/middleware/builtin/secure-headers#secure-headers-middleware
app.use(secureHeaders());
// https://hono.dev/docs/middleware/builtin/compress
// app.use(compress()); // Request must send with "Accept-Encoding" in Header

/////////// IMPORTANT Security allow connection //////////////////////////////
app.use('*', logger());
// app.use('*', async (c, next) => {
//   const info = getConnInfo(c); // info is `ConnInfo`

//   // Can refuse access for certain IP address.
//   console.log(`Your remote address is ${info.remote.address}`);

//   return await next();
// });

app
  .basePath('api/v1')
  .route('/auth', auth)
  .use(isAuthenticate) // Apply authentication only to API routes after '/auth'
  .route('/stream', streamApi)
  .route('/users', users)
  .route('/medias', medias)
  .route('/album', album);

// Catch-all for protected API routes
app.on('GET', ['/Thumbnails/*', '/importPhotos/*', '/StoreUpload/*'], isAuthenticate, serveStatic({ root: Bun.env.MAIN_PATH }));

// Serve static files first (without authentication)
app.get('*', serveStatic({ root: './dist' }));
app.get('*', serveStatic({ path: './dist/index.html' }));

export default app;

// export type ApiRoutes = typeof apiRoutes;

// const logRequestDetails = async (ctx: any) => {
//   const { req } = ctx;

//   const method = req.method;
//   const url = req.url;
//   const headers = req.header;
//   const queryParams = req.query; // Query parameters
//   const body = req.method !== 'GET' ? await req.body() : undefined;

//   // Collect relevant information
//   const requestDetails = {
//     method,
//     url,
//     headers: JSON.stringify(headers),
//     queryParams,
//     body: body ? JSON.stringify(body) : 'N/A', // Only log body for non-GET requests
//   };

//   // Log the collected information (you could replace this with a more sophisticated logger)
//   console.log('Request received:', requestDetails);
// };

// Middleware to log incoming requests
// app.use('*', async (ctx, next) => {
//   await logRequestDetails(ctx); // Log the details before proceeding with the request
//   return next();
// });

// // use bcrypt
// const bcryptHash = await Bun.password.hash(password, {
//   algorithm: 'bcrypt',
//   cost: 4, // number between 4-31
// });

// console.log(bcryptHash);
// const isMatch = await Bun.password.verify(password, argonHash); // => true
// console.log(isMatch);

// app.use(
//   basicAuth({
//     verifyUser: (username, password, c) => {
//       return username === 'user' && password === 'hono';
//     },
//   })
// );

// app.get("/", c => {
//     return c.json({"msg": "Mainpage"});
// })

// medias.get('/', (c) => {
//   // const info = getConnInfo(c);
//   // console.log(c.req.header());
//   // console.log(info);
//   return c.json({ homepage: 'YOU ARE HOME' });
// });

/////////// IMPORTANT Manage login //////////////////////////////
// app.route('api/v1/auth', auth);
// app.use(isAuthenticate);
// app.use('*', async (c, next) => {
//   const sessionId = await getSignedCookie(c, Bun.env.SECRET_KEY, 'auth_token');
//   if (sessionId && sessionStore.has(sessionId)) return await next();
//   return c.text('Unauthorized access', 401);
// });

// app.get('/Thumbnails/*', isAuthenticate, serveStatic({ root: Bun.env.MAIN_PATH }));
// app.get('/importPhotos/*', isAuthenticate, serveStatic({ root: Bun.env.MAIN_PATH }));
// app.get('/StoreUpload/*', isAuthenticate, serveStatic({ root: Bun.env.MAIN_PATH }));

/////////////////////////////////

// app.on('message', (message) => {
//   if (message.topic === '/hello') {
//     hono.publish({
//       topic: message.topic,
//       data: 'Hello from Hono!',
//     });
//   }
// });
