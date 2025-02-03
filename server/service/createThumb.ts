import path from 'path';

import { $ } from 'bun';
import { mediaWoThumb, updateThumb } from '../db/module/media';
import { createFolder } from './fileModify';
import { MAX_CONCURRENT_WORKERS, workerQueue } from './workers';

const SIZE_THUMBNAIL: string = '500x500\\>';

const getDimention = (inputDim: string) => {
  const [w, h] = inputDim.split(' ');
  return { w, h };
};

const createThumbImg = async (input: string, output: string): Promise<any> => {
  try {
    const inputIMG = input.concat('\[0\]'); //Extract first frame for gif //input.concat('\[0\]') //`${input}\\[0\\]`

    const { stdout, stderr, exitCode } = await $`magick ${inputIMG} -auto-orient -thumbnail ${SIZE_THUMBNAIL} -quality 75 -write ${output} -format "%w %h" info:`;

    if (exitCode !== 0) return console.error('Error:', stderr);
    console.log('Image Thumb Converted! ', path.basename(input));
    return getDimention(stdout.toString());
  } catch (error: any) {
    console.error(`Error: ${error.message}, ${input}`);
  }
};

const createThumbVideo = async (input: string, output: string, duration: number = 1): Promise<any> => {
  try {
    const { stdout, stderr, exitCode } = await $`ffmpeg -hide_banner -loglevel error -i ${input} \
      -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -auto-orient \
       -thumbnail ${SIZE_THUMBNAIL} -quality 75 -write ${output} -format "%w %h" info:`;
    if (exitCode !== 0) return console.error('Error:', stderr);
    console.log('Video Thumb Converted! ', path.basename(input));
    return getDimention(stdout.toString());
  } catch (error: any) {
    console.error(`Error: ${error.message}, ${input}`);
  }
};

const createThumbnail = async (input: string, output: string, isPhoto: boolean, duration = 1): Promise<any> => {
  try {
    const command = isPhoto
      ? $`magick ${input.concat('\[0\]')} -auto-orient -thumbnail ${SIZE_THUMBNAIL} -quality 75 -write ${output} -format "%w %h" info:`
      : $`ffmpeg -hide_banner -loglevel error -i ${input} \
        -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -auto-orient \
        -thumbnail ${SIZE_THUMBNAIL} -quality 75 -write ${output} -format "%w %h" info:`;

    const { stdout, stderr, exitCode } = await command;

    if (exitCode !== 0) return console.error('Error:', stderr);

    console.log(`Thumb Converted: `, input);
    return getDimention(stdout.toString());
  } catch (error) {
    console.error(`Error processing ${input}: ${error}`);
  }
};

const processThumbnail = async (media: any) => {
  try {
    const input = path.join(Bun.env.MAIN_PATH, media.SourceFile);
    const output = path.join(Bun.env.MAIN_PATH, media.ThumbPath);

    await createFolder(output);
    // const { w, h } = media.FileType === 'Photo' ? await createThumbImg(input, output) : await createThumbVideo(input, output);
    const { w, h } = await createThumbnail(input, output, media.FileType === 'Photo');

    if (w && h) await updateThumb(media.media_id, w, h);
  } catch (error) {
    console.error(`Failed processing ${media.SourceFile}: ${error}`);
  }
};

const createThumbnails = async () => {
  const loadedmedias = await mediaWoThumb();
  const tasks = loadedmedias.map((media: any) => () => processThumbnail(media));

  await workerQueue(tasks, MAX_CONCURRENT_WORKERS);
  // await deleteImportMedia();
  console.log('======= ALL THUMBNAILS CREATED =======');
};
export { createThumbnails };
