import { $ } from 'bun';
import { sql } from '.';
import { insertErrorLog } from './module/system';

export const createDBMS = async () => {
  try {
    // Create new databse
    const { exitCode: tbExitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d postgres -v name_db=$DB_NAME -v user_db=$DB_USER -f $DB_CREATE`;

    if (tbExitCode) return false;

    await sql.file(Bun.env.DB_MODEL); // Create new schema & tables
    await sql.file(Bun.env.DB_VIEW);
    await sql.file(Bun.env.DB_TRIGGER);

    return true;
  } catch (error) {
    console.log('createDBMS', error);
    await insertErrorLog('db/main.ts', 'createDBMS', error);
    return false;
  }
};

export const backupToDB = async () => {
  const { stderr, exitCode } = await $`pg_dump $DB_URL > $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `backupToDB`, stderr) : console.log(`BACKUP successfully to the DB!`);
  return exitCode === 0;
};

export const restoreToDB = async () => {
  const { stderr, exitCode } = await $`psql $DB_URL -f $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `restoreToDB`, stderr) : console.log(`RESTORE successfully to the DB!`);
  return exitCode === 0;
};
