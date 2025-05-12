import path from 'path';
import { type UUID } from 'crypto';
import type { StreamingApi } from 'hono/utils/stream';
import { preprocessMedia, processMetadataExif } from '../../service';
import { createFolder, isExist, nameFolderByTime } from '../../service/helper';
import { copyFileToExternalDir } from '../../service/generators/metadata';
import { insertErrorLog } from '../../db/module/system';

export const streamingImportMedia = async (dirPath: string, userId: UUID, stream: StreamingApi): Promise<boolean> => {
  stream.onAbort(() => console.warn('Client aborted the stream!'));

  await stream.writeln('📥 Sanitizing files ...');
  if (!(await isExist(dirPath))) {
    await stream.writeln('❌ Directory not found. Please ensure the directory exists');
    return false;
  }

  await stream.writeln('⏳ Importing/Uploading files to system...');
  const totalFile = await processMetadataExif(dirPath, userId, stream);
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

// If process file in provided path, should transfer to the main directory and start process in there
export const importExternalPath = async (sourcePath: string, stream: StreamingApi): Promise<string | undefined> => {
  // Create folder to transfer all the files to
  const writeToDir = path.join(Bun.env.UPLOAD_PATH, nameFolderByTime());
  await createFolder(writeToDir);
  try {
    if ((await isExist(writeToDir)) && (await isExist(sourcePath))) {
      await copyFileToExternalDir(sourcePath, writeToDir);
      return writeToDir;
    }
  } catch (error) {
    console.log('routes/importHelper/_imports.ts', 'importExternalPath', error);
    await insertErrorLog('routes/importHelper/_imports.ts', 'importExternalPath', error);

    await stream.writeln(`❌ An Error occors while transfering data to system!`);
    return '';
  }
};
