import app from './app';
import { createDBMS } from './db/main';
import { checkInitialized, initializeSystem } from './db/module/system';
import { MAX_BODY_SIZE } from './middleware/validateFiles';

// import { backupToDB, createDBMS, insertMediaToDB, restoreToDB } from './db/maintain';

export const isNotDevMode: boolean = Bun.env.NODE_ENV !== 'dev';
export const isProduction: boolean = Bun.env.NODE_ENV === 'production';
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

/**
 * Initial startup process:
 * 1. Check and initialize the database if it doesn't exist.
 * 2. On first run:
 *    - Check for admin existence.
 *    - If no admin exists:
 *        - Allow admin creation.
 *        - Let admin specify import path.
 *        - Import media from specified path.
 * 3. If system is already initialized:
 *    - Allow user account requests via chosen login method.
 *    - Admin reviews and activates accounts.
 *
 * Media Import Workflow:
 *  - Parse and store media in database.
 *  - Generate thumbnails.
 *  - Compute and store media hashes (for duplication check).
 *  - Cleanup temporary import table.
 */
const isSystemInitialized = await checkInitialized();

if (!isSystemInitialized) {
  console.log('🔧 Initializing Server...');

  const dbCreated = await createDBMS();
  console.log('📦 Database created:', dbCreated);

  const systemInitialized = await initializeSystem();
  if (!systemInitialized) {
    console.error('❌ Failed to initialize the system.');
    process.exit(1);
  }
}

// server.stop();
console.log(`Listening on http://localhost:${server.port} ...`);
