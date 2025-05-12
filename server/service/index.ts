import type { UUID } from 'crypto';
import path from 'path';
import type { StreamingApi } from 'hono/utils/stream';

import { workerQueue } from './workers';
import { createFolder } from './helper';
import { createHash } from './generators/hashcode';
import { createThumbnail } from './generators/thumbnails';
import { createCaption } from './generators/caption';

import { importedMediasCaption, importedMediasThumbHash, updateHashThumb } from '../db/module/media';
import { insertErrorLog } from '../db/module/system';
import { insertMetadataToDB, recursiveDir, type ImportTrack } from './generators/metadata';

// ======================= Exif metadata ===============================

export const BATCH_SIZE_INSERT = 500;
export const processMetadataExif = async (sourcePath: string, RegisteredUser: UUID, stream: StreamingApi): Promise<number> => {
  try {
    const tracking: ImportTrack = { count: 0, sourcePaths: [] };
    await recursiveDir(sourcePath, tracking, RegisteredUser, stream);

    // Import the remaining data to db
    if (tracking.sourcePaths.length > 0) await insertMetadataToDB(tracking, RegisteredUser);
    await stream.writeln(`𒁋 Extracted Metadata of ${tracking.count} files...`);

    console.log('------- PROCESS EXTRACTED METADATA COMPLETED -------');
    return tracking.count;
  } catch (error: any) {
    await insertErrorLog('service/index.ts', 'processMetadataExif', error);
    console.log(`processMetadataExif: ${error}`);
    return 0;
  }
};

// ======================= Thumbnail & Hashcode ===============================
export const thumbAndHashGenerate = async (media: any) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.source_file);
    const output = path.join(Bun.env.MAIN_PATH, media.thumb_path);

    await createFolder(output);
    const { w, h } = await createThumbnail(input, output, media.file_type === 'Photo');
    const hash = await createHash(output);

    if (w && h) await updateHashThumb(media.media_id, hash, w, h);
  } catch (error) {
    console.error(`thumbAndHashGenerate - Source: ${media.source_file}: ${error}`);
    await insertErrorLog('service/index.ts', 'thumbAndHashGenerate', `error - ${media.source_file}`);
  }
};

export const preprocessMedia = async (stream: StreamingApi) => {
  const loadedmedias = await importedMediasThumbHash();
  if (!loadedmedias.length) {
    await stream.writeln('❌ No files found in the current directory. Please check if the directory contains media files.');
    return false;
  }

  let completedCount = 0;
  try {
    const tasks = loadedmedias.map(
      (media: any) => () =>
        thumbAndHashGenerate(media).finally(() => {
          stream.writeln(`Digesting: ${++completedCount}/${loadedmedias.length}`);
        })
    );
    await workerQueue(tasks);
    console.log('======= PROCESS THUMBNAIL AND HASH COMPLETED =======');

    return true;
  } catch (error) {
    console.error('preprocessMedia worker', error);
    await insertErrorLog('service/index.ts', 'preprocessMedia', error);
    return false;
  }
};

// ======================= Caption ===============================
export const processCaptioning = async () => {
  // Create BLOCK call for not over load server while processing caption for medias
  try {
    const mediasForCaption = await importedMediasCaption();

    await createCaption(mediasForCaption);

    console.log('******* PROCESS CAPTION HAS BEEN COMPLETED *******');
  } catch (error) {
    console.error('processCaptioning', error);
    await insertErrorLog('service/index.ts', 'processCaptioning', error);
  }
};
