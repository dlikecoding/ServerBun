import type { UUID } from 'crypto';
import path from 'path';
import type { StreamingApi } from 'hono/utils/stream';

import { workerQueue } from './workers';
import { createFolder, isExist } from './helper';
import { createHash } from './generators/hashcode';
import { createThumbnail } from './generators/thumbnails';
import { createCaption } from './generators/caption';

import { importedMediasCaption, importedMediasLocation, importedMediasThumbHash, rescanThumbnail, updateHashThumb } from '../db/module/media';
import { insertErrorLog } from '../db/module/system';
import { insertMetadataToDB, recursiveDir, type ImportTrack } from './generators/metadata';
import { markTaskEnd, markTaskStart } from '../middleware/isRuningTask';
import { findLocation } from './generators/location';

// ======================= Exiftool metadata ===============================

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
export const thumbAndHashGenerate = async (media: any, overwrite: boolean = false) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.source_file);
    const output = path.join(Bun.env.MAIN_PATH, media.thumb_path);

    if (!(await isExist(output)) || overwrite) {
      await createFolder(output);
      const existCode = await createThumbnail(input, output, media);
      if (!existCode) return;
    }

    const hash = await createHash(output);
    if (!hash) return;

    await updateHashThumb(media.media_id, hash);
  } catch (error) {
    console.error(`thumbAndHashGenerate - Source: ${media.source_file}: ${error}`);
    await insertErrorLog('service/index.ts', 'thumbAndHashGenerate', `error - ${media.source_file}`);
  }
};

const processThumbAndHash = async (loadedmedias: any[], stream: StreamingApi) => {
  if (!loadedmedias.length) return false;

  let completedCount = 0;
  try {
    const tasks = loadedmedias.map((media: any) => async () => {
      await thumbAndHashGenerate(media);
      await stream.writeln(`Scanning: ${++completedCount}/${loadedmedias.length}`);
    });
    await workerQueue(tasks);
    console.log('======= PROCESS THUMBNAIL AND HASH COMPLETED =======');

    return true;
  } catch (error) {
    console.error('preprocessMedia worker', error);
    await insertErrorLog('service/index.ts', 'preprocessMedia', error);
    return false;
  }
};

export const preprocessMedia = async (stream: StreamingApi) => {
  const loadedmedias = await importedMediasThumbHash();
  return await processThumbAndHash(loadedmedias, stream);
};

export const rescanningThumbs = async (stream: StreamingApi) => {
  const loadedmedias = await rescanThumbnail();
  return await processThumbAndHash(loadedmedias, stream);
};

// ======================= Location ===============================
export const processLocations = async () => {
  // Create BLOCK call for not over load server while processing caption for medias
  try {
    const medias = await importedMediasLocation();
    if (!medias.length) return;

    await findLocation(medias);

    console.log('++++++++ IMPORT LOCATION HAS BEEN COMPLETED ++++++++');
    return true;
  } catch (error) {
    console.error('processLocations', error);
    await insertErrorLog('service/index.ts', 'processLocations', error);
    return false;
  }
};

// ======================= Caption ===============================
export const processCaptioning = async () => {
  // Create BLOCK call for not over load server while processing caption for medias
  try {
    markTaskStart('captioning');

    const medias = await importedMediasCaption();
    if (!medias.length) return;

    await createCaption(medias);

    console.log('******* PROCESS CAPTION HAS BEEN COMPLETED *******');
  } catch (error) {
    console.error('processCaptioning', error);
    await insertErrorLog('service/index.ts', 'processCaptioning', error);
  } finally {
    markTaskEnd('captioning');
  }
};
