import path from 'path';
import { createMiddleware } from 'hono/factory';
import { createFolder, createRandomId, nameFolderByTime } from '../service/helper';

const GB = 1024 * 1024 * 1024;

const ALLOWED_FILE_SIZE = 1 * GB; // limit per file in bytes
const ALLOWED_MIME_TYPES = ['.webp', '.jpg', '.gif', '.mov', '.mp4', '.heif', '.heic', '.jpeg', '.png'];
export const MAX_BODY_SIZE = 2 * GB; // limit total files size in bytes

export const VALIDATED_RESULT = 'validated_result';

export interface ValidResult {
  validatedFiles: number;
  totalFile: number;
  safeFileDir: string;
}

export const validateFiles = createMiddleware(async (c, next) => {
  const formData = await c.req.formData();
  const files = formData.getAll('uploadFiles') as File[];

  let validFiles = 0;

  const writeToDir = path.join(Bun.env.UPLOAD_PATH, nameFolderByTime());
  await createFolder(writeToDir);

  for (const file of files) {
    const extValid = validateFileExt(file);
    const sizeValid = file.size <= ALLOWED_FILE_SIZE;

    if (!extValid || !sizeValid) continue;

    const fileName = `${createRandomId(12)}.${fileExt(file)}`; // Create a new file name with extension for each file
    const filePath = path.join(writeToDir, fileName);

    await Bun.write(filePath, file); // Write file using Bun.write (efficient, handles streaming)
    validFiles++;
  }

  if (!validFiles) {
    return c.json({ error: '❌ Bad request. No valid files uploaded.' }, 400);
  }

  const validResult: ValidResult = {
    totalFile: files.length,
    validatedFiles: validFiles,
    safeFileDir: writeToDir,
  };
  c.set(VALIDATED_RESULT, validResult);

  return await next();
});

const fileExt = (file: File): string => {
  return path.extname(file.name).toLowerCase();
};

const validateFileExt = (file: File): boolean => {
  return ALLOWED_MIME_TYPES.includes(fileExt(file));
};
