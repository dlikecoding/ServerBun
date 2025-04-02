import app from './app';
import { createDBMS } from './db/main';
import { checkInitalized, initalizeSys } from './db/module/system';
// import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';

export const MAX_UPLOAD_FILE_SIZE: number = 2 * 1024 * 1024 * 1024; // 2 GB
export const isNotDevMode: boolean = Bun.env.NODE_ENV !== 'dev';

const server = Bun.serve({
  development: !isNotDevMode,

  port: Bun.env.PORT || 3000,
  fetch: app.fetch,
  maxRequestBodySize: MAX_UPLOAD_FILE_SIZE,

  // tls: {
  //   cert: Bun.file('./cert.pem'),
  //   key: Bun.file('./key.pem'),
  // },
});

// ///////////////////////////////////////////////////
const isInitSys = await checkInitalized();
if (!isInitSys) {
  console.log('Initializing Server...');
  await createDBMS();
  if (!(await initalizeSys())) {
    console.log('Failed initialized the Database System');
  }
}

/** Process when frist start page:
 * Check if database exist, create one.
 *
 * Allow create admin account (on first start):
 *  - check if admin is exist, if not -> allow to create an admin.
 *  - allow admin to specify path for hard drive to import media.
 *  - Import media to server
 *  => If system already had admin:
 *    - Allow regular users send request an account with there login method
 *    - Then, Admin can activate a new account for this user based on the given information
 *    -
 *
 * Import media:
 *  - Import to data to database
 *  - Create thumbnail (from import data)
 *  - Create Hash for each media to check for duplicate (OPTIONAL AFTER inserted)
 *  - Delete data in ImportMedia tb
 * */

console.log(`Listening on http://localhost:${server.port} ...`);
