import path from 'path';
import { createThumbnail } from './generators/generateThumb';
import { createFolder } from './fsHelper';
import { createHash } from './generators/generateSHA';
import { importedMedias, updateHashThumb } from '../db/module/media';
import { workerQueue } from './workers';
import type { StreamingApi } from 'hono/utils/stream';

const processThumbSHA256 = async (media: any, stream: StreamingApi) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.SourceFile);
    const output = path.join(Bun.env.MAIN_PATH, media.ThumbPath);

    await createFolder(output);
    const { w, h } = await createThumbnail(input, output, media.FileType === 'Photo');
    const hash = await createHash(output);

    await stream.writeln(`${media.FileName}`);
    if (w && h) await updateHashThumb(media.media_id, hash, w, h);
  } catch (error) {
    console.error(`Failed processing - Source: ${media.SourceFile} Thumb: ${media.ThumbPath}: ${error}`);
  }
};

export const processMedias = async (stream: StreamingApi) => {
  const loadedmedias = await importedMedias();
  const tasks = loadedmedias.map((media: any) => () => processThumbSHA256(media, stream));
  try {
    await workerQueue(tasks);
    console.log('======= PROCESS THUMBNAIL AND HASH COMPLETED =======');
  } catch (error) {
    await stream.writeln('Error processing Thumbnail');
    console.warn('Error processing Thumbnail', error);
  }
};
