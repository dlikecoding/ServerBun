import type { UUID } from 'crypto';
import { sql } from '..';
import { insertErrorLog } from './system';
import { createRandomId } from '../../service/helper';

const DURATION_OF_SHORT = 5; // Short video which has duration < 5s

export interface ImportMedia {
  SourceFile: string;
  FileName: string;
  FileType: string;
  FileSize: number;
  MIMEType: string;

  ImageWidth?: number;
  ImageHeight?: number;
  Duration?: number;

  Software: string | null;
  Title: string | null;
  Make: string | null;
  Model: string | null;
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

export const insertImportedToMedia = async (newMedia: ImportMedia, RegisteredUser: UUID) => {
  try {
    const mediaType = fileType(newMedia.MIMEType, newMedia.Duration); // Determine media type
    if (mediaType === 'Unknown') return;

    const insertedMedia = await sql.begin(async (tx) => {
      let cameraTypeId: number | null = null;
      if (newMedia.Make && newMedia.Model) {
        const [isCameraExist] = await tx`
          SELECT camera_id FROM multi_schema."CameraType" 
          WHERE make = ${newMedia.Make} AND model = ${newMedia.Model} LIMIT 1`;
        if (isCameraExist) {
          cameraTypeId = isCameraExist.camera_id;
        } else {
          const [cameraInserted] = await tx`
            INSERT INTO multi_schema."CameraType" (make, model) VALUES (${newMedia.Make}, ${newMedia.Model}) RETURNING camera_id`;
          cameraTypeId = cameraInserted.camera_id;
        }
      }

      const smallestDate = getSmallestDate(newMedia);
      const durationDisplay = convertDuration(newMedia.Duration!);

      const mediaToInsert = {
        file_name: newMedia.FileName,
        file_type: mediaType,
        file_ext: newMedia.FileType,
        software: newMedia.Software,
        file_size: newMedia.FileSize,
        camera_type: cameraTypeId,
        create_date: smallestDate,
        source_file: newMedia.SourceFile,
        mime_type: newMedia.MIMEType,
        thumb_path: createThumbPath(smallestDate),
        video_duration: durationDisplay,
      };

      const [mediaId] = await tx`
        INSERT INTO multi_schema."Media" ${sql(mediaToInsert)} RETURNING media_id`;
      const lastMediaId = mediaId.media_id;

      await tx`
        INSERT INTO multi_schema."UploadBy" ("RegisteredUser", media) VALUES (${RegisteredUser}, ${lastMediaId})`;

      if (mediaType === 'Photo') {
        await tx`
          INSERT INTO multi_schema."Photo" (media, orientation, image_width, image_height, megapixels) VALUES ( ${lastMediaId}, ${newMedia.Orientation}, ${newMedia.ImageWidth}, ${newMedia.ImageHeight}, ${newMedia.Megapixels})`;
      } else {
        const insertVid = { media: lastMediaId, duration: newMedia.Duration, title: newMedia.Title };
        mediaType === 'Video'
          ? await tx`
          INSERT INTO multi_schema."Video" ${sql(insertVid)}`
          : await tx`
          INSERT INTO multi_schema."Live" ${sql(insertVid)}`;
      }

      // Insert GPS Data
      if (newMedia.GPSLatitude && newMedia.GPSLongitude) {
        await tx`
          INSERT INTO multi_schema."Location" (media, gps_latitude, gps_longitude) VALUES (${lastMediaId}, ${newMedia.GPSLatitude}, ${newMedia.GPSLongitude})`;
      }
      return lastMediaId;
    });
    return insertedMedia ? true : false;
  } catch (error) {
    console.log('insertImportedToMedia', error);
    await insertErrorLog('system.ts', 'initializeSystem', error);
    return false;
  }
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
