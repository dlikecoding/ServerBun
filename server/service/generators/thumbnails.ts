import { $ } from 'bun';
import { insertErrorLog } from '../../db/module/system';

const SIZE_THUMBNAIL: string = '512x512\\>';
const QUALITY = 80;

// const getDimention = (inputDim: string) => {
//   const [w, h] = inputDim.split(' ');
//   return { w, h };
// };

export const createThumbnail = async (input: string, output: string, fileType: 'Photo' | 'Video' | 'Live', vidDuration: number): Promise<any> => {
  try {
    const duration = fileType === 'Video' ? 0.5 : vidDuration;

    const command =
      fileType === 'Photo'
        ? $`magick ${input.concat('\[0\]')} -auto-orient -thumbnail ${SIZE_THUMBNAIL} -quality ${QUALITY} ${output}`
        : $`ffmpeg -hide_banner -loglevel error -i ${input} \
        -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -auto-orient \
        -thumbnail ${SIZE_THUMBNAIL} -quality ${QUALITY} ${output}`;

    const { stderr, exitCode } = await command.quiet();
    if (exitCode !== 0) {
      console.error(`createThumbnail Throw ${input}: ${stderr}`);
      await insertErrorLog('service/generators/thumbnails.ts', 'createThumbnail', stderr);
    }

    return exitCode === 0;
  } catch (error) {
    console.error(`createThumbnail Throw ${input}: ${error}`);
    await insertErrorLog('service/generators/thumbnails.ts', 'createThumbnail', error);
  }
};
