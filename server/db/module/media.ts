import { pool, poolPromise } from '..';

// SQL Queries
const Sql = {
  LOAD_MEDIA_THUMB: `SELECT media_id, SourceFile, ThumbPath, FileType, isThumbCreated FROM Media WHERE isThumbCreated = ?`,
  UPDATE_THUMB: `UPDATE Media SET isThumbCreated = 1 WHERE media_id = ?`,
  LOAD_MEDIA_HASH: `SELECT media_id, SourceFile, ThumbPath, FileType FROM Media WHERE HashCode = ?`,
  UPDATE_HASH: `UPDATE Media SET HashCode = ? WHERE media_id = ?`,
  DELETE: `DELETE FROM Media WHERE media_id = ?`,
  FETCH_ALL: `SELECT * FROM PhotoView ORDER BY media_id ASC LIMIT ?, ?`,
  FIND_BY_ID: `SELECT * FROM Media WHERE media_id = ?`,
  MARK_HIDDEN: `UPDATE Media SET Hidden = 1 WHERE media_id = ?`,
  MARK_FAVORITE: `UPDATE Media SET Favorite = 1 WHERE media_id = ?`,
  MARK_DELETED: `UPDATE Media SET DeletedStatus = 1, DeletionDate = CURRENT_TIMESTAMP WHERE media_id = ?`,
  DELETE_IMPORT_TB: `DELETE FROM ImportMedias`,
  SEARCH_MEDIA: `SELECT * FROM Media WHERE FileType = ?`,
};

const mediaWoThumb = async (isNotCreated: number = 0) => {
  const [rows] = await poolPromise.execute(Sql.LOAD_MEDIA_THUMB, [isNotCreated]);
  return rows as any;
};

const deleteImportMedia = async () => {
  await poolPromise.execute(Sql.DELETE_IMPORT_TB);
};

const updateThumb = async (media_id: number) => {
  await poolPromise.execute(Sql.UPDATE_THUMB, [media_id]);
  return { media_id };
};

const updateHash = async (media_id: number, HashCode: string | null) => {
  await poolPromise.execute(Sql.UPDATE_HASH, [media_id, HashCode]);
  return { media_id, HashCode };
};

const deleteMedia = async (media_id: number) => {
  await poolPromise.execute(Sql.DELETE, [media_id]);
  return { message: `Media with ID ${media_id} deleted` };
};

const fetchAllMedia = (offset: number, limit: number) => {
  return pool.query(Sql.FETCH_ALL, [offset, limit]).stream();
};

const findMediaById = async (media_id: number) => {
  const [rows] = await poolPromise.execute(Sql.FIND_BY_ID, [media_id]);
  if ((rows as any).length === 0) {
    throw new Error('Media not found');
  }
  return (rows as any)[0];
};

const markHidden = async (media_id: number) => {
  await poolPromise.execute(Sql.MARK_HIDDEN, [media_id]);
  return { media_id };
};

const markFavorite = async (media_id: number) => {
  await poolPromise.execute(Sql.MARK_FAVORITE, [media_id]);
  return { media_id };
};

const markDeleted = async (media_id: number) => {
  await poolPromise.execute(Sql.MARK_DELETED, [media_id]);
  return { media_id };
};

// Export All Functions
export { updateHash, deleteMedia, deleteImportMedia, fetchAllMedia, findMediaById, markHidden, markFavorite, markDeleted, mediaWoThumb, updateThumb };
