import fs from 'fs';
import { insertErrorLog } from '../../db/module/system';

export const createHash = async (input: string): Promise<any> => {
  try {
    const hasher = new Bun.CryptoHasher('sha256');
    const stream = fs.createReadStream(input);

    await stream.forEach(async (chunk) => {
      hasher.update(new Uint16Array(chunk));
    });

    return hasher.digest('hex');
  } catch (error) {
    console.error(`createHash ${input}: ${error}`);
    await insertErrorLog('generators/hashcode.ts', 'createHash', `${error}`);
  }
};
