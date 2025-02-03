import fs from 'fs';
import path from 'path';
import { importedMedias, updateHash } from '../db/module/media';
import { MAX_CONCURRENT_WORKERS, workerQueue } from './workers';

const createHash = async (input: string): Promise<any> => {
  try {
    const hasher = new Bun.CryptoHasher('sha256');
    const stream = fs.createReadStream(input);

    for await (const chunk of stream) {
      hasher.update(new Uint8Array(chunk));
    }
    return hasher.digest('hex');
  } catch (error) {
    console.error(`Error processing ${input}: ${error}`);
  }
};

const processHash = async (media: any) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.SourceFile);

    const hash = await createHash(input);
    await updateHash(media.media_id, hash);
  } catch (error) {
    console.error(`Failed processing ${media.SourceFile}: ${error}`);
  }
};

const createHashs = async () => {
  const loadedmedias = await importedMedias();
  const tasks = loadedmedias.map((media: any) => () => processHash(media));

  await workerQueue(tasks, MAX_CONCURRENT_WORKERS);

  console.log('======= HASH PROCESS COMPLETED =======');
};

export { createHashs };
