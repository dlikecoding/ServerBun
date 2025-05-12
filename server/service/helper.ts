import * as fs from 'fs/promises';
import { $ } from 'bun';
import path, { basename, dirname } from 'path';
import { rename } from 'fs/promises';
import { insertErrorLog } from '../db/module/system';

export const isExist = async (path: string) => {
  return await fs.exists(path);
};

export const createFolder = async (dePath: string, isRecursive: boolean = true) => {
  try {
    if (path.extname(dePath)) {
      dePath = path.dirname(dePath);
    }
    if (await isExist(dePath)) return;

    await fs.mkdir(dePath, { recursive: isRecursive });
  } catch (error: any) {
    console.log('service/helper.ts', 'createFolder', error);
    await insertErrorLog('service/helper.ts', 'createFolder', error);
  }
};

const deleteFile = async (filePath: string): Promise<boolean> => {
  const { exitCode, stderr } = await $`rm ${filePath}`.nothrow();
  if (exitCode === 0) return true;

  console.log('service/helper.ts', 'deleteFile', stderr);
  await insertErrorLog('service/helper.ts', 'deleteFile', stderr);
  return false;
};

export const copyFile = async (source: string, destination: string): Promise<boolean> => {
  const { exitCode, stderr } = await $`rsync -ahv ${source} ${destination}`.quiet().nothrow();
  if (exitCode === 0) return true;

  console.log('service/helper.ts', 'copyFile', stderr);
  await insertErrorLog('service/helper.ts', 'copyFile', stderr);
  return false;
};

const moveFile = async (oldPath: string, newPath: string): Promise<boolean> => {
  const copyTatus = await copyFile(oldPath, newPath);
  if (copyTatus) return await deleteFile(oldPath);
  return false;
};

const sanitizeFileName = (name: string): string => {
  return name.replace(/[^\w.-]/g, '_');
};

export const renameIfInvalid = async (sourcePath: string): Promise<string> => {
  try {
    const name = basename(sourcePath);
    const dir = dirname(sourcePath);
    const cleanName = sanitizeFileName(name);

    if (cleanName === name) return sourcePath;

    const oldPath = path.join(dir, name);
    const newPath = path.join(dir, cleanName);

    await rename(oldPath, newPath);
    return path.join(dir, cleanName);
  } catch (error) {
    await insertErrorLog('service/helper.ts', 'renameIfInvalid', error);
    console.log('renameIfInvalid', error);
    return '';
  }
};

export const moveUnsupportFile = async (source: string): Promise<boolean> => {
  const movePath = path.join(Bun.env.UNSUPPORT_PATH, nameFolderByTime(true));
  await createFolder(movePath);

  return await moveFile(source, path.join(movePath, basename(source)));
};

export const createRandomId = (length: number) => {
  return Math.random()
    .toString(36)
    .substring(2, 2 + length);
};

const formatDate = (component: number): string => {
  return String(component).padStart(2, '0');
};

export const nameFolderByTime = (isShort: boolean = false): string => {
  const currentDate = new Date();

  const year = currentDate.getFullYear();
  const month = formatDate(currentDate.getMonth() + 1);
  const day = formatDate(currentDate.getDate());

  if (isShort) return `${year}-${month}-${day}`;

  const hour = formatDate(currentDate.getHours());
  const minute = formatDate(currentDate.getMinutes());
  const second = formatDate(currentDate.getSeconds());

  return `${year}-${month}-${day}_${hour}-${minute}-${second}`;
};

// const removeFilesUploadDir = async (dePath: string) => {
//   try {
//     if (!(await isExist(dePath))) return;
//     await fs.rm(dePath, { recursive: true, force: true });
//   } catch (error: any) {
//     // recordErrorInDB(
//     //     'removeFilesUploadDir: ',
//     //     `Error: ${dePath}, ${error.message}`
//     // );
//   }
// };

// const isDirEmpty = async (dePath: string) => {
//   try {
//     const files = await fs.readdir(dePath);
//     if (files.length === 0) {
//       console.log(`Source directory "${dePath}" is EMPTY.`);
//       return true;
//     }
//     return false;
//   } catch (error: any) {
//     console.log(error);
//     // recordErrorInDB('isDirEmpty: ', `Error: ${dePath}, ${error.message}`);
//   }
// };

// const removeEmptyDirectories = async (dir: string): Promise<void> => {
//   try {
//     const entries = await fs.readdir(dir, { withFileTypes: true });

//     for (const entry of entries) {
//       const fullPath = path.join(dir, entry.name);

//       if (entry.isDirectory()) {
//         await removeEmptyDirectories(fullPath);

//         if (await isDirEmpty(fullPath)) {
//           await fs.rmdir(fullPath);
//           console.log(`Removed empty directory: ${fullPath}`);
//         }
//       }
//     }
//   } catch (error: any) {
//     // recordErrorInDB(
//     //     'removeEmptyDirectories: ',
//     //     `Error: ${dir}, ${error.message}`
//     // );
//   }
// };

// const convertFileSize = (bytes: number): string => {
//   const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
//   if (bytes === 0) return '0 Byte';
//   const i = Math.floor(Math.log(bytes) / Math.log(1024));

//   return Math.round(100 * (bytes / Math.pow(1024, i))) / 100 + ' ' + sizes[i];
// };

// const diskCapacity = async (pathToCheck: string): Promise<any> => {
//   try {
//     const capacity = await fs.statfs(pathToCheck);
//     return {
//       total: capacity.bsize * capacity.blocks,
//       used: (capacity!.blocks - capacity!.bfree) * capacity!.bsize,
//       free: capacity!.bsize * capacity!.bfree,
//     };
//   } catch (error) {
//     // return recordErrorInDB('diskCapacity', `Error: ${error}`);
//   }
// };

// export { isDirEmpty, removeEmptyDirectories, convertFileSize, diskCapacity, isExist };
