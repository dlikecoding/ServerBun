import path from 'path';
import { createThumbnail } from './generators/generateThumb';
import { createFolder } from './fsHelper';
import { createHash } from './generators/generateSHA';
import { importedMedias, updateHashThumb } from '../db/module/media';
import { workerQueue } from './workers';
import type { StreamingApi } from 'hono/utils/stream';

const processThumbSHA256 = async (media: any, stream: StreamingApi) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.source_file);
    const output = path.join(Bun.env.MAIN_PATH, media.thumb_path);

    await createFolder(output);
    const { w, h } = await createThumbnail(input, output, media.file_type === 'Photo');
    const hash = await createHash(output);

    await stream.writeln(`${media.file_name}`);
    if (w && h) await updateHashThumb(media.media_id, hash, w, h);
  } catch (error) {
    console.error(`Failed processing - Source: ${media.source_file} Thumb: ${media.thumb_path}: ${error}`);
  }
};

export const processMedias = async (stream: StreamingApi) => {
  const loadedmedias = await importedMedias();
  const tasks = loadedmedias.map((media: any) => () => processThumbSHA256(media, stream));
  try {
    await workerQueue(tasks);
    console.log('======= PROCESS THUMBNAIL AND HASH COMPLETED =======');
    return true;
  } catch (error) {
    await stream.writeln('Error processing Thumbnail');
    console.warn('Error processing Thumbnail', error);
    return false;
  }
};
