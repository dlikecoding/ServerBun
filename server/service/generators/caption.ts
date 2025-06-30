import path from 'path';
import { updateMediaCaption } from '../../db/module/media';
import { workerQueue } from '../workers';
import { BATCH_SIZE_UPDATE_CAPTION, sendTask } from './_sendTaskHelper';
import { insertErrorLog } from '../../db/module/system';

export type UpdateCaption = {
  media_id: number;
  caption: string;
};

export const createCaption = async (medias: any[]): Promise<any> => {
  const pythonFilePath = 'models/ai_model/image_captioning.py';

  const totalFile = medias.length;
  if (!totalFile) return;

  let count = 0;

  const childProc = Bun.spawn(['python3', pythonFilePath], {
    stdout: 'pipe',
    stdin: 'pipe',
  });

  const captions: UpdateCaption[] = [];

  try {
    console.log(childProc.pid);
    const reader = childProc.stdout.getReader();

    for (const media of medias) {
      const resData: UpdateCaption = await sendTask({ id: media.media_id, path: path.join(Bun.env.MAIN_PATH, media.thumb_path) }, childProc, reader);
      console.log(`Generating Caption: ${++count}/${totalFile}`); //{ media_id: 7, caption: "a black dragon flying through the sky" }

      if (captions.length >= BATCH_SIZE_UPDATE_CAPTION) {
        await workerUpdateCaption(captions);
        captions.length = 0;
      }
      captions.push(resData);
    }

    if (captions.length >= 0) await workerUpdateCaption(captions);
  } catch (error) {
    await insertErrorLog('service/generate/captions.ts', 'createCaption', error);
    console.log(error);
  } finally {
    childProc.kill(); // Done — terminate the child process
  }
};

const workerUpdateCaption = async (captions: UpdateCaption[]) => {
  const tasks = captions.map((media: UpdateCaption) => () => updateMediaCaption(media));
  await workerQueue(tasks);
};
