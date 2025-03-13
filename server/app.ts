import { serveStatic } from 'hono/bun';
import { getConnInfo } from 'hono/bun';

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { csrf } from 'hono/csrf';
import { logger } from 'hono/logger';
import { compress } from 'hono/compress';
import { getSignedCookie } from 'hono/cookie';
import { secureHeaders } from 'hono/secure-headers';

// ===============================
import { sessionStore } from './routes/authHelper/cookies';
import auth from './routes/auth';

import home from './routes/medias';
import users from './routes/users';
import streamApi from './routes/stream';
import medias from './routes/medias';
import media from './routes/media';
import album from './routes/album';

const app = new Hono();

// DEV MODE - NEED TO REMOVE CORS ///////////////////////////////////
// CORS should be called before the route
app.use(csrf());
app.use(cors());
// app.use(
//   '/api/v1/*',
//   cors({
//     origin: 'http://localhost:7979',
//     allowHeaders: ['X-Custom-Header', 'Upgrade-Insecure-Requests'],
//     allowMethods: ['POST', 'GET', 'PUT', 'DELETE'],
//     exposeHeaders: ['Content-Length', 'X-Kuma-Revision'],
//     maxAge: 600,
//     credentials: true,
//   })
// );

// https://hono.dev/docs/middleware/builtin/secure-headers#secure-headers-middleware
app.use(secureHeaders());
// https://hono.dev/docs/middleware/builtin/compress
// app.use(compress()); // Request must send with "Accept-Encoding" in Header

// app.use('*', logger());

/////////// IMPORTANT Manage login //////////////////////////////
app.route('api/v1/auth', auth);

app.use('*', async (c, next) => {
  const sessionId = await getSignedCookie(c, Bun.env.SECRET_KEY, 'auth_token');
  if (sessionId && sessionStore.has(sessionId)) return await next();

  return c.text('Unauthorized access', 401);
});

app
  .basePath('api/v1')
  // .route('/auth', auth)
  .route('/home', home)
  .route('/stream', streamApi)
  .route('/users', users)
  .route('/medias', medias)
  .route('/media', media)
  .route('/album', album);

/////////////////////////////////
// app.post
// app.put
// app.delete

// app.on('message', (message) => {
//   if (message.topic === '/hello') {
//     hono.publish({
//       topic: message.topic,
//       data: 'Hello from Hono!',
//     });
//   }
// });

// Serve static files
app.use('*', serveStatic({ root: Bun.env.MAIN_PATH }));
app.use('*', serveStatic({ root: './dist' }));

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
