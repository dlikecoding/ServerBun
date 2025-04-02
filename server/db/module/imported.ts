import { poolPromise } from '..';
import type { FieldPacket, PoolConnection, ResultSetHeader } from 'mysql2/promise';
import type { UUID } from 'crypto';

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

const Sql = {
  GET_CAMERA_TYPE: `SELECT camera_id FROM CameraType WHERE Make = ? AND Model = ? LIMIT 1`,
  INSERT_CAMERA: `INSERT INTO CameraType (Make, Model) VALUES (?, ?)`,

  INSERT_MEDIA: `INSERT INTO Media (FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, SourceFile, MIMEType, ThumbPath) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  INSERT_UPLOADBY: `INSERT INTO UploadBy (RegisteredUser, media) VALUES (?, ?)`,

  INSERT_PHOTO: `INSERT INTO Photo (media, Orientation, ImageWidth, ImageHeight, Megapixels) VALUES (?, ?, ?, ?, ?)`,
  INSERT_VIDEO: `INSERT INTO Video (media, Duration, Title, DisplayDuration) VALUES (?, ?, ?, ?)`,
  INSERT_LIVE: `INSERT INTO Live (media, Duration, Title) VALUES (?, ?, ?)`,

  INSERT_GPS: `INSERT INTO Location (media, GPSLatitude, GPSLongitude) VALUES (?, ?, ?)`,
};

export const handleMediaInsert = async (newMedia: ImportMedia, RegisteredUser: UUID) => {
  const connection = await poolPromise.getConnection();
  try {
    await connection.beginTransaction();
    const mediaType = fileType(newMedia.MIMEType, newMedia.Duration!); // Determine media type
    if (mediaType === 'Unknown') return;

    // Camera Type Handling
    let cameraTypeId: number | null = null;
    if (newMedia.Make && newMedia.Model) {
      const [rows] = await connection.execute(Sql.GET_CAMERA_TYPE, [newMedia.Make, newMedia.Model]);
      cameraTypeId = (rows as any).length === 0 ? await createCameraType(connection, newMedia.Make, newMedia.Model) : (rows as any)[0].camera_id;
    }

    const smallestDate = getSmallestDate(newMedia);
    const thumbPath = createThumbPath(smallestDate);

    const [result]: [ResultSetHeader, FieldPacket[]] = await connection.execute(Sql.INSERT_MEDIA, [
      newMedia.FileName,
      mediaType,
      newMedia.FileType,
      newMedia.Software,
      newMedia.FileSize,
      cameraTypeId,
      smallestDate,
      newMedia.SourceFile,
      newMedia.MIMEType,
      thumbPath,
    ]);
    const lastMediaInsertedId = result.insertId;

    // Insert Upload Info
    await connection.execute(Sql.INSERT_UPLOADBY, [RegisteredUser, lastMediaInsertedId]);

    if (mediaType === 'Photo') {
      await connection.execute(Sql.INSERT_PHOTO, [lastMediaInsertedId, newMedia.Orientation, newMedia.ImageWidth, newMedia.ImageHeight, newMedia.Megapixels]);
    } else if (mediaType === 'Video') {
      const durationDisplay = convertDuration(newMedia.Duration!);
      await connection.execute(Sql.INSERT_VIDEO, [lastMediaInsertedId, newMedia.Duration, newMedia.Title, durationDisplay]);
    } else if (mediaType === 'Live') {
      await connection.execute(Sql.INSERT_LIVE, [lastMediaInsertedId, newMedia.Duration, newMedia.Title]);
    }

    // Insert GPS Data
    if (newMedia.GPSLatitude && newMedia.GPSLongitude) {
      await connection.execute(Sql.INSERT_GPS, [lastMediaInsertedId, newMedia.GPSLatitude, newMedia.GPSLongitude]);
    }

    await connection.commit();
  } catch (error) {
    await connection.rollback();
    console.error('Error processing media:', error);
    throw error;
  } finally {
    connection.release();
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

const createCameraType = async (connection: PoolConnection, make: string, model: string) => {
  const [result]: [ResultSetHeader, FieldPacket[]] = await connection.execute(Sql.INSERT_CAMERA, [make, model]);
  return result.insertId;
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

  // duration >= 3600 ? `${Math.floor(duration / 3600)}:${String(Math.floor((duration / 60) % 60)).padStart(2, '0')}:${String(Math.round(duration % 60)).padStart(2, '0')}`
  // : duration >= 60 ? `${Math.floor(duration / 60)}:${String(Math.round(duration % 60)).padStart(2, '0')}`
  // : `0:${String(Math.round(duration % 60)).padStart(2, '0')}`;
};
