USE Photos;

-- ====================================================================================
-- OPTIONAL: Triggers for managing Media, Favorite, and AlbumMedia tables
-- ====================================================================================
DELIMITER $$

-- ====================================================================================
-- Trigger to update DeletionDate in Media table when Deleted changes
DROP TRIGGER IF EXISTS Media_BEFORE_UPDATE$$
CREATE TRIGGER Media_BEFORE_UPDATE BEFORE UPDATE ON Media
FOR EACH ROW
BEGIN

    -- Set DeletionDate to NOW() if Deleted changes to 1, otherwise set to NULL
    IF OLD.Deleted <> NEW.Deleted THEN
        SET NEW.DeletionDate = IF(NEW.Deleted = 1, NOW(), NULL);
        
        IF NEW.Favorite = 1 THEN
            SET NEW.Favorite = 0;
        END IF;
    END IF;

END$$

-- ====================================================================================
DROP TRIGGER IF EXISTS Account_BEFORE_INSERT$$
CREATE TRIGGER Account_BEFORE_INSERT
BEFORE INSERT ON Account
FOR EACH ROW
BEGIN
    DECLARE admin_exists INT;

    -- Check if an admin account already exists
    SELECT COUNT(*) INTO admin_exists FROM Account WHERE role_type = 'admin';

    -- If NEW account is admin and an admin already exists, block the insert
    IF NEW.role_type = 'admin' AND admin_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admin already exists, insert is prevented';
    END IF;

    -- If NEW account is not admin and no admin exists, block the insert
    IF NEW.role_type <> 'admin' AND admin_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No admin exists, please create an admin account first';
    END IF;
END$$


/*
    Business Requirement #1
    ----------------------------------------------------
    Purpose: Automate Metadata Processing for Uploaded Media Files

    Description: The system must automate the processing and organization of metadata
                 for uploaded media files, ensuring that images, videos, and live streams
                 are categorized appropriately. The trigger must also:
                 - Validate and handle invalid fields like empty dates.
                 - Create or associate related metadata such as camera type and GPS location.
                 - Insert data into relevant tables (e.g., Media, Photo, Video, Live, Location).

    Challenges:
        1. Handling inconsistent or missing metadata in uploaded files.
        2. Generating unique identifiers for media entries without collisions.
        3. Dynamically categorizing and storing different types of media data
           (e.g., images vs. videos vs. live streams).
        4. Ensuring referential integrity for related tables (e.g., CameraType, Location).
        5. Calculating derived fields like video duration display format.

    Assumptions:
        - All uploaded files have a valid MIMEType that can determine their category.
        - Invalid or missing dates default to '9999-12-31 23:59:59'.
        - GPS coordinates (latitude and longitude) are either both provided or omitted.

    Implementation Plan:
        1. Create a trigger (ImagesMetadata_AFTER_INSERT) to process metadata upon insertion.
        2. Validate metadata fields and handle inconsistencies (e.g., empty dates).
        3. Insert or update related data (e.g., camera type, GPS location).
        4. Dynamically categorize media and insert data into specific tables (e.g., Media, Photo, Video, Live).
        5. Test the implementation with example data.

*/
-- Create Index for Camera type table.
-- =======================================

DROP TRIGGER IF EXISTS ImportMedias_AFTER_INSERT$$
CREATE TRIGGER ImportMedias_AFTER_INSERT 
AFTER INSERT ON ImportMedias FOR EACH ROW
BEGIN
    DECLARE mimeTypePrefix VARCHAR(10);
    DECLARE smallestDate DATETIME; -- To store the smallest date if have any
    DECLARE cameraTypeId INT; -- Camera ID if have any
    DECLARE durationDisplay VARCHAR(10); -- Display duration time for videos
    DECLARE mediaType ENUM('Photo', 'Video', 'Live', 'Unknown');
    -- DECLARE lastInsertMediaID INT;
    DECLARE thumbnailName VARCHAR(15); -- Create a random string for thumbnailFile
    
    DECLARE currentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

    -- Extract MIME type prefix (e.g., 'image' from 'image/png')
    SET mimeTypePrefix = SUBSTRING_INDEX(NEW.MIMEType, '/', 1);  -- 'image' from 'image/png'

    -- Determine the smallest valid date among multiple fields. Use CASE statements to handle invalid date values
    SET smallestDate = LEAST(
        IF((NEW.CreateDate = '' OR NEW.CreateDate = '0000:00:00 00:00:00'), currentDate, NEW.CreateDate),
        IF((NEW.DateCreated = '' OR NEW.DateCreated = '0000:00:00 00:00:00'), currentDate, NEW.DateCreated),
        IF((NEW.CreationDate = '' OR NEW.CreationDate = '0000:00:00 00:00:00'), currentDate, NEW.CreationDate),
        IF((NEW.DateTimeOriginal = '' OR NEW.DateTimeOriginal = '0000:00:00 00:00:00'), currentDate, NEW.DateTimeOriginal),
        IF((NEW.FileModifyDate = '' OR NEW.FileModifyDate = '0000:00:00 00:00:00'), currentDate, NEW.FileModifyDate),
        IF((NEW.MediaCreateDate = '' OR NEW.MediaCreateDate = '0000:00:00 00:00:00'), currentDate, NEW.MediaCreateDate),
        IF((NEW.MediaModifyDate = '' OR NEW.MediaModifyDate = '0000:00:00 00:00:00'), currentDate, NEW.MediaModifyDate)
    );
    
    -- Handle camera type association:
    -- Check if Make, Model, and LensModel are not NULL or empty
    IF NEW.Make IS NOT NULL AND NEW.Make <> '' AND NEW.Model IS NOT NULL AND NEW.Model <> '' THEN
        SELECT camera_id INTO cameraTypeId FROM CameraType
        WHERE Make = NEW.Make AND Model = NEW.Model
        -- AND LensModel = NEW.LensModel
        LIMIT 1;
 
        IF cameraTypeId IS NULL THEN
            INSERT INTO CameraType (Make, Model) VALUES (NEW.Make, NEW.Model);
            SET cameraTypeId = LAST_INSERT_ID();
        END IF;
    END IF;

    SET mediaType = IF ( (mimeTypePrefix = 'image'), 'Photo', 
                    IF ( (mimeTypePrefix = 'video'), 
                    IF ( (NEW.Duration > 5), 'Video', 'Live' ), 'Unknown') );
    
    -- Generate unique thumbnail name
    SET thumbnailName = CONCAT(NEW.import_id, LPAD(CONV(NEW.import_id, 10, 36), 8, '0'));

    -- Insert into Media table
    INSERT INTO Media (media_id, FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, SourceFile, MIMEType, ThumbPath) 
        VALUES (NEW.import_id, NEW.FileName, mediaType, NEW.FileType, NEW.Software, NEW.FileSize, cameraTypeId,
        STR_TO_DATE(smallestDate, '%Y-%m-%d %H:%i:%s'), NEW.SourceFile, NEW.MIMEType,
        CONCAT('/Thumbnails/', YEAR(smallestDate), '/', DATE_FORMAT(smallestDate, '%M'), '/', thumbnailName, '.webp')
    );

    -- Reuse this variable as media_id for the last Media inserted
    -- SET lastInsertMediaID = LAST_INSERT_ID();

    -- ///////////// NOTE ///////////////////
    -- The account number needs to be added when the user is created, so we can identify which user uploaded these media.
    INSERT INTO UploadBy (account, media) VALUES (NEW.account, NEW.import_id);

    -- -- Create a thumbnail path and add it to Thumbnail table
    -- INSERT INTO Thumbnail (media, ThumbPath, isImage) 
    -- VALUES (lastInsertMediaID, 
    --   CONCAT('/Thumbnails/', YEAR(smallestDate), '/', DATE_FORMAT(smallestDate, '%M'), '/', NEW.FileName),
    --   IF ( (mimeTypePrefix = 'image'), 1, 0)
    -- );

    -- Insert into Photo, Video, or Live table based on media type
    CASE 
        WHEN mediaType = 'Photo' THEN
            INSERT INTO Photo (media, Orientation, ImageWidth, ImageHeight, Megapixels)
            VALUES (NEW.import_id, NEW.Orientation, NEW.ImageWidth, NEW.ImageHeight, ROUND(NEW.Megapixels, 1));
            
        WHEN mediaType = 'Video' THEN
            SET durationDisplay = CASE
                WHEN FLOOR(NEW.Duration / 3600) > 0 THEN CONCAT(FLOOR(NEW.Duration / 3600), ':', LPAD(FLOOR(NEW.Duration / 60) % 60, 2, '0'), ':', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
                WHEN FLOOR(NEW.Duration / 60) > 0 THEN CONCAT(FLOOR(NEW.Duration / 60), ':', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
                ELSE CONCAT('0:', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
            END;
            INSERT INTO Video (media, Title, Duration, DisplayDuration) 
            VALUES (NEW.import_id, NEW.Title, NEW.Duration, durationDisplay);
            
        WHEN mediaType = 'Live' THEN
            INSERT INTO Live (media, Title, Duration) 
            VALUES (NEW.import_id, NEW.Title, NEW.Duration);
    END CASE;

    -- Handle GPS data
    IF NEW.GPSLatitude IS NOT NULL AND NEW.GPSLatitude != '' 
       AND NEW.GPSLongitude IS NOT NULL AND NEW.GPSLongitude != '' THEN
        INSERT INTO Location (media, GPSLatitude, GPSLongitude) 
        VALUES (NEW.import_id, NEW.GPSLatitude, NEW.GPSLongitude );
    END IF;

END$$

/*
    Business Requirement #2: Create View for Medias
    ----------------------------------------------------
*/

DROP VIEW IF EXISTS PhotoView$$
CREATE VIEW PhotoView AS

-- Assign a ranked class name to each media item based on classification.
-- TODO: This needs to be improved to find multiple tags in the same file
SELECT
    im.media_id,
    im.FileType,
    im.FileName,
    im.FileSize,
    im.CreateDate,
    im.UploadAt,
    im.ThumbPath,
    im.SourceFile,
    im.Favorite as isFavorite,
    im.Hidden as isHidden,
    im.Deleted as isDeleted,
    im.CameraType,
    im.HashCode,
    CONCAT(DATE_FORMAT(im.CreateDate, '%b'), " ", DAY(im.CreateDate), ", ", YEAR(im.CreateDate)) AS timeFormat,
    v.DisplayDuration as duration,
    v.Title as videoTitle,
    im.MIMEType
FROM Media im
LEFT JOIN Video v ON im.media_id = v.media$$



-- ====================================================================================
/*
   Stored Procedure: GetAlbumsAndCount
   - Aggregates total Albums, and count all medias for each album.
   - Does not count Deleted and Hidden medias.
   - Returns results as a single query output.
*/

DROP PROCEDURE IF EXISTS GetAlbumsAndCount$$
CREATE PROCEDURE GetAlbumsAndCount()
BEGIN
    SELECT 
    ab.album_id, 
    ab.title, 
    md.media_id, 
    md.ThumbPath,
    (SELECT COUNT(*) FROM AlbumMedia am_count 
        LEFT JOIN Media as md ON md.media_id = am_count.media      
        WHERE am_count.album = ab.album_id AND md.Hidden = 0 AND md.Deleted = 0) AS media_count
    FROM Album ab
    LEFT JOIN AlbumMedia AS am ON am.album = ab.album_id
    LEFT JOIN Media as md ON md.media_id = am.media
    WHERE md.media_id = (
        SELECT m2.media_id FROM AlbumMedia am2 
        JOIN Media m2 ON m2.media_id = am2.media 
        WHERE am2.album = ab.album_id AND m2.Hidden = 0 AND m2.Deleted = 0
        LIMIT 1
    );
END$$

-- ====================================================================================
/*
   Stored Procedure: GetMediaStatistics
   - Aggregates total favorites, deleted status, and hidden media.
   - Counts duplicate entries based on HashCode.
   - Uses a CTE for efficient duplicate detection.
   - Returns results as a single query output.
*/
DROP PROCEDURE IF EXISTS GetMediaStatistics$$
CREATE PROCEDURE GetMediaStatistics()
BEGIN
    WITH countData AS (
        SELECT COUNT(media_id) AS countDup 
        FROM Media 
        WHERE HashCode IS NOT NULL AND Hidden = 0 AND Deleted = 0
        GROUP BY HashCode 
        HAVING countDup > 1
    )
    SELECT 
        SUM(CASE WHEN Favorite = 1 AND Hidden = 0 AND Deleted = 0 THEN 1 ELSE 0 END) AS 'Favorite',
        (SELECT COALESCE(SUM(countDup), 0) FROM countData) AS 'Duplicate',
        SUM(CASE WHEN Hidden = 1 AND Deleted = 0 THEN 1 ELSE 0 END) AS 'Hidden',
        SUM(Deleted) AS 'Recently Deleted'
    FROM Media;
END $$



-- ==============================================================================
-- Find each media for every year in database

DROP PROCEDURE IF EXISTS GetMediaEachYear$$
CREATE PROCEDURE GetMediaEachYear ()
BEGIN
    WITH ranked_media AS (
        SELECT 
            media_id, FileType, ThumbPath, 
            YEAR(CreateDate) AS createAtYear,
            ROW_NUMBER() OVER (PARTITION BY YEAR(CreateDate) ORDER BY CreateDate) AS rn
        FROM PhotoView
        WHERE isHidden = 0 AND isDeleted = 0
    )
    SELECT media_id, ThumbPath, FileType, createAtYear as timeFormat
    FROM ranked_media
    WHERE rn = 1
    ORDER BY createAtYear DESC;
END $$


-- ==============================================================================
-- Find each media for each year in every month in database
DROP PROCEDURE IF EXISTS GetMediaByYear$$
CREATE PROCEDURE GetMediaByYear (IN inputYear INT)
BEGIN
    WITH ranked_media AS (
        SELECT 
            media_id, FileType, ThumbPath, 
            CreateDate,
            YEAR(CreateDate) AS createAtYear,
            MONTH(CreateDate) AS createAtMonth,
            DAY(CreateDate) AS createAtDate,
            ROW_NUMBER() OVER (
                PARTITION BY YEAR(CreateDate), MONTH(CreateDate)
                ORDER BY CreateDate
            ) AS rn
        FROM PhotoView
        WHERE (inputYear = 0 OR inputYear = YEAR(CreateDate)) AND isHidden = 0 AND isDeleted = 0
    )
    SELECT media_id, ThumbPath, FileType, createAtYear, createAtMonth, createAtDate, CONCAT(DATE_FORMAT(CreateDate, '%M'), " ", createAtYear) as timeFormat
    FROM ranked_media
    WHERE rn = 1
    ORDER BY createAtYear DESC, createAtMonth DESC;
END $$


-- ==============================================================================
-- Find medias for All display in database

DROP PROCEDURE IF EXISTS BuildWhereClause$$
CREATE PROCEDURE BuildWhereClause(
    IN inputMonth INT,
    IN inputYear INT,
    IN findMake INT,
    IN findMediaType VARCHAR(10),
    
    IN findFavorite BOOLEAN,
    IN findHidden BOOLEAN,
    IN findDeleted BOOLEAN,
    
    IN findDuplicate BOOLEAN,

    OUT whereClause TEXT
)
BEGIN
    IF findDuplicate = 1 THEN
        SET whereClause = CONCAT(
            ' HashCode IN (',
            'SELECT HashCode ',
            'FROM Media ',
            'WHERE HashCode IS NOT NULL AND Hidden = 0 AND Deleted = 0 ',
            'GROUP BY HashCode ',
            'HAVING COUNT(media_id) > 1)'
        );
    ELSE
        SET whereClause = CONCAT(
            '1=1 ',
            CASE WHEN inputYear IS NOT NULL AND inputYear > 0 THEN CONCAT(' AND YEAR(CreateDate) = ', inputYear) ELSE '' END,
            CASE WHEN inputMonth IS NOT NULL AND inputMonth > 0 THEN CONCAT(' AND MONTH(CreateDate) = ', inputMonth) ELSE '' END,
            
            CASE WHEN findMake IS NOT NULL THEN CONCAT(' AND CameraType = ', findMake) ELSE '' END,
            CASE WHEN findMediaType IS NOT NULL THEN CONCAT(' AND FileType = ''', findMediaType, '''') ELSE '' END,
            
            CASE WHEN findFavorite IS NOT NULL THEN ' AND isFavorite = 1' ELSE '' END,
            
            CASE WHEN findHidden IS NOT NULL THEN CONCAT(' AND isHidden = 1') ELSE (CASE WHEN findDeleted IS NOT NULL THEN '' ELSE ' AND isHidden = 0 ' END) END,
            CASE WHEN findDeleted IS NOT NULL THEN CONCAT(' AND isDeleted = 1') ELSE ' AND isDeleted = 0 ' END
        );

    END IF;
END$$


DROP PROCEDURE IF EXISTS ValidateSorting$$
CREATE PROCEDURE ValidateSorting(
    IN sortColumnInput VARCHAR(10),
    IN sortOrderInput VARCHAR(5),
    OUT sortColumn VARCHAR(10),
    OUT sortOrder VARCHAR(5)
)
BEGIN
    SET sortColumn = CASE 
        WHEN sortColumnInput IN ('CreateDate', 'FileSize', 'UploadAt', 'HashCode') THEN sortColumnInput 
        ELSE 'CreateDate' 
    END;

    SET sortOrder = CASE 
        WHEN sortOrderInput = 1 THEN 'ASC' 
        ELSE 'DESC' 
    END;
END$$


DROP PROCEDURE IF EXISTS CteClauseAlbum$$
CREATE PROCEDURE CteClauseAlbum(
    IN albumId INT,
    OUT cteClause TEXT
)
BEGIN
    IF albumId IS NOT NULL THEN
        -- Use CTE when albumId is provided
        SET cteClause = CONCAT(
            'WITH PhotoView AS ( ',
            '   SELECT * FROM Album as ab ',
            '   LEFT JOIN AlbumMedia am ON am.album = ab.album_id ',
            '   LEFT JOIN PhotoView md ON md.media_id = am.media ',
            '   WHERE ab.album_id = ', albumId,
            ') '
        );
    ELSE
        SET cteClause = ' ';

    END IF;
END$$


DROP PROCEDURE IF EXISTS StreamSearchMedias$$
CREATE PROCEDURE StreamSearchMedias(
    IN inputMonth INT,
    IN inputYear INT,
    IN offsetIdx INT,
    IN limitInput INT,
    IN findMake INT,
    IN findMediaType VARCHAR(10),
    
    IN sortColumnInput VARCHAR(10),
    IN sortOrderInput VARCHAR(5),
    
    IN findFavorite BOOLEAN,
    IN findHidden BOOLEAN,
    IN findDeleted BOOLEAN,
    IN findDuplicate BOOLEAN,

    IN albumId INT
)
BEGIN
    DECLARE whereClause TEXT;
    DECLARE cteClause TEXT;
    DECLARE sortColumn VARCHAR(10);
    DECLARE sortOrder VARCHAR(5);

    CALL ValidateSorting(sortColumnInput, sortOrderInput, sortColumn, sortOrder);
    CALL BuildWhereClause(inputMonth, inputYear, findMake, findMediaType, findFavorite, findHidden, findDeleted, findDuplicate, whereClause);
    CALL CteClauseAlbum(albumId, cteClause);

    IF findDuplicate = 1 THEN SET sortColumn = 'HashCode '; END IF;

    SET @query = CONCAT(
        cteClause,
        'SELECT media_id, FileType, FileName, FileSize, isFavorite, CreateDate, UploadAt, ThumbPath, SourceFile, CameraType, timeFormat, duration, videoTitle, MIMEType ',
        'FROM PhotoView ',
        'WHERE ', whereClause, ' ',
        'ORDER BY ', sortColumn, ' ', sortOrder, ', media_id ASC ',
        'LIMIT ', offsetIdx, ', ', limitInput
    );

    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- Auto create an admin if there is no user exist in the db
DROP TRIGGER IF EXISTS UserGuest_AFTER_INSERT$$
CREATE TRIGGER UserGuest_AFTER_INSERT AFTER INSERT ON UserGuest 
FOR EACH ROW
BEGIN 
    DECLARE account_exist INT;
    -- SELECT account_id INTO account_exist FROM Account WHERE role_type = 'admin' LIMIT 1;
    SELECT account_id INTO account_exist FROM Account LIMIT 1;
    -- If no user has been create an account, create an admin
    IF account_exist IS NULL THEN
        INSERT INTO Account (user_email, role_type)
        VALUES (NEW.user_email, 'admin');
    END IF;

END$$ 

