import path from 'path';
import { updateMediaCaption } from '../../db/module/media';
import { workerQueue } from '../workers';

const BATCH_SIZE_UPDATE_CAPTION = 200;

export type UpdateCaption = {
  media_id: number;
  caption: string;
};

/**
 * Sends a single task obj to the child process via stdin,
 * then waits and reads stdout line by line until it receives
 * a valid JSON response.
 *
 * Assumes:
 * - The child process outputs one JSON object per task on stdout.
 * - The response for each task arrives before the next task is sent.
 *
 * Parameters:
 * @param task - The task obj to send to the child process.
 * @param childProc - A Bun subprocess with 'pipe' mode for stdin and stdout.
 * @param reader - A shared ReadableStreamDefaultReader for reading stdout from the child.
 *
 * Returns:
 * A Promise that resolves with the parsed JSON response from the child process.
 *
 * Throws:
 * If the child process closes before a valid JSON response is received.
 */
const sendTask = async (task: object, childProc: Bun.Subprocess<'pipe', 'pipe', 'inherit'>, reader: ReadableStreamDefaultReader<Uint8Array>) => {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  // Serialize task as JSON and write it to the child process
  childProc.stdin.write(encoder.encode(JSON.stringify(task) + '\n'));

  // Wait for a JSON response line from the child
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    const text = decoder.decode(value).trim();
    for (const line of text.split('\n')) {
      try {
        const result = JSON.parse(line);
        return result;
      } catch {} // ignore non-JSON lines
    }
  }

  throw new Error('Child process closed before sending a JSON response');
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
    console.log(error);
  } finally {
    childProc.kill(); // Done — terminate the child process
  }
};

const workerUpdateCaption = async (captions: UpdateCaption[]) => {
  const tasks = captions.map((media: UpdateCaption) => () => updateMediaCaption(media));
  await workerQueue(tasks);
};
