import { $ } from 'bun';
import { type UUID } from 'crypto';
import { insertImportedToMedia, type ImportMedia } from './module/imported';
import type { StreamingApi } from 'hono/utils/stream';
import { sql } from '.';
import { isExist } from '../service/fsHelper';

export const createDBMS = async () => {
  try {
    const { exitCode: tbExitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d postgres -v name_db='"${Bun.env.DB_NAME}"' -v user_db=${Bun.env.DB_USER} -f $DB_CREATE`;

    if (tbExitCode) return false;

    // Restore to database if backup database exists
    if (await isExist(Bun.env.DB_BACKUP)) {
      return await restoreToDB();
    }

    // Create new databse
    await sql.file(Bun.env.DB_MODEL);
    await sql.file(Bun.env.DB_VIEW);
    await sql.file(Bun.env.DB_TRIGGER);

    return true;
  } catch (error) {
    return false;
  }
};

export const renameAllFiles = async (sourcePath: string): Promise<boolean> => {
  const { stderr, exitCode } =
    await $`find ${sourcePath} -depth -name '*[^a-zA-Z0-9._/-]*' -exec bash -c 'mv "$0" "$(dirname "$0")/$(basename "$0" | sed "s/[^a-zA-Z0-9._-]/_/g")"' {} \;`;
  if (exitCode === 0) return true;

  console.log('Error:', stderr);
  return false;
};

export const countFiles = async (sourcePath: string): Promise<number> => {
  const { stdout, stderr, exitCode } = await $`find ${sourcePath} -type f ! -name '.*' | wc -l`.quiet();

  if (exitCode === 0) return parseInt(stdout.toString().trim(), 10);

  console.log('Error:', stderr);
  return 0;
};

export async function insertMediaToDB(RegisteredUser: UUID, sourcePath: string, stream: StreamingApi, totalFiles: number) {
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
    console.log(`----=====INSERTED ${totalFiles} to the DB successfully!=====-----`);
    await stream.writeln(`Inserted ${totalFiles} to the database`);
    return true;
  } catch (err: any) {
    console.log(`Import FAILED with error: ${err}`);
    await stream.writeln(`Failed to import media to database`);
    return false;
  }
}

export async function backupToDB() {
  const { stderr, exitCode } = await $`PGPASSWORD=$DB_PASS pg_dump -U $DB_USER $DB_NAME > $DB_BACKUP`.quiet();
  exitCode !== 0 ? console.log(`Backup: Non-zero exit code ${stderr}`) : console.log(`BACKUP successfully to the DB!`);
  return exitCode;
}

export async function restoreToDB() {
  const { stderr, exitCode } = await $`PGPASSWORD=$DB_PASS psql -U $DB_USER -d $DB_NAME -f $DB_BACKUP`.quiet();
  exitCode !== 0 ? console.log(`Restore: Non-zero exit code ${stderr}`) : console.log(`RESTORE successfully to the DB!`);
  return exitCode;
}

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
