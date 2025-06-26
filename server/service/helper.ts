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

export const deleteFile = async (filePath: string): Promise<boolean> => {
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

export const reducePath = (absolutePath: string): string => (absolutePath.startsWith(Bun.env.MAIN_PATH) ? absolutePath.slice(Bun.env.MAIN_PATH.length) : absolutePath);

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

export const diskCapacity = async (pathToCheck: string): Promise<{ total: number; used: number; free: number } | null> => {
  try {
    const { stdout } = await $`df -k ${pathToCheck}`.quiet();

    const output = new TextDecoder().decode(stdout);
    const lines = output.trim().split('\n');

    const parts = lines[1].split(/\s+/);
    const total = parseInt(parts[1]) * 1024;
    const used = parseInt(parts[2]) * 1024;
    const free = parseInt(parts[3]) * 1024;

    return { total, used, free };
  } catch (error) {
    await insertErrorLog('service/helper.ts', 'diskCapacity', error);
    return null;
  }
};

export const getDirName = (dirPath: string) => dirPath.split('/').at(-1);

// Remove directory recursively and forcefully
const removeDirRecursive = async (targetPath: string): Promise<void> => {
  await fs.rm(targetPath, { recursive: true, force: true });
};

// Check if directory is empty
const isDirEmpty = async (targetPath: string): Promise<boolean> => {
  const files = await fs.readdir(targetPath);
  return files.length === 0;
};

export const removeEmptyDirs = async (dir: string): Promise<void> => {
  const entries = await fs.readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (!(await isExist(fullPath))) continue;

    if (entry.isDirectory()) {
      await removeEmptyDirs(fullPath);

      if (await isDirEmpty(fullPath)) {
        await removeDirRecursive(fullPath);
        console.log(`[Cleanup] Removed empty directory: ${fullPath}`);
      }
    }
  }
};
