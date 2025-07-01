import fs from 'fs';
import { insertErrorLog } from '../../db/module/system';
import { isExist } from '../helper';

export const createHash = async (input: string): Promise<string> => {
  try {
    if (!(await isExist(input))) return '';

    const hasher = new Bun.CryptoHasher('sha256');
    const stream = fs.createReadStream(input);

    await stream.forEach(async (chunk) => {
      hasher.update(new Uint16Array(chunk));
    });

    return hasher.digest('hex');
  } catch (error) {
    console.error(`createHash ${input}: ${error}`);
    await insertErrorLog('generators/hashcode.ts', 'createHash', `${error}`);
    return '';
  }
};
