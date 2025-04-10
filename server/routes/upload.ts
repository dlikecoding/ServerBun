import path from 'path';
import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';

import { createFolder, isExist, nameFolderByTime } from '../service/fsHelper';
import { getUserBySession } from '../middleware/validateAuth';
import { countFiles, insertMediaToDB, renameAllFiles } from '../db/main';
import { processMedias } from '../service';
import { streamText } from 'hono/streaming';
import { IS_IN_PROCESSING } from './authHelper/_cookies';

const GB = 1024 * 1024 * 1024;

const MAX_BODY_SIZE = 5 * GB; // limit total files size in bytes
const ALLOWED_FILE_SIZE = 1 * GB; // limit per file in bytes
const ALLOWED_MIME_TYPES = ['.jpg', '.gif', '.mov', '.mp4', '.heif', '.heic', '.jpeg', '.png'];

const upload = new Hono();

upload.get('/', (c) => {
  return c.json({ uploadpage: 'YOU ARE upload' });
});

upload.post(
  '/',
  bodyLimit({
    maxSize: MAX_BODY_SIZE,
    onError: (c) => {
      return c.json({ error: 'Reach file capaciry limited!' }, 413);
    },
  }),
  async (c) => {
    return streamText(c, async (stream) => {
      if (IS_IN_PROCESSING.status) {
        await stream.writeln('❌ Server is currently processing data. Please try again later.');
        return;
      }

      IS_IN_PROCESSING.status = true;

      const formData = await c.req.formData();
      const files = formData.getAll('uploadFiles') as File[];
      const userId = getUserBySession(c).userId;
      try {
        stream.onAbort(() => {
          console.warn('Client aborted the stream!');
        });
        await stream.writeln('Started processing medias ...');

        if (!files.length) {
          await stream.writeln('No files uploaded');
          return;
        }

        const writeToDir = path.join(Bun.env.UPLOAD_PATH, nameFolderByTime());
        await createFolder(writeToDir);

        const savedFiles: { name: string; size: number }[] = [];

        for (const eachFile of files) {
          try {
            if (!validateFileExt(eachFile)) {
              console.warn(`Blocked unsupported file: ${eachFile.name}`);
              await stream.writeln(`Unsupported file: ${eachFile.name}. Please upload a valid type.`);
              return;
            }

            if (eachFile.size > ALLOWED_FILE_SIZE) {
              console.warn(`Blocked large file: ${eachFile.name} (${eachFile.size} bytes)`);
              await stream.writeln(`Error: File '${eachFile.name}' is too large (${eachFile.size} bytes).`);
              return;
            }

            const filePath = path.join(writeToDir, eachFile.name);
            if (!filePath.startsWith(Bun.env.UPLOAD_PATH)) {
              await stream.writeln(`Error processing '${eachFile.name}'. Please re-upload.`);
              return;
            }
            await Bun.write(filePath, eachFile); // Write file using Bun.write (efficient, handles streaming)

            savedFiles.push({ name: eachFile.name, size: eachFile.size });
            await stream.writeln(`File Uploaded: ${eachFile.name}`);
          } catch (err) {
            await stream.writeln(`Error processing file: ${eachFile.name}`);
            console.log(`Error processing file: ${eachFile.name} - ${err}`);
            return;
          }
        }

        if (!savedFiles.length) {
          await stream.writeln('Error: The uploaded files are invalid. Please check file format, size, or try again.');
          return;
        }

        const isValidDir = isExist(writeToDir);
        if (!isValidDir) {
          await stream.writeln('Error: Directory not found. Please ensure the directory exists');
          return;
        }

        const totalFiles = await countFiles(writeToDir);
        if (!totalFiles) {
          await stream.writeln('Warning: No files found in the current directory. Please check if the directory contains media files.');
          return;
        }

        const rename = await renameAllFiles(writeToDir);
        if (!rename) {
          await stream.writeln('Error: Failed to rename files. Please check file permissions and the files path are valid.');
          return;
        }

        const insertStatus = await insertMediaToDB(userId, writeToDir, stream, totalFiles);
        if (!insertStatus) {
          await stream.writeln('Error: Failed to importing medias to database.');
          return;
        }

        const processSts = await processMedias(stream); // create thumbnail and hash keys
        if (!processSts) {
          await stream.writeln('Error: Failed to create thumb for medias');
          return;
        }

        await stream.writeln('✅ Finished Uploading Medias!');

        IS_IN_PROCESSING.status = false;
      } catch (error) {
        await stream.writeln(`Error: 500 Internal Server Error`);
        console.error('upload.post', error);
      }
    });
  }
);

const validateFileExt = (file: File): Boolean => {
  const ext = path.extname(file.name).toLowerCase();
  return ALLOWED_MIME_TYPES.includes(ext);
};

export default upload;
