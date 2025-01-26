import app from './app';
import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';
import { accountExists, getUserById } from './db/module/account';
import { createUserGuest } from './db/module/guest';
import { createThumbnails } from './service/createThumb';

export const MAX_UPLOAD_FILE_SIZE: number = 2 * 1024 * 1024 * 1024; //2GB

const server = Bun.serve({
  port: Bun.env.PORT || 3000,
  fetch: app.fetch,
  maxRequestBodySize: MAX_UPLOAD_FILE_SIZE,
});

// await getUserById(2);
// await accountExists('jane.smith@example.com');

// await createUserGuest('guasdaaesaasdaaat@Hwllo.com', 'Guest ASHD User');

// await createDBMS();
// await insertMediaToDB(1, Bun.env['PHOTO_PATH']!);

// await backupToDB();
// await restoreToDB();

// await createThumbnails();

console.log(`Listening on http://localhost:${server.port} ...`);
