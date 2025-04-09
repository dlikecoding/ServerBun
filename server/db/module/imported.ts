import type { UUID } from 'crypto';
import { sql } from '..';

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
        const [isCameraExist] = await tx`SELECT camera_id FROM "CameraType" WHERE make = ${newMedia.Make} AND model = ${newMedia.Model} LIMIT 1`;
        if (isCameraExist) {
          cameraTypeId = isCameraExist.camera_id;
        } else {
          const [cameraInserted] = await tx`INSERT INTO "CameraType" (make, model) VALUES (${newMedia.Make}, ${newMedia.Model}) RETURNING camera_id`;
          cameraTypeId = cameraInserted.camera_id;
        }
      }

      const smallestDate = getSmallestDate(newMedia);
      const thumbPath = createThumbPath(smallestDate);
      const [mediaId] = await tx`INSERT INTO "Media" (file_name, file_type, file_ext, software, file_size, camera_type, create_date, source_file, mime_type, thumb_path) VALUES (
        ${newMedia.FileName}, ${mediaType}, ${newMedia.FileType}, ${newMedia.Software}, ${newMedia.FileSize}, ${cameraTypeId}, ${smallestDate}, ${newMedia.SourceFile}, ${newMedia.MIMEType}, ${thumbPath})
        RETURNING media_id`;

      const lastMediaId = mediaId.media_id;

      await tx`INSERT INTO "UploadBy" ("RegisteredUser", media) VALUES (${RegisteredUser}, ${lastMediaId})`;

      if (mediaType === 'Photo') {
        await tx`INSERT INTO "Photo" (media, orientation, image_width, image_height, megapixels) VALUES ( ${lastMediaId}, ${newMedia.Orientation}, ${newMedia.ImageWidth}, ${newMedia.ImageHeight}, ${newMedia.Megapixels})`;
      } else if (mediaType === 'Video') {
        const durationDisplay = convertDuration(newMedia.Duration!);
        await tx`INSERT INTO "Video" (media, duration, title, display_duration) VALUES ( ${lastMediaId}, ${newMedia.Duration}, ${newMedia.Title}, ${durationDisplay})`;
      } else if (mediaType === 'Live') {
        await tx`INSERT INTO "Live" (media, duration, title) VALUES ( ${lastMediaId}, ${newMedia.Duration}, ${newMedia.Title})`;
      }

      // Insert GPS Data
      if (newMedia.GPSLatitude && newMedia.GPSLongitude) {
        await tx`INSERT INTO "Location" (media, gps_latitude, gps_longitude) VALUES (${lastMediaId}, ${newMedia.GPSLatitude}, ${newMedia.GPSLongitude})`;
      }
      return lastMediaId;
    });
    return insertedMedia ? true : false;
  } catch (error) {
    console.log(error);
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
  if (prefix === 'video') return duration && duration > 5 ? 'Video' : 'Live';
  return 'Unknown';
};

const createThumbPath = (inputDate: Date) => {
  return `/Thumbnails/${inputDate.getFullYear()}/${inputDate.toLocaleString('default', { month: 'long' })}/${Bun.randomUUIDv7()}.webp`;
};

const convertDuration = (inputSecond: number) => {
  if (!inputSecond) return ``;
  const hours = Math.floor(inputSecond / 3600);
  const minutes = Math.floor((inputSecond % 3600) / 60);
  const seconds = Math.round(inputSecond % 60);

  const formattedHours = hours === 0 ? '' : `${hours}:`;
  const formattedMinutes = minutes === 0 ? '0' : `${minutes}`;
  const formattedSeconds = seconds < 10 ? `0${seconds}` : `${seconds}`;

  return `${formattedHours}${formattedMinutes}:${formattedSeconds}`;
};

// const connection = await poolPromise.getConnection();
// try {
//   await connection.beginTransaction();
//   const mediaType = fileType(newMedia.MIMEType, newMedia.Duration!); // Determine media type
//   if (mediaType === 'Unknown') return;

//   // Camera Type Handling
//   let cameraTypeId: number | null = null;
//   if (newMedia.Make && newMedia.Model) {
//     const [rows] = await connection.execute(Sql.GET_CAMERA_TYPE, [newMedia.Make, newMedia.Model]);
//     cameraTypeId = (rows as any).length === 0 ? await createCameraType(connection, newMedia.Make, newMedia.Model) : (rows as any)[0].camera_id;
//   }

//   const smallestDate = getSmallestDate(newMedia);
//   const thumbPath = createThumbPath(smallestDate);

//   const [result]: [ResultSetHeader, FieldPacket[]] = await connection.execute(Sql.INSERT_MEDIA, [
//     newMedia.FileName,
//     mediaType,
//     newMedia.FileType,
//     newMedia.Software,
//     newMedia.FileSize,
//     cameraTypeId,
//     smallestDate,
//     newMedia.SourceFile,
//     newMedia.MIMEType,
//     thumbPath,
//   ]);
//   const lastMediaInsertedId = result.insertId;

//   // Insert Upload Info
//   await connection.execute(Sql.INSERT_UPLOADBY, [RegisteredUser, lastMediaInsertedId]);

//   if (mediaType === 'Photo') {
//     await connection.execute(Sql.INSERT_PHOTO, [lastMediaInsertedId, newMedia.Orientation, newMedia.ImageWidth, newMedia.ImageHeight, newMedia.Megapixels]);
//   } else if (mediaType === 'Video') {
//     const durationDisplay = convertDuration(newMedia.Duration!);
//     await connection.execute(Sql.INSERT_VIDEO, [lastMediaInsertedId, newMedia.Duration, newMedia.Title, durationDisplay]);
//   } else if (mediaType === 'Live') {
//     await connection.execute(Sql.INSERT_LIVE, [lastMediaInsertedId, newMedia.Duration, newMedia.Title]);
//   }

//   // Insert GPS Data
//   if (newMedia.GPSLatitude && newMedia.GPSLongitude) {
//     await connection.execute(Sql.INSERT_GPS, [lastMediaInsertedId, newMedia.GPSLatitude, newMedia.GPSLongitude]);
//   }

//   await connection.commit();
// } catch (error) {
//   await connection.rollback();
//   console.error('Error processing media:', error);
//   throw error;
// } finally {
//   connection.release();
// }

// const createCameraType = async (connection: PoolConnection, make: string, model: string) => {
//   const [result]: [ResultSetHeader, FieldPacket[]] = await connection.execute(Sql.INSERT_CAMERA, [make, model]);
//   return result.insertId;
// };

// const Sql = {
//   GET_CAMERA_TYPE: `SELECT camera_id FROM CameraType WHERE Make = ? AND Model = ? LIMIT 1`,
//   INSERT_CAMERA: `INSERT INTO CameraType (Make, Model) VALUES (?, ?)`,

//   INSERT_MEDIA: `INSERT INTO Media (FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, SourceFile, MIMEType, ThumbPath) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
//   INSERT_UPLOADBY: `INSERT INTO UploadBy (RegisteredUser, media) VALUES (?, ?)`,

//   INSERT_PHOTO: `INSERT INTO Photo (media, Orientation, ImageWidth, ImageHeight, Megapixels) VALUES (?, ?, ?, ?, ?)`,
//   INSERT_VIDEO: `INSERT INTO Video (media, Duration, Title, DisplayDuration) VALUES (?, ?, ?, ?)`,
//   INSERT_LIVE: `INSERT INTO Live (media, Duration, Title) VALUES (?, ?, ?)`,

//   INSERT_GPS: `INSERT INTO Location (media, GPSLatitude, GPSLongitude) VALUES (?, ?, ?)`,
// };
