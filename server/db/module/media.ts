import path from 'path';
import type { UUID } from 'crypto';
import { $ } from 'bun';

import { sql } from '..';
import { insertErrorLog } from './system';
import type { UpdateCaption } from '../../service/generators/caption';

export const importedMediasThumbHash = async () => {
  return await sql`
    SELECT media_id, source_file, thumb_path, file_type, selected_frame, duration 
    FROM multi_schema."Media" 
    WHERE thumb_created = FALSE OR hash_code IS NULL
    ORDER BY media_id`;
};

export const rescanThumbnail = async () => {
  return await sql`
    SELECT media_id, source_file, thumb_path, file_type, selected_frame, duration 
    FROM multi_schema."Media"
    ORDER BY media_id`;
};

export const importedMediasCaption = async () => {
  return await sql`
    SELECT media_id, thumb_path FROM multi_schema."Media"
    WHERE caption IS NULL OR caption = '' ORDER BY media_id`;
};

export const importedMediasLocation = async () => {
  return await sql`
    SELECT media_id, gps_latitude, gps_longitude 
    FROM multi_schema."Media" md
    LEFT JOIN multi_schema."LocationMedia" lm ON md.media_id = lm.media
    WHERE lm.media IS NULL AND md.gps_latitude IS NOT NULL
    ORDER BY media_id`;
};

export const updateHashThumb = async (media_id: number, hashCode: string) => {
  return await sql.begin(async (tx) => {
    const [dupMedia] = await tx`
      SELECT media_id, hash_code 
      FROM multi_schema."Media" 
      WHERE hash_code = ${hashCode} AND media_id <> ${media_id} LIMIT 1`;

    if (dupMedia) {
      const insertDups = [
        { media: dupMedia.media_id, hash_code: dupMedia.hash_code },
        { media: media_id, hash_code: hashCode },
      ];
      await tx`
          INSERT INTO "multi_schema"."Duplicate" ${sql(insertDups)} 
          ON CONFLICT DO NOTHING`;
    }
    return await tx`
      UPDATE multi_schema."Media" SET hash_code = ${hashCode}, thumb_created = TRUE 
      WHERE media_id = ${media_id}`;
  });
};

export const fetchCameraType = async () => {
  return await sql`
    SELECT camera_id, model FROM multi_schema."CameraType" 
    ORDER BY model ASC`;
};

export const updateMedias = async (mediaIds: number[], updateKey: string, updateValue: boolean) => {
  const result = await sql`
    UPDATE multi_schema."Media" SET ${sql(updateKey)} = ${updateValue} 
    WHERE media_id IN ${sql(mediaIds)}`;
  return result.count === mediaIds.length;
};

export const updateMediaCaption = async (media: UpdateCaption) => {
  return await sql`
    UPDATE multi_schema."Media" SET caption = ${media.caption} 
    WHERE media_id = ${media.media_id}`;
};

export const updateSelectFrameLivePhoto = async (mediaId: number, framePos: string) => {
  return await sql`
    UPDATE multi_schema."Media" SET selected_frame = ${framePos} 
    WHERE media_id = ${mediaId}`;
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
      const deletePaths = await tx`
        SELECT media_id, source_file, thumb_path FROM "multi_schema"."Media" 
        WHERE media_id IN ${sql(mediaIds)}`;

      const result = await tx`
        DELETE FROM "multi_schema"."Media" 
        WHERE media_id IN ${sql(mediaIds)} 
        RETURNING media_id`;

      const countDelted = await deleteHelper(deletePaths);
      return result.length === countDelted ? countDelted : 0;
    });

    return mediaDeleted === mediaIds.length;
  } catch (error) {
    await insertErrorLog('db/module/media.ts', 'deleteMedias', error);
    console.error('deleteMedias', error);
  }
};

export const deleteAllInRecently = async () => {
  try {
    const mediaDeleted = await sql.begin(async (tx) => {
      const deletePaths = await tx`
        SELECT media_id, source_file, thumb_path FROM "multi_schema"."Media" 
        WHERE deleted = TRUE`;

      const result = await tx`
        DELETE FROM "multi_schema"."Media" 
        WHERE deleted = TRUE RETURNING media_id`;

      const countDelted = await deleteHelper(deletePaths);
      return result.length === countDelted;
    });

    return mediaDeleted;
  } catch (error) {
    await insertErrorLog('db/module/media.ts', 'deleteMedias', error);
    console.error('deleteMedias', error);
  }
};

const deleteHelper = async (deletePaths: { media_id: number; source_file: string; thumb_path: string }[]) => {
  let count = 0;

  for (const each of deletePaths) {
    const thumbPath = path.join(Bun.env.MAIN_PATH, each.thumb_path);
    const sourcePath = path.join(Bun.env.MAIN_PATH, each.source_file);

    const { stderr, exitCode } = await $`rm ${thumbPath} ${sourcePath}`;
    exitCode === 0 ? ++count : console.warn(stderr); // Save result in error table
  }
  return count;
};

/**--------------- ///// ALBUM SECTION ///// ---------------*/
export const createAlbum = async (regUserId: UUID, albumTitle: string) => {
  const [albumId] = await sql`
    INSERT INTO "multi_schema"."Album" ("RegisteredUser", title) 
    VALUES (${regUserId}, ${albumTitle}) RETURNING album_id`;
  return albumId.album_id; // Return album id
};

/** Fetch all Albums incluing album without any Media with one image created */
export const fetchAlbums = async () => {
  return await sql`
    SELECT al.album_id, al.title as title, COUNT(am.media) AS media_count, MIN(md.thumb_path) as thumb_path
    FROM multi_schema."Album" al
    LEFT JOIN multi_schema."AlbumMedia" am ON am.album = al.album_id
    LEFT JOIN multi_schema."Media" md ON am.media = md.media_id
    WHERE md.deleted = FALSE AND md.hidden = FALSE
    GROUP BY al.album_id
    ORDER BY al.title ASC`;
};

export const fetchLocations = async () => {
  return await sql`
    SELECT loc.location_id, loc.city, loc.country, COUNT(lm.media) AS media_count, MIN(md.thumb_path) as thumb_path
    FROM multi_schema."Location" loc
    LEFT JOIN multi_schema."LocationMedia" lm ON loc.location_id = lm.location
    LEFT JOIN multi_schema."Media" md ON lm.media = md.media_id
    WHERE md.deleted = FALSE AND md.hidden = FALSE
    GROUP BY loc.location_id
    ORDER BY loc.location_id ASC`;
};

export const fetchAddToAlbum = async (mediaIds: number[], albumId: number) => {
  const insertIds = mediaIds.map((id) => ({
    album: albumId,
    media: id,
  }));
  return await sql`
    INSERT INTO "multi_schema"."AlbumMedia" ${sql(insertIds)} 
    ON CONFLICT DO NOTHING`;
};

export const fetchRemoveFromAlbum = async (mediaIds: number[], albumId: number) => {
  return await sql`
    DELETE FROM "multi_schema"."AlbumMedia" 
    WHERE album = ${albumId} AND media IN ${sql(mediaIds)}`;
};

export const fetchMediaCount = async () => {
  const mediaCount = await sql`
    SELECT 
      SUM(CASE WHEN "favorite" = TRUE AND "hidden" = FALSE AND "deleted" = FALSE THEN 1 ELSE 0 END) AS "Favorite",
      SUM(CASE WHEN "hidden" = TRUE AND "deleted" = FALSE THEN 1 ELSE 0 END) AS "Hidden",
      ( SELECT COUNT("media") FROM "multi_schema"."Duplicate") AS "Duplicate",
      SUM(CASE WHEN "deleted" = TRUE THEN 1 ELSE 0 END) AS "Recently Deleted"
    FROM "multi_schema"."Media"`;
  return mediaCount;
};

export const sumSizeMediaType = async () => {
  const [mediaCount] = await sql`
    SELECT
        COALESCE(SUM(file_size) FILTER (WHERE file_type = 'Photo'), 0)::BIGINT AS "photo",
        COALESCE(SUM(file_size) FILTER (WHERE file_type = 'Live'), 0)::BIGINT AS "live",
        COALESCE(SUM(file_size) FILTER (WHERE file_type = 'Video'), 0)::BIGINT AS "video",
        SUM(file_size)::BIGINT AS "all"
    FROM "multi_schema"."Media"`;
  return mediaCount;
};

export const getSourceFiles = async (mediaIds: number[]) => {
  return await sql`
    SELECT source_file FROM "multi_schema"."Media" 
    WHERE media_id IN ${sql(mediaIds)}`;
};

export const mergeMedias = async () => {
  return await sql`
    SELECT media FROM (
      SELECT dp.media, dp.hash_code, md.file_size, 
      ROW_NUMBER() OVER (PARTITION BY dp.hash_code ORDER BY md.file_size DESC, dp.media ASC) rn
      FROM multi_schema."Duplicate" dp
      LEFT JOIN multi_schema."Media" md ON md.media_id = dp.media
    ) ranked
    WHERE rn > 1`.values();
};
