import { $ } from 'bun';
import { type UUID } from 'crypto';
import { handleMediaInsert, type ImportMedia } from './module/imported';

export const createDBMS = async () => {
  try {
    const { exitCode: tbExitCode } = await $`mysql -u $DB_USER -p$DB_PASS < $DB_CREATE`;
    const { exitCode: triggerExitCode } = await $`mysql -u $DB_USER -p$DB_PASS < $DB_TRIGGERS`;
    return tbExitCode === 0 && triggerExitCode === 0;
  } catch (error) {
    console.log('createDBMS:', error);
    return false;
  }
};

export async function insertMediaToDB(RegisteredUser: UUID, sourcePath: string) {
  try {
    const { stderr: renameErr, exitCode: renameExitCode } =
      await $`find ${sourcePath} -depth -name '*[^a-zA-Z0-9._/-]*' -exec bash -c 'mv "$0" "$(dirname "$0")/$(basename "$0" | sed "s/[^a-zA-Z0-9._-]/_/g")"' {} \;`;
    if (renameExitCode !== 0) console.log('Error:', renameErr);

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
        await handleMediaInsert(newMedia, RegisteredUser);

        jsonString = '{';
        continue;
      }

      jsonString += line.trim();
    }

    console.log(`-----=====INSERTED successfully to the DB!=====-----`);

    return renameExitCode;
  } catch (err: any) {
    console.log(`FAILED with code ${err}`);
    return -1;
  }
}

export async function backupToDB() {
  const { stderr, exitCode } = await $`mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DB_BACKUP`.nothrow().quiet();
  exitCode !== 0 ? console.log(`Backup: Non-zero exit code ${stderr}`) : console.log(`BACKUP successfully to the DB!`);
  return exitCode;
}

export async function restoreToDB() {
  const { stderr, exitCode } = await $`mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DB_BACKUP`;
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
