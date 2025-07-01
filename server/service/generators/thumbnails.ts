import { $ } from 'bun';
import { insertErrorLog } from '../../db/module/system';
import { isExist } from '../helper';

const SIZE_THUMBNAIL: string = '512x512\\>';
const QUALITY = 80;

export const createThumbnail = async (input: string, output: string, media: any): Promise<boolean> => {
  try {
    if (!(await isExist(input))) return false;

    const fileType = media.file_type;
    const duration = fileType === 'Video' ? 1 : Math.min(media.selected_frame, media.duration);

    const command =
      fileType === 'Photo'
        ? $`magick ${input.concat('\[0\]')} -auto-orient -thumbnail ${SIZE_THUMBNAIL} -quality ${QUALITY} ${output}`
        : $`ffmpeg -hide_banner -loglevel error -i ${input} \
        -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -auto-orient \
        -thumbnail ${SIZE_THUMBNAIL} -quality ${QUALITY} ${output}`;

    await command.quiet();

    return await isExist(output);
  } catch (error) {
    console.error(`createThumbnail Throw ${input}: ${error}`);
    await insertErrorLog('service/generators/thumbnails.ts', 'createThumbnail', error);
    return false;
  }
};
