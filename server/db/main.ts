import { $ } from 'bun';
import { type UUID } from 'crypto';
import { insertImportedToMedia, type ImportMedia } from './module/imported';
import { sql } from '.';
import { isExist } from '../service/fsHelper';
import { insertErrorLog } from './module/system';

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
    await sql.file(Bun.env.DB_TRIGGER);

    return true;
  } catch (error) {
    console.log('createDBMS', error);
    await insertErrorLog('db/main.ts', 'createDBMS', error);
    return false;
  }
};

export const renameAllFiles = async (sourcePath: string): Promise<boolean> => {
  const { stderr, exitCode } =
    await $`find ${sourcePath} -depth -name '*[^a-zA-Z0-9._/-]*' -exec bash -c 'mv "$0" "$(dirname "$0")/$(basename "$0" | sed "s/[^a-zA-Z0-9._-]/_/g")"' {} \;`;
  if (exitCode === 0) return true;

  await insertErrorLog('db/main.ts', 'renameAllFiles', stderr);
  return false;
};

export const countFiles = async (sourcePath: string): Promise<number> => {
  const { stdout, stderr, exitCode } = await $`find ${sourcePath} -type f ! -name '.*' | wc -l`.quiet();

  if (exitCode === 0) return parseInt(stdout.toString().trim(), 10);
  await insertErrorLog('db/main.ts', 'countFiles', stderr);
  return 0;
};

export const insertMediaToDB = async (RegisteredUser: UUID, sourcePath: string) => {
  try {
    const command = $`exiftool -r -json -d "%Y-%m-%dT%H:%M:%S" \
    -SourceFile -FileName -FileType -MIMEType \
    -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated \
    -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# \
    -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels ${sourcePath} | \
    sed 's|${Bun.env.MAIN_PATH}||g'`.lines();

    let jsonString = '{';

    for await (let line of command) {
      if (!line) continue;

      if (line.startsWith('[{') || line.startsWith('{')) continue;

      if (line.endsWith('},') || line.endsWith('}]')) {
        jsonString += '}';

        const newMedia: ImportMedia = parseJsonToObject(jsonString);
        const status = await insertImportedToMedia(newMedia, RegisteredUser);

        if (!status) return false;

        jsonString = '{';
        continue;
      }

      jsonString += line.trim();
    }

    return true;
  } catch (error: any) {
    await insertErrorLog('db/main.ts', 'insertMediaToDB', error);
    console.log(`Import FAILED with error: ${error}`);
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
