import { isNotDevMode } from './init_sys';
import app from './app';
import { MAX_BODY_SIZE } from './middleware/validateFiles';

// import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';

const server = Bun.serve({
  development: !isNotDevMode,

  port: Bun.env.PORT,
  fetch: app.fetch,
  maxRequestBodySize: MAX_BODY_SIZE,
  idleTimeout: 5,
  // tls: {
  //   cert: Bun.file('./cert.pem'),
  //   key: Bun.file('./key.pem'),
  // },
});

// server.stop();
console.log(`Listening on http://localhost:${server.port} ...`);
