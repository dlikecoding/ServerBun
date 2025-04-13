-- ====================================================================================
-- Trigger function to automaticly delete album when media is deleted in Media table
CREATE OR REPLACE FUNCTION multi_schema.auto_delete_album_if_empty()
RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "multi_schema"."AlbumMedia"
        WHERE "album" = OLD."album"
    ) THEN 
        DELETE FROM "multi_schema"."Album"
        WHERE "album_id" = OLD."album";
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER delete_empty_album_after_delete_media
AFTER DELETE ON multi_schema."AlbumMedia"
FOR EACH ROW
EXECUTE FUNCTION "multi_schema".auto_delete_album_if_empty();

-- =========================== END ===================================================




-- -- ====================================================================================
-- -- Trigger function to update DeletionDate in Media table when Deleted changes
-- DROP FUNCTION IF EXISTS media_before_update() CASCADE;

-- CREATE FUNCTION media_before_update()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     -- Set DeletionDate to CURRENT_TIMESTAMP if Deleted changes to 1, otherwise set to NULL
--     IF OLD.Deleted IS DISTINCT FROM NEW.Deleted THEN
--         IF NEW.Deleted = 1 THEN
--             NEW.DeletionDate := CURRENT_TIMESTAMP;
--         ELSE
--             NEW.DeletionDate := NULL;
--         END IF;

--         IF NEW.Favorite = 1 THEN
--             NEW.Favorite := 0;
--         END IF;
--     END IF;

--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Create the trigger
-- DROP TRIGGER IF EXISTS media_before_update_trigger ON "Media";

-- CREATE TRIGGER media_before_update_trigger
-- BEFORE UPDATE ON "Media"
-- FOR EACH ROW
-- EXECUTE FUNCTION media_before_update();




-- Assign a ranked class name to each media item based on classification.
CREATE OR REPLACE VIEW "PhotoView" AS
  SELECT 
    im.media_id,
    im.file_type AS "FileType",
    im.file_name AS "FileName",
    im.file_size AS "FileSize",
    im.create_date AS "CreateDate",
    im.upload_at AS "UploadAt",
    im.thumb_path AS "ThumbPath",
    im.source_file AS "SourceFile",
    im.favorite AS "isFavorite",
    im.hidden AS "isHidden",
    im.deleted AS "isDeleted",
    im.camera_type AS "CameraType",
    im.hash_code AS "HashCode",
    to_char(im.create_date, 'Mon DD, YYYY'::text) AS "TimeFormat",
    v.display_duration AS "Duration",
    v.title AS "VideoTitle",
    im.mime_type as "MIMEType"
  FROM "Media" im
  LEFT JOIN "Video" v ON im.media_id = v.media;


-- ====================================================================================
/*
   Stored Procedure: GetAlbumsAndCount
   - Aggregates total Albums, and count all medias for each album.
   - Does not count Deleted and Hidden medias.
   - Returns results as a single query output.
*/

CREATE OR REPLACE FUNCTION "GetAlbumsAndCount"()
RETURNS TABLE (
    album_id INTEGER,
    title TEXT,
    media_id INTEGER,
    "ThumbPath" TEXT,
    media_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ab.album_id,
        ab.title,
        md.media_id,
        md."ThumbPath",
        (
            SELECT COUNT(*) 
            FROM "AlbumMedia" am_count 
            LEFT JOIN "Media" md2 ON md2.media_id = am_count.media
            WHERE am_count.album = ab.album_id 
              AND md2."Hidden" = 0 
              AND md2."Deleted" = 0
        ) AS media_count
    FROM "Album" ab
    LEFT JOIN "AlbumMedia" am ON am.album = ab.album_id
    LEFT JOIN "Media" md ON md.media_id = am.media
    WHERE md.media_id = (
        SELECT m2.media_id 
        FROM "AlbumMedia" am2 
        JOIN "Media" m2 ON m2.media_id = am2.media
        WHERE am2.album = ab.album_id 
          AND m2."Hidden" = 0 
          AND m2."Deleted" = 0
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;


-- ====================================================================================
/*
   Stored Procedure: GetMediaStatistics
   - Aggregates total favorites, deleted status, and hidden media.
   - Counts duplicate entries based on HashCode.
   - Uses a CTE for efficient duplicate detection.
   - Returns results as a single query output.
*/

DROP FUNCTION IF EXISTS "GetMediaStatistics"();

CREATE OR REPLACE FUNCTION "GetMediaStatistics"()
RETURNS TABLE (
    "Favorite" INTEGER,
    "Duplicate" INTEGER,
    "Hidden" INTEGER,
    "Recently Deleted" INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH countData AS (
        SELECT COUNT(media_id) AS countDup
        FROM "Media"
        WHERE "HashCode" IS NOT NULL AND "Hidden" = 0 AND "Deleted" = 0
        GROUP BY "HashCode"
        HAVING COUNT(media_id) > 1
    )
    SELECT
        SUM(CASE WHEN "Favorite" = 1 AND "Hidden" = 0 AND "Deleted" = 0 THEN 1 ELSE 0 END) AS "Favorite",
        COALESCE((SELECT SUM(countDup) FROM countData), 0) AS "Duplicate",
        SUM(CASE WHEN "Hidden" = 1 AND "Deleted" = 0 THEN 1 ELSE 0 END) AS "Hidden",
        SUM(CASE WHEN "Deleted" = 1 THEN 1 ELSE 0 END) AS "Recently Deleted"
    FROM "Media";
END;
$$ LANGUAGE plpgsql;



-- ==============================================================================
-- Find medias for All display in database

DROP FUNCTION IF EXISTS "StreamSearchMedias"(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER);

CREATE OR REPLACE FUNCTION "StreamSearchMedias"(
    inputMonth        INTEGER,
    inputYear         INTEGER,
    offsetIdx         INTEGER,
    limitInput        INTEGER,
    findMake          INTEGER,
    findMediaType     TEXT,
    sortColumnInput   TEXT,
    sortOrderInput    TEXT,
    findFavorite      BOOLEAN,
    findHidden        BOOLEAN,
    findDeleted       BOOLEAN,
    findDuplicate     BOOLEAN,
    albumId           INTEGER
)
RETURNS SETOF RECORD AS $$
DECLARE
    queryText TEXT;
    whereClause TEXT := '1=1';
    cteClause TEXT := '';
    validSortCols TEXT[] := ARRAY['CreateDate', 'FileSize', 'UploadAt', 'HashCode'];
    sortColumn TEXT := 'CreateDate';
    sortOrder TEXT := 'DESC';
BEGIN
    -- ✅ Validate sorting column
    IF sortColumnInput = ANY(validSortCols) THEN
        sortColumn := quote_ident(sortColumnInput);
    END IF;

    -- ✅ Validate sort order
    IF LOWER(sortOrderInput) = 'asc' THEN
        sortOrder := 'ASC';
    END IF;

    -- ✅ Build WHERE conditions
    IF findDuplicate THEN
        whereClause := '
            "HashCode" IN (
                SELECT "HashCode"
                FROM "Media"
                WHERE "HashCode" IS NOT NULL AND "Hidden" = FALSE AND "Deleted" = FALSE
                GROUP BY "HashCode"
                HAVING COUNT(media_id) > 1
            )';
        sortColumn := 'HashCode';
    ELSE
        IF inputYear > 0 THEN
            whereClause := whereClause || ' AND EXTRACT(YEAR FROM "CreateDate") = ' || inputYear;
        END IF;
        IF inputMonth > 0 THEN
            whereClause := whereClause || ' AND EXTRACT(MONTH FROM "CreateDate") = ' || inputMonth;
        END IF;
        IF findMake IS NOT NULL THEN
            whereClause := whereClause || ' AND "CameraType" = ' || findMake;
        END IF;
        IF findMediaType IS NOT NULL AND length(findMediaType) > 0 THEN
            whereClause := whereClause || ' AND "FileType" = ' || quote_literal(findMediaType);
        END IF;
        IF findFavorite THEN
            whereClause := whereClause || ' AND "isFavorite" = TRUE';
        END IF;

        IF findHidden IS NOT NULL THEN
            whereClause := whereClause || ' AND "isHidden" = ' || findHidden;
        ELSE
            whereClause := whereClause || ' AND "isHidden" = FALSE';
        END IF;

        IF findDeleted IS NOT NULL THEN
            whereClause := whereClause || ' AND "isDeleted" = ' || findDeleted;
        ELSE
            whereClause := whereClause || ' AND "isDeleted" = FALSE';
        END IF;
    END IF;

    -- ✅ Album-based CTE
    IF albumId IS NOT NULL THEN
        cteClause := format($f$
            WITH "PhotoView" AS (
                SELECT md.*
                FROM "Album" ab
                LEFT JOIN "AlbumMedia" am ON am.album = ab.album_id
                LEFT JOIN "PhotoView" md ON md.media_id = am.media
                WHERE ab.album_id = %s
            )
        $f$, albumId);
    END IF;

    -- ✅ Final query construction
    queryText := format($f$
        %s
        SELECT 
            media_id, "FileType", "FileName", "FileSize", "isFavorite", 
            "CreateDate", "UploadAt", "ThumbPath", "SourceFile", "CameraType", 
            "TimeFormat", "Duration", "VideoTitle", "MIMEType"
        FROM "PhotoView"
        WHERE %s
        ORDER BY %s %s, media_id ASC
        LIMIT %s OFFSET %s
    $f$, cteClause, whereClause, sortColumn, sortOrder, limitInput, offsetIdx);

    -- ✅ Execute dynamic SQL
    RETURN QUERY EXECUTE queryText;

END;
$$ LANGUAGE plpgsql;



-- SELECT * FROM "StreamSearchMedias"(
--     3, 2024, 0, 20, NULL, 'Photo', 'CreateDate', 'DESC',
--     false, false, false, false, NULL
-- ) AS result (
--     media_id INTEGER,
--     "FileType" TEXT,
--     "FileName" TEXT,
--     "FileSize" BIGINT,
--     "isFavorite" BOOLEAN,
--     "CreateDate" TIMESTAMP,
--     "UploadAt" TIMESTAMP,
--     "ThumbPath" TEXT,
--     "SourceFile" TEXT,
--     "CameraType" INTEGER,
--     "TimeFormat" TEXT,
--     "Duration" INTERVAL,
--     "VideoTitle" TEXT,
--     "MIMEType" TEXT
-- );
