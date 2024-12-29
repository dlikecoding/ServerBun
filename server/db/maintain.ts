import { $ } from 'bun';

export async function createDBMS() {
  await $`mysql -u $DB_USER -p$DB_PASS < $DB_CREATE`;
  await $`mysql -u $DB_USER -p$DB_PASS < $DB_TRIGGERS`;
  // await $`mysql -u $DB_USER -p$DB_PASS < $TEST_DB_INSERT_ACCOUNT`;
}

export async function insertMediaToDB(account: Number = 1, sourcePath: String = `${Bun.env.SOURCE_IMPORT}`) {
  try {
    // await $`echo $COMMAND`;
    const output =
      await $`exiftool -r -a -d "%Y-%m-%dT%H:%M:%S" -csv -SourceFile -FileName -FileType -MIMEType -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels ${sourcePath} | awk -v account=${account} '{print account "," $0}' | \
    sed '1d'| mysql --local-infile=1 -u $DB_USER -p$DB_PASS $DB_NAME -e $DB_INSERT`;

    console.log(`INSERT successfully to the DB!\n${output}`);
  } catch (err: any) {
    if (err.exitCode !== 0) {
      return console.log(`FAILED with code ${err.exitCode}`);
    }
  }
}

export async function backupToDB() {
  const { stdout, stderr, exitCode } = await $`mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DB_BACKUP
`;
  // .nothrow()
  // .quiet();

  if (exitCode !== 0) {
    return console.log(`Non-zero exit code ${exitCode}`);
  }
  console.log(exitCode);
}
export async function restoreToDB() {
  const { stdout, stderr, exitCode } = await $`mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DB_BACKUP`;
  if (exitCode !== 0) {
    return console.log(`Non-zero exit code ${exitCode}`);
  }
  console.log(exitCode);
}
