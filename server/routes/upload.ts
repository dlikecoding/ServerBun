import path from 'path';
import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';

import { createFolder, nameFolderByTime } from '../service/fsHelper';
import { getUserBySession } from '../middleware/validateAuth';
import { insertMediaToDB } from '../db/maintain';
import { processMedias } from '../service';

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
      return c.json({ error: 'overflow :(' }, 413);
    },
  }),
  async (c) => {
    const formData = await c.req.formData();
    const files = formData.getAll('uploadFiles') as File[];

    if (!files.length) {
      return c.json({ error: 'No files uploaded' }, 400);
    }

    const writeToDir = path.join(Bun.env.UPLOAD_PATH, nameFolderByTime());
    await createFolder(writeToDir);

    const savedFiles: { name: string; size: number }[] = [];
    const invalidFiles: { name: string; error: string }[] = [];

    for (const eachFile of files) {
      try {
        if (!validateFileExt(eachFile)) {
          console.warn(`Blocked unsupported file: ${eachFile.name}`);
          invalidFiles.push({ name: eachFile.name, error: `Unsupported file type: ${eachFile.type}` });
          continue;
        }

        if (eachFile.size > ALLOWED_FILE_SIZE) {
          console.warn(`Blocked large file: ${eachFile.name} (${eachFile.size} bytes)`);
          invalidFiles.push({ name: eachFile.name, error: `File too large: ${eachFile.name}` });
          continue;
        }

        const filePath = path.join(writeToDir, eachFile.name);
        // Prevent directory traversal attacks
        if (!filePath.startsWith(Bun.env.UPLOAD_PATH)) {
          invalidFiles.push({ name: eachFile.name, error: `Invalid file path: ${eachFile.name}` });
          continue;
        }

        await Bun.write(filePath, eachFile); // Write file using Bun.write (efficient, handles streaming)

        savedFiles.push({ name: eachFile.name, size: eachFile.size });
        console.log(`✅ File saved: ${filePath}`);
      } catch (err) {
        console.error(`❌ Error processing file: ${eachFile.name}`, err);
      }
    }

    if (!savedFiles.length) return c.json({ error: `Failed to upload`, files: invalidFiles }, 400);

    const userId = getUserBySession(c).userId;

    const exitCode = await insertMediaToDB(userId, writeToDir);
    if (exitCode !== 0) return c.json({ error: 'Failed to Import media to account' }, 500);

    const proceedThumb = await processMedias();
    if (!proceedThumb) return c.json({ error: 'Failed to create Thumbs & Hash for medias' }, 500);

    return c.json({ message: 'Files uploaded successfully', saved: savedFiles, invalid: invalidFiles });
  }
);

const validateFileExt = (file: File): Boolean => {
  const ext = path.extname(file.name).toLowerCase();
  return ALLOWED_MIME_TYPES.includes(ext);
};

// upload.post(
//   '/',
//   // bodyLimit({
//   //   maxSize: MAX_UPLOAD_FILE_SIZE,
//   //   onError: (c) => {
//   //     return c.json({ error: 'overflow :(' }, 413);
//   //   },
//   // }),
//   async (c) => {
//     // const formData = await c.req.formData();
//     // const files = formData.getAll('file') as File[];
//     // // // const data = body['file']; //Single File
//     // // // const data = body['file[]'] // Multiple files

//     console.log('Got request files');

//     // if (body['file'] instanceof File) {
//     //   console.log(`Got file sized: ${body['file'].size}`);
//     // }
//     return c.json('pass :)');
//   }
// );

export default upload;
