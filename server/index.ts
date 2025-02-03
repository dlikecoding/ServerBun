import app from './app';
import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';
import { accountExists, getUserById } from './db/module/account';
import { createUserGuest } from './db/module/guest';
import { createThumbnails } from './service/createThumb';
import { createHashs } from './service/generateSHA';

export const MAX_UPLOAD_FILE_SIZE: number = 2 * 1024 * 1024 * 1024; //2GB

const server = Bun.serve({
  //////////////////////////
  development: true,
  //////////////////////////

  port: Bun.env.PORT || 3000,
  fetch: app.fetch,
  maxRequestBodySize: MAX_UPLOAD_FILE_SIZE,
});

// await getUserById(2);
// await accountExists('jane.smith@example.com');

// await createUserGuest('guasdaaesaasdaaat@Hwllo.com', 'Guest ASHD User');

/////////////////////////////////////////////////
// await createDBMS();
// await insertMediaToDB(1, Bun.env['PHOTO_PATH']!);

// // // await backupToDB();

// await createThumbnails();

// await createHashs();
///////////////////////////////////////////////////
// await restoreToDB();

/** Process when frist start page:
 * Check if database exist, create one.
 *
 * Allow create admin account (on first start):
 *  - check if admin is exist, if not -> allow to create an admin.
 *  - allow admin to specify path for hard drive to import media.
 *  - Import media to server
 *  => If system already had admin:
 *    - Allow regular users send request an account with there login method
 *    - Then, Admin can create a new account for that user based on the given information
 *    -
 *
 * Import media:
 *  - Import to data to database
 *  - Create thumbnail (from import data)
 *  - Create Hash for each media and check for duplicate (In DB) AFTER inserted
 *  - Delete data in ImportMedia tb
 * */

console.log(`Listening on http://localhost:${server.port} ...`);
