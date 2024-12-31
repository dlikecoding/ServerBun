import * as fs from 'fs/promises';
import path from 'path';

async function isFile(fPath: string) {
  const stats = await fs.stat(fPath);
  return stats.isFile();
}

async function isExist(path: string) {
  return await fs.exists(path);
}

async function deleteFileOrDE(fPath: string) {
  try {
    (await isFile(fPath)) ? await fs.unlink(fPath) : await fs.rm(fPath, { recursive: true });
    return console.log(`DELETED ${fPath} -> Deleted successfully.`);
  } catch (error: any) {
    // recordErrorInDB(
    //     'deleteFileOrDE: ',
    //     `Error deleting ${folderPath}: ${error.message}`
    // );
  }
}

const createFolder = async (dePath: string, isRecursive: boolean = true) => {
  try {
    if (path.extname(dePath)) {
      dePath = path.dirname(dePath);
    }
    if (await isExist(dePath)) return;

    await fs.mkdir(dePath, { recursive: isRecursive });
    console.log('Successfully create FOLDER!');
  } catch (error: any) {
    console.log('createFolder: ', `Error: ${dePath}, ${error.message}`);
  }
};

const removeFilesUploadDir = async (dePath: string) => {
  try {
    if (!(await isExist(dePath))) return;
    await fs.rm(dePath, { recursive: true, force: true });
  } catch (error: any) {
    // recordErrorInDB(
    //     'removeFilesUploadDir: ',
    //     `Error: ${dePath}, ${error.message}`
    // );
  }
};

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

async function removeEmptyDirectories(dir: string): Promise<void> {
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
}

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

export { deleteFileOrDE, createFolder, removeFilesUploadDir, isDirEmpty, removeEmptyDirectories, convertFileSize, diskCapacity, isExist };
