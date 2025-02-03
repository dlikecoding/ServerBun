import { $ } from 'bun';

export const createDBMS = async () => {
  try {
    await $`mysql -u $DB_USER -p$DB_PASS < $DB_CREATE`;
    await $`mysql -u $DB_USER -p$DB_PASS < $DB_TRIGGERS`;
    await $`mysql -u $DB_USER -p$DB_PASS < $TEST_DB_INSERT_ACCOUNT`;
  } catch (error) {
    console.log(error);
  }
};

export async function insertMediaToDB(account: Number = 1, sourcePath: string) {
  try {
    const { stderr, exitCode } = await $`find ${sourcePath} -depth -name '*[^a-zA-Z0-9._/-]*' -exec bash -c 'mv "$0" "$(dirname "$0")/$(basename "$0" | sed "s/[^a-zA-Z0-9._-]/_/g")"' {} \;`;
    if (exitCode !== 0) return console.log('Error:', stderr);

    await $`exiftool -r -a -d "%Y-%m-%dT%H:%M:%S" -csv -SourceFile -FileName -FileType -MIMEType \
    -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated \
    -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# \
    -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels ${sourcePath} | \
    awk -v account=${account} '{print account "," $0}' | \
    sed '1d'| sed 's|${Bun.env['MAIN_PATH']}||g' | \
    mysql --local-infile=1 -u $DB_USER -p$DB_PASS $DB_NAME -e $DB_INSERT`;

    console.log(`INSERT successfully to the DB!`);
  } catch (err: any) {
    return console.log(`FAILED with code ${err.exitCode}`);
  }
}

export async function backupToDB() {
  // stdout, stderr, exitCode
  const { stderr, exitCode } = await $`mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DB_BACKUP`.nothrow().quiet();

  if (exitCode !== 0) {
    return console.log(`Non-zero exit code ${stderr}`);
  }
  console.log(`BACKUP successfully to the DB!`);
}
export async function restoreToDB() {
  const { stderr, exitCode } = await $`mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DB_BACKUP`;
  if (exitCode !== 0) {
    return console.log(`Non-zero exit code ${stderr}`);
  }
  console.log(`RESTORE successfully to the DB!`);
}
