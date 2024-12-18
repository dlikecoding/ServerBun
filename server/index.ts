import app from "./app";
import { $ } from "bun";


async function testProcess(
      account:Number = 2,
      sourcePath: String = `${Bun.env.SOURCE_IMPORT}`
      ) {
  const { stdout, stderr, exitCode } = await $`exiftool ${Bun.env.COMMAND} ${sourcePath} | awk -v account=${account} '{print account "," $0}' | \
  sed '1d'`.nothrow().quiet();

  if (exitCode !== 0) {
    console.log(`Non-zero exit code ${exitCode}`);
  }
  console.log(exitCode);
}

await testProcess();

console.log(Bun.env.DB_INSERT);

const server = Bun.serve({
    port: Bun.env.PORT || 3000,
    fetch: app.fetch
  });
  
console.log(`Listening on http://localhost:${server.port} ...`);












// const { stdout, stderr, exitCode } = await $`exiftool -r -a -d "%Y-%m-%dT%H:%M:%S" -csv \
//   -SourceFile -FileName -FileType -MIMEType -Software -Title -FileSize# -Make -Model \
//   -LensModel -Orientation -CreateDate -DateCreated -CreationDate -DateTimeOriginal \
//   -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# -GPSLatitude# -GPSLongitude# \
//   -ImageWidth -ImageHeight -Megapixels ${sourcePath} | awk -v account=${account} '{print account "," $0}' | \
//   sed '1d'`.nothrow().quiet();