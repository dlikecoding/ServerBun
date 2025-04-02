import type { FieldPacket, ResultSetHeader, RowDataPacket } from 'mysql2/promise';
import { poolPromise } from '..';
import type { StreamMediasParams } from '../../routes/stream';
import path from 'path';
import { $ } from 'bun';
import type { UUID } from 'crypto';

export interface Media {
  media_id: number;
  FileType: 'Video' | 'Live' | 'Photo';
  FileName: string;
  FileSize: number;
  CreateDate: Date;
  ThumbPath: string;
  SourceFile: string;
  isFavorite: number;
  timeFormat: string;
  duration: string;
  videoTitle: string;

  affectedRows?: any;
}

// SQL Queries
const Sql = {
  LOAD_IMPORTED_MEDIA: 'SELECT media_id, SourceFile, ThumbPath, FileType, FileName FROM Media WHERE ThumbPath IS NULL OR HashCode IS NULL',
  UPDATE_HASH_THUMB: 'UPDATE Media SET HashCode = ?, ThumbWidth = ?, ThumbHeight = ? WHERE media_id = ?',

  // UPDATE_THUMB: 'UPDATE Media SET ThumbWidth = ?, ThumbHeight = ? WHERE media_id = ?',
  // UPDATE_HASH: 'UPDATE Media SET HashCode = (?) WHERE media_id = ?',

  FETCH_CAMERATYPE: 'SELECT * FROM CameraType',

  FETCH_MEDIA_EACH_YEAR: 'CALL GetMediaEachYear()',
  FETCH_MEDIA_EACH_MONTH: 'CALL GetMediaByYear(?)',

  STREAM_MEDIA: 'CALL StreamSearchMedias(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',

  FETCH_MEDIA_STATISTICS: 'CALL GetMediaStatistics()',
  GET_ALBUMS: 'CALL GetAlbumsAndCount()',
  ADD_TO_ALBUMS: 'INSERT IGNORE INTO AlbumMedia (album, media) SELECT (?), media_id FROM Media WHERE media_id IN (?)',
  CREATE_ALBUM: 'INSERT INTO Album (RegisteredUser, title) VALUES (?, ?)',

  FIND_MEDIA_TO_DEL: 'SELECT media_id, SourceFile, ThumbPath FROM Media WHERE media_id IN (?)',
  DELETE_MEDIAS: 'DELETE FROM Media WHERE media_id IN (?)',

  // MARK_FAVORITES: "UPDATE Media SET Favorite = ? WHERE media_id IN (?)",
  // MARK_DELETED: "UPDATE Media SET DeletedStatus = 1 WHERE media_id = ?",
  // LOAD_MEDIA_HASH: "SELECT media_id, SourceFile, ThumbPath, FileType FROM Media WHERE HashCode = ?`,
  // CREATE_DB: `CREATE DATABASE IF NOT EXISTS Photos`,
};

export const importedMedias = async () => {
  const [rows] = await poolPromise.execute(Sql.LOAD_IMPORTED_MEDIA);
  return rows as any;
};

export const updateHashThumb = async (media_id: number, hashCode: string, thumbWidth: string, thumbHeight: string) => {
  await poolPromise.execute(Sql.UPDATE_HASH_THUMB, [hashCode, thumbWidth, thumbHeight, media_id]);
  return { media_id };
};

// export const updateThumb = async (media_id: number, thumbWidth: string, thumbHeight: string) => {
//   await poolPromise.execute(Sql.UPDATE_THUMB, [thumbWidth, thumbHeight, media_id]);
//   return { media_id };
// };

// export const updateHash = async (media_id: number, HashCode: string) => {
//   await poolPromise.execute(Sql.UPDATE_HASH, [HashCode, media_id]);
//   return { media_id, HashCode };
// };

export const updateMedias = async (mediaIds: number[], updateKey: string, updateValue: boolean) => {
  const connection = await poolPromise.getConnection();
  try {
    await connection.beginTransaction();
    const result: [ResultSetHeader, FieldPacket[]] = await connection.query(`UPDATE Media SET ${updateKey} = ? WHERE media_id IN (?)`, [updateValue, mediaIds]);
    await connection.commit();

    return result[0].affectedRows === mediaIds.length;
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

export const fetchMedias = async ({
  year,
  month,
  offset,
  limit,
  device = null,
  type = null,
  sortKey = null,
  sortOrder = null,

  favorite = null,
  hidden = null,
  deleted = null,
  duplicate = null,

  albumId = null,
}: StreamMediasParams) => {
  const params = [month, year, offset, limit, device, type, sortKey, sortOrder, favorite, hidden, deleted, duplicate, albumId];
  const [rows] = await poolPromise.execute(Sql.STREAM_MEDIA, params);
  return (rows as any)[0];
};

export const fetchMediaEachYear = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_MEDIA_EACH_YEAR);
  if ((rows as any).length === 0) {
    throw new Error('Media not found');
  }
  return (rows as any)[0];
};

export const fetchMediaOfEachMonth = async (yearNum?: number) => {
  const [rows] = await poolPromise.execute(Sql.FETCH_MEDIA_EACH_MONTH, [yearNum]);
  if ((rows as any).length === 0) {
    throw new Error('Media not found');
  }
  return (rows as any)[0];
};

export const fetchMediaCount = async () => {
  const sql = Sql.FETCH_MEDIA_STATISTICS;
  const [rows] = await poolPromise.execute({ sql });
  if ((rows as any).length === 0) {
    throw new Error('Media not found');
  }
  return (rows as any)[0];
};

export const fetchCameraType = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_CAMERATYPE);
  return rows;
};

export const fetchAlbums = async () => {
  const [rows] = await poolPromise.execute(Sql.GET_ALBUMS);
  return (rows as any)[0];
};

export const createAlbum = async (regUserId: UUID, albumTitle: string) => {
  const [result]: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.CREATE_ALBUM, [regUserId, albumTitle]);
  return result.insertId;
};

export const fetchAddToAlbum = async (mediaIds: number[], albumId: number) => {
  const connection = await poolPromise.getConnection();
  try {
    await connection.beginTransaction();
    const [result]: [ResultSetHeader, FieldPacket[]] = await poolPromise.query(Sql.ADD_TO_ALBUMS, [albumId, mediaIds]);
    await connection.commit();
    return result.affectedRows === mediaIds.length;
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('[transactionalUpdate] Error:', error);
    return false;
  } finally {
    if (connection) connection.release();
  }
};

export const deleteMedias = async (mediaIds: number[]) => {
  const connection = await poolPromise.getConnection();

  try {
    await connection.beginTransaction();

    const foundPaths: [RowDataPacket[], FieldPacket[]] = await connection.query(Sql.FIND_MEDIA_TO_DEL, [mediaIds]);
    const result: [ResultSetHeader, FieldPacket[]] = await connection.query(Sql.DELETE_MEDIAS, [mediaIds]);

    foundPaths[0].forEach(async (each: any, _index) => {
      const thumbPath = path.join(Bun.env.MAIN_PATH, each.ThumbPath);
      const sourcePath = path.join(Bun.env.MAIN_PATH, each.SourceFile);

      const { stderr, exitCode } = await $`rm ${thumbPath} ${sourcePath}`;
      if (exitCode !== 0) return console.warn(stderr); // Save result in error table
    });

    await connection.commit();

    return result[0].affectedRows === mediaIds.length;
  } catch (error) {
    if (connection) await connection.rollback();
  } finally {
    if (connection) connection.release();
  }
};

// Export All Functions
// export { updateHash, deleteMedia, deleteImportMedia, streamMedias, findMediaById, markHidden, markFavorite, markDeleted, mediaWoThumb, updateThumb, fetchMediaEachYear };

/////////////////////////////////////////////////

// export const findMediaById = async (media_id: number) => {
//   const [rows] = await poolPromise.execute(Sql.FIND_BY_ID, [media_id]);
//   if ((rows as any).length === 0) {
//     throw new Error('Media not found');
//   }
//   return (rows as any)[0];
// };

// export const streamMedias = ({ year, month, offset, limit, device = undefined, type = undefined, sortKey = undefined, sortOrder = undefined }: StreamMediasParams) => {
//   // Prepare SQL query with parameters
//   const params = [month, year, offset, limit, device, type, sortKey, sortOrder];
//   return pool.query(Sql.STREAM_MEDIA, params).stream();
// };
///////////////////////////////////////////////
// export const markHidden = async (media_id: number) => {
//   await poolPromise.execute(Sql.MARK_HIDDEN, [media_id]);
//   return { media_id };
// };
