import app from './app';
import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';
import { accountExists, getUserById } from './db/module/account';
import { createUserGuest } from './db/module/guest';

export const MAX_UPLOAD_FILE_SIZE: number = 2 * 1024 * 1024 * 1024;

const server = Bun.serve({
  port: Bun.env.PORT || 3000,
  fetch: app.fetch,
  maxRequestBodySize: MAX_UPLOAD_FILE_SIZE,
});

// await getUserById(2);
// await accountExists('jane.smith@example.com');

// await createUserGuest('guasdaaesaasdaaat@Hwllo.com', 'Guest ASHD User');

// await backupToDB();
// await createDBMS();
// await restoreToDB();
// await insertMediaToDB();

console.log(`Listening on http://localhost:${server.port} ...`);
