import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';

import { getUserBySession } from '../middleware/validateAuth';
import { insertMediaToDB, renameAllFiles } from '../db/main';
import { processCaptioning, processMedias } from '../service';
import { streamText } from 'hono/streaming';

import { MAX_BODY_SIZE, VALIDATED_RESULT, validateFiles, type ValidResult } from '../middleware/validateFiles';
import { taskStatusMiddleware } from '../middleware/isRuningTask';

const upload = new Hono();

upload.get('/', (c) => {
  return c.json({ uploadpage: 'YOU ARE upload' });
});

upload.post(
  '/',
  taskStatusMiddleware('captioning'),
  bodyLimit({
    maxSize: MAX_BODY_SIZE,
    onError: (c) => {
      return c.json({ error: '❌ File(s) too large. Try a smaller file.' }, 413);
    },
  }),
  validateFiles,
  async (c) => {
    return streamText(c, async (stream) => {
      const userId = getUserBySession(c).userId;
      const { totalFile, validatedFiles, safeFileDir } = c.get(VALIDATED_RESULT) as ValidResult;

      try {
        stream.onAbort(() => console.warn('Client aborted the stream!'));
        await stream.writeln('⏳ Started processing uploaded medias ...');

        await stream.writeln('📥 Sanitizing uploaded files ...');
        const rename = await renameAllFiles(safeFileDir);
        if (!rename) {
          await stream.writeln('❌ Failed to rename files. Please check file permissions and the files path are valid.');
          return;
        }

        await stream.writeln('⏳ Importing uploaded files to system...');
        const insertStatus = await insertMediaToDB(userId, safeFileDir);
        if (!insertStatus) {
          await stream.writeln('❌ Failed to importing medias to database.');
          return;
        }

        const processSts = await processMedias(stream); // create thumbnail and hash keys
        if (!processSts) {
          await stream.writeln('❌ Failed to create thumb for medias');
          return;
        }

        await stream.writeln(`✅ Finished Uploading: ${validatedFiles}/${totalFile} files!`);
        await stream.close();

        // Generate captions for medias in the background
        return await processCaptioning();
      } catch (error) {
        await stream.writeln(`❌ 500 Internal Server Error`);
        console.error('upload.post', error);
      } finally {
        if (!stream.closed) await stream.close();
      }
    });
  }
);

export default upload;
