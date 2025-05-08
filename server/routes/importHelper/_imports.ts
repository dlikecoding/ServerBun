import { $ } from 'bun';
import path from 'path';
import { type UUID } from 'crypto';
import type { StreamingApi } from 'hono/utils/stream';
import { insertMediaToDB } from '../../db/main';
import { preprocessMedia } from '../../service';
import { createFolder, isExist, nameFolderByTime } from '../../service/helper';

export const streamingImportMedia = async (stream: StreamingApi, userId: UUID, dirPath: string): Promise<boolean> => {
  stream.onAbort(() => console.warn('Client aborted the stream!'));

  // await stream.writeln('⏳ Processing media files started. Please wait...');
  // if (!(await countFiles(dirPath))) {
  //   await stream.writeln('❌ No files found in the current directory. Please check if the directory contains media files.');
  //   return false;
  // }

  // if (!(await renameAllFiles(dirPath))) {
  //   await stream.writeln('❌ Failed to rename files. Please check file permissions and the files path are valid.');
  //   return false;
  // }

  await stream.writeln('⏳ Importing/Uploading files to system...');
  const totalFile = await insertMediaToDB(userId, dirPath, stream);
  if (!totalFile) {
    await stream.writeln('❌ Failed to importing medias to database.');
    return false;
  }

  if (!(await preprocessMedia(stream))) {
    // create thumbnail and hash keys
    await stream.writeln('❌ Failed to compressing medias and create hashcode');
    return false;
  }
  return true;
};

export const prepareExternalImporting = async (sourcePath: string, stream: StreamingApi): Promise<string | undefined> => {
  // // /*TODO*/ If process file in provided path, should transfer to the main directory. and start process in there
  // // For now, just return when user had imported media in main
  // Create folder to transfer all the files to
  const writeToDir = path.join(Bun.env.UPLOAD_PATH, nameFolderByTime());
  await createFolder(writeToDir);

  if ((await isExist(writeToDir)) && (await isExist(sourcePath))) {
    const cpStatus = await $`rsync -ahv --exclude='.*' ${sourcePath} ${writeToDir}`;
    if (cpStatus.exitCode === 0) return writeToDir;

    await stream.writeln(`❌ An Error occors while writing data to main directory!`);
    return '';
  }
};
