import { $ } from 'bun';
import { type UUID } from 'crypto';
import { insertImportedToMedia, type ImportMedia } from './module/imported';
import { sql } from '.';
import { isExist } from '../service/helper';
import { insertErrorLog } from './module/system';
import type { StreamingApi } from 'hono/utils/stream';

export const createDBMS = async () => {
  try {
    // Create new databse
    const { exitCode: tbExitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d postgres -v name_db=$DB_NAME -v user_db=$DB_USER -f $DB_CREATE`;

    if (tbExitCode) return false;

    // Restore to database if backup database exists
    if (await isExist(Bun.env.DB_BACKUP)) {
      return await restoreToDB();
    }

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

export const insertMediaToDB = async (RegisteredUser: UUID, sourcePath: string, stream: StreamingApi): Promise<boolean> => {
  try {
    await stream.writeln('📥 Sanitizing files ...');
    if (!(await isExist(sourcePath))) {
      await stream.writeln('❌ Directory not found. Please ensure the directory exists');
      return false;
    }

    const command = $`exiftool -r -json -d "%Y-%m-%dT%H:%M:%S" \
    -SourceFile -FileName -FileType -MIMEType \
    -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated \
    -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# \
    -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels ${sourcePath} | \
    sed 's|${Bun.env.MAIN_PATH}||g'`.lines();

    let jsonString = '{';
    let count = 1;

    for await (let line of command) {
      if (!line) continue;

      if (line.startsWith('[{') || line.startsWith('{')) continue;

      if (line.endsWith('},') || line.endsWith('}]')) {
        jsonString += '}';

        const newMedia: ImportMedia = parseJsonToObject(jsonString);
        const status = await insertImportedToMedia(newMedia, RegisteredUser);

        await stream.writeln(`🗂️ 🚀 Importing/Uploading files to system: ${count++}`);

        if (!status) return false;

        jsonString = '{';
        continue;
      }

      jsonString += line.trim();
    }

    return true;
  } catch (error: any) {
    await insertErrorLog('db/main.ts', 'insertMediaToDB', error);
    console.log(`insertMediaToDB: ${error}`);
    return false;
  }
};

export const backupToDB = async () => {
  const { stderr, exitCode } = await $`PGPASSWORD=$DB_PASS pg_dump -U $DB_USER $DB_NAME > $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `backupToDB`, stderr) : console.log(`BACKUP successfully to the DB!`);
  return exitCode;
};

export const restoreToDB = async () => {
  const { stderr, exitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d $DB_NAME -f $DB_BACKUP`.quiet();
  exitCode !== 0 ? await insertErrorLog('db/main.ts', `restoreToDB`, stderr) : console.log(`RESTORE successfully to the DB!`);
  return exitCode;
};

const parseJsonToObject = (input: string) => {
  const jsonObj = JSON.parse(input);

  const importMedia: ImportMedia = {
    ...jsonObj,

    Software: jsonObj.Software ?? null,
    Title: jsonObj.Title ?? null,
    Make: jsonObj.Make ?? null,
    Model: jsonObj.Model ?? null,
    LensModel: jsonObj.LensModel ?? null,
    Orientation: jsonObj.Orientation ?? null,
    Megapixels: jsonObj.Megapixels ?? null,

    CreateDate: jsonObj.CreateDate ?? null,
    DateCreated: jsonObj.DateCreated ?? null,
    CreationDate: jsonObj.CreationDate ?? null,
    DateTimeOriginal: jsonObj.DateTimeOriginal ?? null,
    FileModifyDate: jsonObj.FileModifyDate ?? null,
    MediaCreateDate: jsonObj.MediaCreateDate ?? null,
    MediaModifyDate: jsonObj.MediaModifyDate ?? null,
    GPSLatitude: jsonObj.GPSLatitude ?? null,
    GPSLongitude: jsonObj.GPSLongitude ?? null,
  };

  return importMedia;
};
