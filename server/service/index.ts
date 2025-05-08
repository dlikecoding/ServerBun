import path from 'path';
import type { StreamingApi } from 'hono/utils/stream';

import { workerQueue } from './workers';
import { createFolder } from './helper';
import { createHash } from './generators/generateSHA';
import { createThumbnail } from './generators/generateThumb';
import { createCaption } from './generators/generateCaption';

import { importedMediasCaption, importedMediasThumbHash, updateHashThumb } from '../db/module/media';
import { insertErrorLog } from '../db/module/system';

const thumbAndHashGenerate = async (media: any) => {
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

  let completedCount = 1;
  try {
    const tasks = loadedmedias.map(
      (media: any) => () =>
        thumbAndHashGenerate(media).finally(() => {
          stream.writeln(`Digesting: ${completedCount++}/${loadedmedias.length}`);
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
