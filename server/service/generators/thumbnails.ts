import { $ } from 'bun';

const SIZE_THUMBNAIL: string = '512x512\\>';

const getDimention = (inputDim: string) => {
  const [w, h] = inputDim.split(' ');
  return { w, h };
};

export const createThumbnail = async (input: string, output: string, isPhoto: boolean, duration = 0.5): Promise<any> => {
  try {
    const command = isPhoto
      ? $`magick ${input.concat('\[0\]')} -auto-orient -thumbnail ${SIZE_THUMBNAIL} -quality 80 -write ${output} -format "%w %h" info:`
      : $`ffmpeg -hide_banner -loglevel error -i ${input} \
        -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -auto-orient \
        -thumbnail ${SIZE_THUMBNAIL} -quality 80 -write ${output} -format "%w %h" info:`;

    const { stdout, stderr, exitCode } = await command.quiet();

    if (exitCode !== 0) return console.error('createThumbnail', stderr);
    return getDimention(stdout.toString());
  } catch (error) {
    console.error(`createThumbnail Throw ${input}: ${error}`);
  }
};
