import { $ } from 'bun';
import path from 'path';
import { deleteImportMedia, mediaWoThumb, updateThumb } from '../db/module/media';
import { createFolder, isExist } from './fileModify';

const SIZE_THUMBNAIL: string = '640x640';

const createThumbImg = async (input: string, output: string): Promise<void> => {
  try {
    const { stderr, exitCode } = await $`magick ${input} -resize ${SIZE_THUMBNAIL} ${output}`;
    if (exitCode !== 0) return console.error('Error:', stderr);

    console.log('Image Thumb Converted! ', path.basename(input));
  } catch (error: any) {
    console.error(`Error: ${error.message}, ${input}`);
  }
};

const createThumbVideo = async (input: string, output: string, duration: number = 1): Promise<void> => {
  try {
    const { stderr, exitCode } = await $`ffmpeg -hide_banner -loglevel error -i ${input} \
      -ss 00:00:0${duration} -vframes 1 -f image2pipe -vcodec png - | magick - -strip \
      -resize ${SIZE_THUMBNAIL}\> ${output}`;
    if (exitCode !== 0) return console.error('Error:', stderr);

    console.log('Video Thumb Converted! ', path.basename(input));
  } catch (error: any) {
    console.error(`Error: ${error.message}, ${input}`);
  }
};

const createThumbnails = async () => {
  const loadedmedias = await mediaWoThumb(1);
  // const processThumbs = new Promise((resolve, reject) => {
  //   loadedmedias.forEach(async (media: { SourceFile: string; ThumbPath: string; FileType: string }) => {
  //     const input = path.join(Bun.env.MAIN_PATH, media.SourceFile);
  //     const output = path.join(Bun.env.MAIN_PATH, media.ThumbPath);
  //     if (!(await isExist(output))) {
  //       await createFolder(output);
  //       media.FileType === 'Photo' ? createThumbImg(input, output) : await createThumbVideo(input, output);
  //     }
  //   });
  // });
  // processThumbs.then(() => {
  //   loadedmedias.forEach(async (media: { media_id: number; SourceFile: string; ThumbPath: string; FileType: string }) => {
  //     await updateThumb(media.media_id);
  //     console.log('=======ALL THUMBNAILS CREATED=======');
  //   });
  // });

  for (const media of loadedmedias) {
    const input = path.join(Bun.env.MAIN_PATH, media.SourceFile);
    const output = path.join(Bun.env.MAIN_PATH, media.ThumbPath);
    if (!(await isExist(output))) {
      await createFolder(output);
      // No need to waiting for Image thumb create since it not take to long. But should wait for video
      media.FileType === 'Photo' ? createThumbImg(input, output) : await createThumbVideo(input, output);
    }
    // Need to update the media isThumbCreate to true after succesfully inserted
    // await updateThumb(media.media_id);
    // Delete all rows in Import medias table
    await deleteImportMedia();
  }
};

export { createThumbnails };
