import path from 'path';
import type { UUID } from 'crypto';
import { $ } from 'bun';

import { sql } from '..';

// SQL Queries
// const Sql = {
//   // LOAD_IMPORTED_MEDIA: 'SELECT media_id, SourceFile, ThumbPath, FileType, FileName FROM Media WHERE ThumbPath IS NULL OR HashCode IS NULL',
//   // UPDATE_HASH_THUMB: 'UPDATE Media SET HashCode = ?, ThumbWidth = ?, ThumbHeight = ? WHERE media_id = ?',
//   // UPDATE_THUMB: 'UPDATE Media SET ThumbWidth = ?, ThumbHeight = ? WHERE media_id = ?',
//   // UPDATE_HASH: 'UPDATE Media SET HashCode = (?) WHERE media_id = ?',
//   // FETCH_CAMERATYPE: 'SELECT * FROM CameraType',
//   // FETCH_MEDIA_EACH_YEAR: 'CALL GetMediaEachYear()',
//   // FETCH_MEDIA_EACH_MONTH: 'CALL GetMediaByYear(?)',
//   // STREAM_MEDIA: 'CALL StreamSearchMedias(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
//   // FETCH_MEDIA_STATISTICS: 'CALL GetMediaStatistics()',
//   // GET_ALBUMS: 'CALL GetAlbumsAndCount()',
//   // ADD_TO_ALBUMS: 'INSERT IGNORE INTO AlbumMedia (album, media) SELECT (?), media_id FROM Media WHERE media_id IN (?)',
//   // CREATE_ALBUM: 'INSERT INTO Album (RegisteredUser, title) VALUES (?, ?)',
//   // FIND_MEDIA_TO_DEL: 'SELECT media_id, SourceFile, ThumbPath FROM Media WHERE media_id IN (?)',
//   // DELETE_MEDIAS: 'DELETE FROM Media WHERE media_id IN (?)',
//   // MARK_FAVORITES: "UPDATE Media SET Favorite = ? WHERE media_id IN (?)",
//   // MARK_DELETED: "UPDATE Media SET DeletedStatus = 1 WHERE media_id = ?",
//   // LOAD_MEDIA_HASH: "SELECT media_id, SourceFile, ThumbPath, FileType FROM Media WHERE HashCode = ?`,
//   // CREATE_DB: `CREATE DATABASE IF NOT EXISTS Photos`,
// };

export const importedMedias = async () => {
  return await sql`SELECT media_id, source_file, thumb_path, file_type, file_name FROM multi_schema."Media" WHERE thumb_path IS NULL OR hash_code IS NULL`;
};

export const updateHashThumb = async (media_id: number, hashCode: string, thumbWidth: string, thumbHeight: string) => {
  return await sql`UPDATE multi_schema."Media" SET hash_code = ${hashCode}, thumb_width = ${thumbWidth}, thumb_height = ${thumbHeight} WHERE media_id = ${media_id}`;
};

export const fetchCameraType = async () => {
  return await sql`SELECT camera_id, model FROM multi_schema."CameraType" ORDER BY model ASC`;
};

export const updateMedias = async (mediaIds: number[], updateKey: string, updateValue: boolean) => {
  const result = await sql`UPDATE multi_schema."Media" SET ${sql(updateKey)} = ${updateValue} WHERE media_id IN ${sql(mediaIds)}`;
  return result.count === mediaIds.length;
};

export const groupMonthsByYear = async () => {
  return await sql`
  WITH ranked_media AS (
    SELECT media_id, thumb_path, file_type, create_year, create_month, create_date,
          ROW_NUMBER() OVER (
            PARTITION BY create_year, create_month
            ORDER BY create_date ) AS rn
      FROM multi_schema."Media" as md
      WHERE hidden = FALSE AND deleted = FALSE
  )
  SELECT * FROM ranked_media
  WHERE rn = 1
  ORDER BY create_year DESC, create_month DESC`;
};

export const deleteMedias = async (mediaIds: number[]) => {
  try {
    const mediaDeleted = await sql.begin(async (tx) => {
      const deletePaths = await tx`SELECT media_id, source_file, thumb_path FROM "multi_schema"."Media" WHERE media_id IN ${sql(mediaIds)}`;
      const result = await tx`DELETE FROM "multi_schema"."Media" WHERE media_id IN ${sql(mediaIds)} RETURNING media_id`;

      deletePaths.forEach(async (each: any) => {
        const thumbPath = path.join(Bun.env.MAIN_PATH, each.thumb_path);
        const sourcePath = path.join(Bun.env.MAIN_PATH, each.source_file);

        const { stderr, exitCode } = await $`rm ${thumbPath} ${sourcePath}`;
        if (exitCode !== 0) console.warn(stderr); // Save result in error table
      });

      return result;
    });

    return mediaDeleted.length === mediaIds.length;
  } catch (error) {
    console.error('deleteMedias', error);
  }
};

/**--------------- ///// ALBUM SECTION ///// ---------------*/
export const createAlbum = async (regUserId: UUID, albumTitle: string) => {
  const [albumId] = await sql`INSERT INTO "multi_schema"."Album" ("RegisteredUser", title) VALUES (${regUserId}, ${albumTitle}) RETURNING album_id`;
  return albumId.album_id; // Return album id
};

/** Fetch all Albums incluing album without any Media with one image created */
export const fetchAlbums = async () => {
  const rows = await sql`
    SELECT al.album_id, al.title as title, COUNT(am.media) AS media_count, MIN(md.thumb_path) as thumb_path
    FROM multi_schema."Album" al
    LEFT JOIN multi_schema."AlbumMedia" am ON am.album = al.album_id
    LEFT JOIN multi_schema."Media" md ON am.media = md.media_id
    WHERE md.deleted = FALSE AND md.hidden = FALSE
    GROUP BY al.album_id
    ORDER BY al.title ASC`;
  return rows;
};

export const fetchAddToAlbum = async (mediaIds: number[], albumId: number) => {
  try {
    const insertIds = mediaIds.map((id) => ({
      album: albumId,
      media: id,
    }));
    return await sql`INSERT INTO "multi_schema"."AlbumMedia" ${sql(insertIds)} ON CONFLICT DO NOTHING`;
  } catch (error) {
    console.error('fetchAddToAlbum ', error);
  }
};

export const fetchRemoveFromAlbum = async (mediaIds: number[], albumId: number) => {
  try {
    return await sql`DELETE FROM "multi_schema"."AlbumMedia" WHERE album = ${albumId} AND media IN ${sql(mediaIds)}`;
  } catch (error) {
    console.error('fetchRemoveFromAlbum ', error);
  }
};

export const fetchMediaCount = async () => {
  // TODO need to implement count duplicate
  const mediaCount = sql`
    SELECT 
        SUM(CASE WHEN "favorite" = TRUE AND "hidden" = FALSE AND "deleted" = FALSE THEN 1 ELSE 0 END) AS "Favorite",
        SUM(CASE WHEN "hidden" = TRUE AND "deleted" = FALSE THEN 1 ELSE 0 END) AS "Hidden",
        SUM(CASE WHEN "deleted" = TRUE THEN 1 ELSE 0 END) AS "Recently Deleted",
        SUM(CASE WHEN "create_date" IS NOT NULL THEN 1 ELSE 0 END) AS "Duplicate"
    FROM "multi_schema"."Media"`;

  return mediaCount;
};

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

// export const fetchMedias = async ({
//   year,
//   month,
//   offset,
//   limit,
//   device = null,
//   type = null,
//   sortKey = null,
//   sortOrder = null,

//   favorite = null,
//   hidden = null,
//   deleted = null,
//   duplicate = null,

//   albumId = null,
// }: StreamMediasParams) => {
//   const params = [month, year, offset, limit, device, type, sortKey, sortOrder, favorite, hidden, deleted, duplicate, albumId];
//   console.log(params.filter((item) => item !== null));
//   // const [rows] = await poolPromise.execute(Sql.STREAM_MEDIA, params);
//   // return (rows as any)[0];
//   const medias = await sql`SELECT * FROM multi_schema."Media"`;
//   return medias;
// };
