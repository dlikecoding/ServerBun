import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { serveStatic } from 'hono/bun';
import { secureHeaders } from 'hono/secure-headers';
import { compress } from 'hono/compress';
import { basicAuth } from 'hono/basic-auth';
import { csrf } from 'hono/csrf';

// import { getConnInfo } from 'hono/bun';
/////////////////////////////
import { cors } from 'hono/cors';
// ===============================
import home from './routes/medias';

import users from './routes/users';

import streamApi from './routes/stream';
import medias from './routes/medias';
import media from './routes/media';

const app = new Hono();

// DEV MODE - NEED TO REMOVE CORS ///////////////////////////////////
app.use(cors());
///////////////////////////////////

app.use(csrf());

// https://hono.dev/docs/middleware/builtin/secure-headers#secure-headers-middleware
app.use(secureHeaders());
// https://hono.dev/docs/middleware/builtin/compress
// app.use(compress()); // Request must send with "Accept-Encoding" in Header

// app.use('*', logger());

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

// // Encrypt password
// const password = 'hello@12039aisdoquwe283';
// const argonHash = await Bun.password.hash(password);
// console.log(argonHash);

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

const apiRoutes = app.basePath('api').route('/v1/home', home);
app.route('/api/v1/stream', streamApi);
app.route('/api/v1/users', users);
app.route('/api/v1/medias', medias);
app.route('/api/v1/media', media);
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
export type ApiRoutes = typeof apiRoutes;
