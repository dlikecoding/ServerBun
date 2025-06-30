import { $ } from 'bun';
import { sql } from '.';
import type { StreamingApi } from 'hono/utils/stream';

import { insertErrorLog } from './module/system';
import { diskCapacity, isExist } from '../service/helper';

export const createDBMS = async () => {
  try {
    // Create new databse
    const { exitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d postgres -h $DB_HOST -v name_db=$DB_NAME -v user_db=$DB_USER -f $DB_CREATE`;

    if (exitCode !== 0) return false;

    await sql.file(Bun.env.DB_MODEL); // Create new schema & tables
    await sql.file(Bun.env.DB_VIEW);
    await sql.file(Bun.env.DB_TRIGGER);

    return true;
  } catch (error) {
    console.log('createDBMS', error);
    return false;
  }
};

export const backupToDB = async () => {
  const { stderr, exitCode } = await $`pg_dump $DB_URL > $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `backupToDB`, stderr) : console.log(`BACKUP successfully to the DB!`);
  return exitCode === 0;
};

export const backupFiles = async (stream: StreamingApi) => {
  const [isMainExist, isBackupExist] = await Promise.all([isExist(Bun.env.MAIN_PATH), isExist(Bun.env.BACKUP_DATA)]);
  if (!isMainExist || !isBackupExist) {
    await stream.writeln(`❌ Failed! ${!isMainExist ? 'Source' : 'Backup'} directory path is not exist`);
    return false;
  }

  const [mainDisk, backupDisk] = await Promise.all([diskCapacity(Bun.env.MAIN_PATH), diskCapacity(Bun.env.BACKUP_DATA)]);
  if (mainDisk?.used! > backupDisk?.total!) {
    await stream.writeln(`❌ Failed! Backup storage does not have enough spaces.`);
    return false;
  }

  const process = Bun.spawn(
    [
      'rsync',
      '-ahv',
      '--delete',
      '--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"}',
      `${Bun.env.MAIN_PATH}/`,
      `${Bun.env.BACKUP_DATA}/`,
    ],
    {
      stderr: 'pipe',
      stdout: 'pipe',
    }
  );

  try {
    const reader = process.stdout.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;

      const eachLine = decoder.decode(value, { stream: true }).trim();
      await stream.writeln(eachLine);
    }
  } catch (error) {
    await insertErrorLog('db/main.ts', `backupFiles`, error);
  } finally {
    process.kill();
  }

  return (await process.exited) === 0;
};

export const restoreToDB = async () => {
  const { stderr, exitCode } = await $`psql $DB_URL -f $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `restoreToDB`, stderr) : console.log(`RESTORE successfully to the DB!`);
  return exitCode === 0;
};
