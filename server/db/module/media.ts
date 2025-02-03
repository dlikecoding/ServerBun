import type { FieldPacket, ResultSetHeader } from 'mysql2/promise';
import { poolPromise } from '..';
import type { StreamMediasParams } from '../../routes/stream';

// SQL Queries
const Sql = {
  LOAD_IMPORTED_MEDIA: `SELECT md.media_id, md.SourceFile, md.ThumbPath, md.FileType FROM ImportMedias im LEFT JOIN Media md ON im.import_id = md.media_id`,
  UPDATE_THUMB: `UPDATE Media SET ThumbWidth = ?, ThumbHeight = ? WHERE media_id = ?`,
  UPDATE_HASH: `UPDATE Media SET HashCode = (?) WHERE media_id = ?`,
  DELETE: `DELETE FROM Media WHERE media_id = ?`,
  DELETE_IMPORT_TB: `DELETE FROM ImportMedias`,
  FETCH_ALL: `SELECT * FROM PhotoView ORDER BY media_id ASC`,
  FETCH_CAMERATYPE: `SELECT * FROM CameraType`,
  FETCH_MEDIA_EACH_YEAR: `CALL GetMediaEachYear()`,
  FETCH_MEDIA_EACH_MONTH: `CALL GetMediaByYear(?)`,
  FETCH_MEDIA_STATISTICS: `CALL GetMediaStatistics()`,
  STREAM_MEDIA: `CALL StreamSearchMedias(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,

  // SEARCH_MEDIA: `SELECT * FROM Media WHERE FileType = ?`,
  // FIND_BY_ID: `SELECT * FROM Media WHERE media_id = ?`,
  // MARK_HIDDEN: `UPDATE Media SET Hidden = 1 WHERE media_id = ?`,
  // MARK_FAVORITES: `UPDATE Media SET Favorite = ? WHERE media_id IN (?)`,
  // MARK_DELETED: `UPDATE Media SET DeletedStatus = 1 WHERE media_id = ?`,
  // LOAD_MEDIA_HASH: `SELECT media_id, SourceFile, ThumbPath, FileType FROM Media WHERE HashCode = ?`,
  // CREATE_DB: `CREATE DATABASE IF NOT EXISTS Photos`,
};

export const importedMedias = async () => {
  const [rows] = await poolPromise.execute(Sql.LOAD_IMPORTED_MEDIA);
  return rows as any;
};

export const updateThumb = async (media_id: number, thumbWidth: string, thumbHeight: string) => {
  await poolPromise.execute(Sql.UPDATE_THUMB, [thumbWidth, thumbHeight, media_id]);
  return { media_id };
};

export const updateHash = async (media_id: number, HashCode: string) => {
  await poolPromise.execute(Sql.UPDATE_HASH, [HashCode, media_id]);
  return { media_id, HashCode };
};

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

export const deleteMedia = async (media_id: number) => {
  await poolPromise.execute(Sql.DELETE, [media_id]);
  return { message: `Media with ID ${media_id} deleted` };
};

export const deleteImportMedia = async () => {
  await poolPromise.execute(Sql.DELETE_IMPORT_TB);
};

export const fetchMedias = async ({ year, month, offset, limit, device = null, type = null, sortKey = null, sortOrder = null, deleted = null, hidden = null, favorite = null }: StreamMediasParams) => {
  const params = [month, year, offset, limit, device, type, sortKey, sortOrder, deleted, hidden, favorite];
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

// export const markDeleted = async (media_id: number) => {
//   await poolPromise.execute(Sql.MARK_DELETED, [media_id]);
//   return { media_id };
// };

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
