import path from 'path';
import { createThumbnail } from './generators/generateThumb';
import { createFolder } from './helper';
import { createHash } from './generators/generateSHA';
import { importedMediasCaption, importedMediasThumbHash, updateHashThumb } from '../db/module/media';
import { workerQueue } from './workers';
import { insertErrorLog } from '../db/module/system';
import type { StreamingApi } from 'hono/utils/stream';
import { markTaskEnd, markTaskStart } from '../middleware/isRuningTask';
import { createCaption } from './generators/generateCaption';

const thumbAndHashGenerate = async (media: any, stream: StreamingApi) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.source_file);
    const output = path.join(Bun.env.MAIN_PATH, media.thumb_path);

    await createFolder(output);
    const { w, h } = await createThumbnail(input, output, media.file_type === 'Photo');
    const hash = await createHash(output);

    await stream.writeln(`${media.file_name}`);
    if (w && h) await updateHashThumb(media.media_id, hash, w, h);
  } catch (error) {
    console.error(`thumbAndHashGenerate - Source: ${media.source_file}: ${error}`);
    await insertErrorLog('service/index.ts', 'thumbAndHashGenerate', `error - ${media.source_file}`);
  }
};

export const processMedias = async (stream: StreamingApi) => {
  const loadedmedias = await importedMediasThumbHash();
  const tasks = loadedmedias.map((media: any) => () => thumbAndHashGenerate(media, stream));
  try {
    await workerQueue(tasks);
    console.log('======= PROCESS THUMBNAIL AND HASH COMPLETED =======');

    return true;
  } catch (error) {
    console.error('processMedias worker', error);
    await insertErrorLog('service/index.ts', 'processMedias', error);
    return false;
  }
};

export const processCaptioning = async () => {
  // Create BLOCK call for not over load server while processing caption for medias
  try {
    markTaskStart('captioning');

    const mediasForCaption = await importedMediasCaption();
    await createCaption(mediasForCaption);

    console.log('======= PROCESS CAPTION HAS BEEN COMPLETED =======');
  } catch (error) {
    console.error('processCaptioning', error);
    await insertErrorLog('service/index.ts', 'processCaptioning', error);
  } finally {
    markTaskEnd('captioning');
  }
};
