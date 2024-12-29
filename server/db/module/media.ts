import { poolPromise } from '..';

// SQL Queries
const Sql = {
  UPDATE: `
    UPDATE Photos.Media 
    SET FileType = ?, FileName = ?, CreateDate = ?, FileSize = ?, HashCode = ?, URL = ?, Privacy = ?, Hidden = ?, FavoriteCount = ?, DeletedStatus = ?, DeletionDate = ?, Restricted = ?, CameraType = ?, FileExt = ?, Software = ?
    WHERE media_id = ?
  `,
  DELETE: `
    DELETE FROM Photos.Media 
    WHERE media_id = ?
  `,
  FETCH_ALL: `
    SELECT * FROM Photos.Media
  `,
  FIND_BY_ID: `
    SELECT * FROM Photos.Media 
    WHERE media_id = ?
  `,
  MARK_HIDDEN: `
    UPDATE Photos.Media 
    SET Hidden = 1 
    WHERE media_id = ?
  `,
  MARK_FAVORITE: `
    UPDATE Photos.Media 
    SET FavoriteCount = FavoriteCount + 1 
    WHERE media_id = ?
  `,
  MARK_DELETED: `
    UPDATE Photos.Media 
    SET DeletedStatus = 1, DeletionDate = CURRENT_TIMESTAMP 
    WHERE media_id = ?
  `,
};

const updateMedia = async (
  media_id: number,
  FileType: 'Photo' | 'Video' | 'Live' | 'Unknown',
  FileName: string | null,
  CreateDate: Date | null,
  FileSize: number | null,
  URL: string | null,
  Privacy: boolean,
  Hidden: boolean,
  Restricted: boolean,
  CameraType: number | null,
  FileExt: string | null,
  Software: string | null
) => {
  await poolPromise.execute(Sql.UPDATE, [
    FileType,
    FileName,
    CreateDate,
    FileSize,
    URL,
    Privacy ? 1 : 0,
    Hidden ? 1 : 0,
    0, // FavoriteCount stays unchanged
    0, // DeletedStatus stays unchanged
    null, // DeletionDate stays unchanged
    Restricted ? 1 : 0,
    CameraType,
    FileExt,
    Software,
    media_id,
  ]);

  return { media_id, FileType, FileName };
};

const deleteMedia = async (media_id: number) => {
  await poolPromise.execute(Sql.DELETE, [media_id]);
  return { message: `Media with ID ${media_id} deleted` };
};

const fetchAllMedia = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_ALL);
  return rows as any[];
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
  return { media_id, hidden: true };
};

const markFavorite = async (media_id: number) => {
  await poolPromise.execute(Sql.MARK_FAVORITE, [media_id]);
  return { media_id, favoriteIncremented: true };
};

const markDeleted = async (media_id: number) => {
  await poolPromise.execute(Sql.MARK_DELETED, [media_id]);
  return { media_id, deleted: true, deletionDate: new Date() };
};

// Export All Functions
export default {
  updateMedia,
  deleteMedia,
  fetchAllMedia,
  findMediaById,
  markHidden,
  markFavorite,
  markDeleted,
};
