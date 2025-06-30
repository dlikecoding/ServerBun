import type { UUID } from 'crypto';
import { sql } from '..';
import { insertErrorLog } from './system';
import { createRandomId, reducePath } from '../../service/helper';

const DURATION_OF_SHORT = 5; // Short video which has duration < 5s

export interface ImportMedia {
  SourceFile: string;
  FileName: string;
  FileType: string;
  FileSize: number;
  MIMEType: string;

  ImageWidth?: number;
  ImageHeight?: number;

  VideoFrameRate?: number;
  Duration?: number;
  Title: string | null;

  Software: string | null;

  Make?: string;
  Model?: string;
  LensModel: string | null;
  Orientation: string | null;
  Megapixels: number | null;

  CreateDate: string | null;
  DateCreated: string | null;
  CreationDate: string | null;
  DateTimeOriginal: string | null;
  FileModifyDate: string | null;
  MediaCreateDate: string | null;
  MediaModifyDate: string | null;

  GPSLatitude: string | null;
  GPSLongitude: string | null;
}

/**
 * Inserts a new media item into the system.
 * @param newMedia - The media object to be inserted, including metadata and a file reference.
 * @param RegisteredUser - The user performing the upload or import.
 */
export const insertImportedToMedia = async (newMedia: ImportMedia, RegisteredUser: UUID) => {
  try {
    const sourceFilePath = reducePath(newMedia.SourceFile);
    const mediaType = fileType(newMedia.MIMEType, newMedia.Duration); // Determine media type

    const cameraId = await insertCameraToDb(newMedia.Make, newMedia.Model);

    await sql.begin(async (tx) => {
      const smallestDate = getSmallestDate(newMedia);
      const durationDisplay = convertDuration(newMedia.Duration!);

      const mediaToInsert = {
        file_name: newMedia.FileName,
        file_type: mediaType,
        file_ext: newMedia.FileType,
        software: newMedia.Software,
        file_size: newMedia.FileSize,
        camera_type: cameraId,
        create_date: smallestDate,
        source_file: sourceFilePath,
        mime_type: newMedia.MIMEType,
        thumb_path: createThumbPath(smallestDate),

        orientation: newMedia.Orientation,
        image_width: newMedia.ImageWidth,
        image_height: newMedia.ImageHeight,
        megapixels: newMedia.Megapixels,

        lens_model: newMedia.LensModel,

        duration: newMedia.Duration,
        video_duration: durationDisplay,
        title: newMedia.Title,
        frame_rate: rountInt(newMedia.VideoFrameRate),

        // Insert GPS Data
        gps_latitude: newMedia.GPSLatitude,
        gps_longitude: newMedia.GPSLongitude,
      };

      const [mediaId] = await tx`
        INSERT INTO multi_schema."Media" ${sql(mediaToInsert)} 
        ON CONFLICT (source_file) DO NOTHING 
        RETURNING media_id`;

      if (!mediaId) return console.log('File had imported in the system');

      const lastMediaId: number = mediaId.media_id;

      await tx`
        INSERT INTO multi_schema."UploadBy" ("RegisteredUser", media) VALUES (${RegisteredUser}, ${lastMediaId})`;

      return lastMediaId;
    });
  } catch (error) {
    console.log('insertImportedToMedia', error);
    await insertErrorLog('db/module/imported.ts', 'insertImportedToMedia', error);
  }
};

// temporary////////////////////////////////
export const insertCameraToDb = async (make?: string, model?: string): Promise<number | null> => {
  if (!model) return null;

  const camId = await sql.begin(async (tx) => {
    const [getCamera] = await tx`
          SELECT camera_id FROM multi_schema."CameraType" 
          WHERE model = ${model}`;
    if (getCamera) return getCamera.camera_id;

    const insertCamera = { make: make ?? null, model: model };
    const [idInserted] = await tx`
          INSERT INTO "multi_schema"."CameraType" ${sql(insertCamera)} 
          ON CONFLICT DO NOTHING
          RETURNING camera_id`;

    if (idInserted) return idInserted.camera_id;
  });
  if (camId) return camId;

  // In case race condion exist, check again to get camera id.
  const [getCameraId] = await sql`
          SELECT camera_id FROM multi_schema."CameraType"
          WHERE model = ${model}`;

  if (getCameraId) return getCameraId.camera_id;

  console.log('Race condition failed to add camera type', model, make);
  return null;
};

const getSmallestDate = (newMedia: ImportMedia): Date => {
  const validDates = [
    newMedia.CreateDate,
    newMedia.DateCreated,
    newMedia.CreationDate,
    newMedia.DateTimeOriginal,
    newMedia.FileModifyDate,
    newMedia.MediaCreateDate,
    newMedia.MediaModifyDate,
  ]
    .map((date) => new Date(date!).getTime())
    .filter((date) => date > 0);

  const smallestDate = validDates.length ? new Date(Math.min(...validDates)) : new Date(); // Default to current date
  return smallestDate;
};

const fileType = (MIMEType: string, duration?: number) => {
  const prefix = MIMEType.split('/')[0];
  if (prefix === 'image') return 'Photo';
  if (prefix === 'video') return duration && duration > DURATION_OF_SHORT ? 'Video' : 'Live';
  return 'Unknown';
};

const createThumbPath = (inputDate: Date) => {
  const randomId = createRandomId(9);
  return `/Thumbnails/${inputDate.getFullYear()}/${inputDate.toLocaleString('default', { month: 'long' })}/${randomId}.webp`;
};

const convertDuration = (inputSecond: number) => {
  if (!inputSecond) return null;
  const hours = Math.floor(inputSecond / 3600);
  const minutes = Math.floor((inputSecond % 3600) / 60);
  const seconds = Math.round(inputSecond % 60);

  const formattedHours = hours === 0 ? '' : `${hours}:`;
  const formattedMinutes = minutes === 0 ? '0' : `${minutes}`;
  const formattedSeconds = seconds < 10 ? `0${seconds}` : `${seconds}`;

  return `${formattedHours}${formattedMinutes}:${formattedSeconds}`;
};

const rountInt = (input: any) => {
  if (!input) return 0;
  return Math.round(parseInt(input));
};
