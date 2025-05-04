import { type UUID } from 'crypto';
import type { StreamingApi } from 'hono/utils/stream';
import { insertMediaToDB, renameAllFiles } from '../../db/main';
import { processMedias } from '../../service';
import { isExist } from '../../service/helper';

export const streamingImportMedia = async (stream: StreamingApi, userId: UUID, dirPath: string): Promise<boolean> => {
  stream.onAbort(() => console.warn('Client aborted the stream!'));

  if (!(await isExist(dirPath))) {
    await stream.writeln('❌ Directory not found. Please ensure the directory exists');
    return false;
  }

  // if (!(await countFiles(dirPath))) {
  //   await stream.writeln('❌ No files found in the current directory. Please check if the directory contains media files.');
  //   return false;
  // }

  await stream.writeln('📥 Sanitizing uploaded files ...');
  if (!(await renameAllFiles(dirPath))) {
    await stream.writeln('❌ Failed to rename files. Please check file permissions and the files path are valid.');
    return false;
  }

  await stream.writeln('⏳ Importing uploaded files to system...');
  if (!(await insertMediaToDB(userId, dirPath))) {
    await stream.writeln('❌ Failed to importing medias to database.');
    return false;
  }

  if (!(await processMedias(stream))) {
    // create thumbnail and hash keys
    await stream.writeln('❌ Failed to create thumb for medias');
    return false;
  }
  return true;
};
