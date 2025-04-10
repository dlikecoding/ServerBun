import * as fs from 'fs/promises';
import path from 'path';

const isExist = async (path: string) => {
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
    console.log('createFolder: ', `Error: ${dePath}, ${error.message}`);
  }
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

const isDirEmpty = async (dePath: string) => {
  try {
    const files = await fs.readdir(dePath);
    if (files.length === 0) {
      console.log(`Source directory "${dePath}" is EMPTY.`);
      return true;
    }
    return false;
  } catch (error: any) {
    console.log(error);
    // recordErrorInDB('isDirEmpty: ', `Error: ${dePath}, ${error.message}`);
  }
};

const removeEmptyDirectories = async (dir: string): Promise<void> => {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await removeEmptyDirectories(fullPath);

        if (await isDirEmpty(fullPath)) {
          await fs.rmdir(fullPath);
          console.log(`Removed empty directory: ${fullPath}`);
        }
      }
    }
  } catch (error: any) {
    // recordErrorInDB(
    //     'removeEmptyDirectories: ',
    //     `Error: ${dir}, ${error.message}`
    // );
  }
};

const convertFileSize = (bytes: number): string => {
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  if (bytes === 0) return '0 Byte';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));

  return Math.round(100 * (bytes / Math.pow(1024, i))) / 100 + ' ' + sizes[i];
};

const diskCapacity = async (pathToCheck: string): Promise<any> => {
  try {
    const capacity = await fs.statfs(pathToCheck);
    return {
      total: capacity.bsize * capacity.blocks,
      used: (capacity!.blocks - capacity!.bfree) * capacity!.bsize,
      free: capacity!.bsize * capacity!.bfree,
    };
  } catch (error) {
    // return recordErrorInDB('diskCapacity', `Error: ${error}`);
  }
};

const formatDate = (component: number): string => {
  return String(component).padStart(2, '0');
};

const nameFolderByTime = (): string => {
  const currentDate = new Date();

  const year = currentDate.getFullYear();
  const month = formatDate(currentDate.getMonth() + 1);
  const day = formatDate(currentDate.getDate());
  const hour = formatDate(currentDate.getHours());
  const minute = formatDate(currentDate.getMinutes());
  const second = formatDate(currentDate.getSeconds());

  return `${year}-${month}-${day}_${hour}-${minute}-${second}`;
};
export { isDirEmpty, removeEmptyDirectories, convertFileSize, diskCapacity, isExist, nameFolderByTime };
