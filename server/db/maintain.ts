import { $ } from 'bun';
import { type UUID } from 'crypto';

export const createDBMS = async () => {
  try {
    await $`mysql -u $DB_USER -p$DB_PASS < $DB_CREATE`;
    await $`mysql -u $DB_USER -p$DB_PASS < $DB_TRIGGERS`;
    // await $`mysql -u $DB_USER -p$DB_PASS < $TEST_DB_INSERT_ACCOUNT`;
  } catch (error) {
    console.log(error);
  }
};

export async function insertMediaToDB(RegisteredUser: UUID, sourcePath: string) {
  try {
    const { stderr: renameErr, exitCode: renameExitCode } =
      await $`find ${sourcePath} -depth -name '*[^a-zA-Z0-9._/-]*' -exec bash -c 'mv "$0" "$(dirname "$0")/$(basename "$0" | sed "s/[^a-zA-Z0-9._-]/_/g")"' {} \;`;
    if (renameExitCode !== 0) console.log('Error:', renameErr);

    const { stderr: exifErr, exitCode: exifCode } = await $`exiftool -r -a -d "%Y-%m-%dT%H:%M:%S" -csv -SourceFile -FileName -FileType -MIMEType \
    -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated \
    -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# \
    -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels ${sourcePath} | \
    awk -v RegisteredUser=${RegisteredUser} '{print RegisteredUser "," $0}' | \
    sed '1d'| sed 's|${Bun.env.MAIN_PATH}||g' | \
    mysql --local-infile=1 -u $DB_USER -p$DB_PASS $DB_NAME -e "LOAD DATA LOCAL INFILE '/dev/stdin' INTO TABLE ImportMedias FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' (RegisteredUser, SourceFile, FileName, FileType, MIMEType, Software, Title, FileSize, Make, Model, LensModel, Orientation, CreateDate, DateCreated, CreationDate, DateTimeOriginal, FileModifyDate, MediaCreateDate, MediaModifyDate, Duration, GPSLatitude, GPSLongitude, ImageWidth, ImageHeight, Megapixels);"`;

    if (exifCode !== 0) console.log('Error:', exifErr);

    console.log(`-----=====INSERT successfully to the DB!=====-----`);

    return renameExitCode;
  } catch (err: any) {
    return console.log(`FAILED with code ${err.exifErr}`);
  }
}

export async function backupToDB() {
  // stdout, stderr, exitCode
  const { stderr, exitCode } = await $`mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DB_BACKUP`.nothrow().quiet();
  if (exitCode !== 0) return console.log(`Non-zero exit code ${stderr}`);

  console.log(`BACKUP successfully to the DB!`);
}

export async function restoreToDB() {
  const { stderr, exitCode } = await $`mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DB_BACKUP`;
  if (exitCode !== 0) return console.log(`Non-zero exit code ${stderr}`);

  console.log(`RESTORE successfully to the DB!`);
}
