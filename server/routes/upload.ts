import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';

import { getUserBySession } from '../middleware/validateAuth';
import { processCaptioning } from '../service';
import { streamText } from 'hono/streaming';

import { MAX_BODY_SIZE, VALIDATED_RESULT, validateFiles, type ValidResult } from '../middleware/validateFiles';
import { markTaskEnd, markTaskStart, taskImportStatusMiddleware } from '../middleware/isRuningTask';
import { insertErrorLog } from '../db/module/system';
import { streamingImportMedia } from './importHelper/_imports';
import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';

const upload = new Hono();

const isAiModeSchema = z.object({
  aimode: z.coerce.number().min(0).max(1).default(0),
});

upload.post(
  '/',
  taskImportStatusMiddleware,
  validateSchema('json', isAiModeSchema),

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
        markTaskStart('importing');
        await stream.writeln('⏳ Started processing uploaded medias ...');

        const importing = await streamingImportMedia(stream, userId, safeFileDir);
        if (!importing) return;

        await stream.writeln(`✅ Finished Uploading: ${validatedFiles}/${totalFile} files!`);
        await stream.close();

        // Generate captions for medias in the background
        return await processCaptioning();
      } catch (error) {
        await stream.writeln(`❌ 500 Internal Server Error`);
        // console.log('upload.post:', error);
        await insertErrorLog('upload.ts', 'upload.post', error);
      } finally {
        if (!stream.closed) await stream.close();
        markTaskEnd('importing');
      }
    });
  }
);

export default upload;
