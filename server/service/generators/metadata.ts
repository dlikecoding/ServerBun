import { $ } from 'bun';
import path from 'path';
import * as fs from 'fs/promises';
import { BATCH_SIZE_INSERT } from '..';
import type { UUID } from 'crypto';
import type { StreamingApi } from 'hono/utils/stream';

import { workerQueue } from '../workers';
import { insertErrorLog } from '../../db/module/system';
import { ALLOWED_MIME_TYPES } from '../../middleware/validateFiles';
import { copyFile, moveUnsupportFile, renameIfInvalid, startWithDot } from '../helper';
import { insertImportedToMedia, type ImportMedia } from '../../db/module/imported';

export interface ImportTrack {
  count: number;
  sourcePaths: string[];
}

/** Loop through all file in directory, get file path, verify and extract metadata */
export const recursiveDir = async (dePath: string, tracking: ImportTrack, RegisteredUser: UUID, stream: StreamingApi): Promise<void> => {
  try {
    const files = await fs.readdir(dePath);
    for (const file of files) {
      const sourcePath = path.join(dePath, file);

      // Ignore all file start with . (ussally from mac os)
      if (startWithDot(sourcePath)) continue;

      const stat = await fs.stat(sourcePath);

      if (stat.isDirectory()) {
        await recursiveDir(sourcePath, tracking, RegisteredUser, stream);
      } else {
        await updateTrackingAndFileValidate(sourcePath, tracking);

        if (tracking.sourcePaths.length >= BATCH_SIZE_INSERT) {
          await insertMetadataToDB(tracking, RegisteredUser);
          await stream.writeln(`𒁋 Extracted Metadata of ${tracking.count} files...`);
        }
      }
    }
  } catch (error) {
    console.log('service/generator/metadata.ts', 'recursiveDir', error);
    await insertErrorLog('service/generator/metadata.ts', 'recursiveDir', error);
  }
};

export const insertMetadataToDB = async (tracking: ImportTrack, RegisteredUser: UUID): Promise<any> => {
  try {
    // insert To Database source files
    const metadatas = await extractMetadata(tracking.sourcePaths);
    const tasks = metadatas.map((media: ImportMedia) => () => insertImportedToMedia(media, RegisteredUser));
    await workerQueue(tasks);

    // on success, clear tracking.sourcePaths
    tracking.sourcePaths.length = 0;
  } catch (error) {
    console.log('service/generator/metadata.ts', 'recursiveDir', error);
    await insertErrorLog('service/generator/metadata.ts', 'recursiveDir', error);
  }
};

const extractMetadata = async (sourcePaths: string[]): Promise<ImportMedia[]> => {
  const { stdout, stderr, exitCode } = await $`exiftool -json -d "%Y-%m-%dT%H:%M:%S" \
      -SourceFile -FileName -FileType -MIMEType \
      -Software -Title -FileSize# -Make -Model -LensModel -Orientation -CreateDate -DateCreated \
      -CreationDate -DateTimeOriginal -FileModifyDate -MediaCreateDate -MediaModifyDate -Duration# \
      -GPSLatitude# -GPSLongitude# -ImageWidth -ImageHeight -Megapixels -VideoFrameRate ${sourcePaths}`.quiet();

  if (exitCode !== 0) {
    console.log('service/generator/metadata.ts', 'extractMetadata', stderr);
    await insertErrorLog('service/generator/metadata.ts', 'extractMetadata', stderr);
  }

  return JSON.parse(stdout.toString().trim());
};

const updateTrackingAndFileValidate = async (sourcePath: string, tracking: ImportTrack): Promise<any> => {
  const process = await validateFileExt(sourcePath);

  // if file not support: Move to unsupport
  if (!process) {
    await moveUnsupportFile(sourcePath);
    return;
  }
  // if filename is invalid, rename the file and push the new path to the list
  const sourceFile = await renameIfInvalid(sourcePath);
  ++tracking.count;
  tracking.sourcePaths.push(sourceFile);
};

const validateFileExt = async (file: string): Promise<boolean> => {
  const fileExt = path.extname(file).toLowerCase();
  return ALLOWED_MIME_TYPES.includes(fileExt);
};

export const copyFileToExternalDir = async (copyToPath: string, dest: string): Promise<void> => {
  const files = await fs.readdir(copyToPath);
  for (const file of files) {
    const sourcePath = path.join(copyToPath, file);

    // Ignore all file start with . (ussally mac os automaticly created)
    if (startWithDot(sourcePath)) continue;

    const stat = await fs.stat(sourcePath);

    if (stat.isDirectory()) {
      await copyFileToExternalDir(sourcePath, dest);
    } else {
      // Only include allow files with extension
      const isValidExt = await validateFileExt(sourcePath);

      if (isValidExt) {
        const copyStatus = await copyFile(sourcePath, dest);
        if (!copyStatus) console.log('❌ Failed to copy files to system.');
      }
    }
  }
};
