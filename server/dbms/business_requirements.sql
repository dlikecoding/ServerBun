USE Photos;

-- ====================================================================================
-- OPTIONAL: Triggers for managing Media, Favorite, and AlbumMedia tables
-- ====================================================================================
DELIMITER $$

-- ====================================================================================
-- Trigger to update DeletionDate in Media table when DeletedStatus changes
DROP TRIGGER IF EXISTS Media_BEFORE_UPDATE$$
CREATE TRIGGER Media_BEFORE_UPDATE BEFORE UPDATE ON Media
FOR EACH ROW
BEGIN
    -- Set DeletionDate to NOW() if DeletedStatus changes to 1, otherwise set to NULL
    IF OLD.DeletedStatus != NEW.DeletedStatus THEN
        SET NEW.DeletionDate = IF(NEW.DeletedStatus = 1, NOW(), NULL);
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
-- =======================================
-- =======================================

DROP TRIGGER IF EXISTS ImportMedias_AFTER_INSERT$$
DELIMITER $$

CREATE TRIGGER ImportMedias_AFTER_INSERT 
AFTER INSERT ON ImportMedias FOR EACH ROW
BEGIN
    DECLARE mimeTypePrefix VARCHAR(10);
    DECLARE smallestDate DATETIME; -- To store the smallest date if have any
    DECLARE cameraTypeId INT; -- Camera ID if have any
    DECLARE durationDisplay VARCHAR(20); -- Display duration time for videos
    DECLARE mediaType VARCHAR(7); -- Media Type for ENUM (Photo/Video/Live/Unknown)
    DECLARE lastInsertMediaID VARCHAR(15); -- Create a random string for an URL
    
    DECLARE currentDate TIMESTAMP;
    SET currentDate = CURRENT_TIMESTAMP;

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
    IF NEW.Make IS NOT NULL AND NEW.Make <> '' 
       AND NEW.Model IS NOT NULL AND NEW.Model <> '' 
       AND NEW.LensModel IS NOT NULL AND NEW.LensModel <> '' THEN
        
        -- Check if the record already exists and get the cameraTypeId
        SELECT camera_id INTO cameraTypeId FROM CameraType
        WHERE Make = NEW.Make AND Model = NEW.Model AND LensModel = NEW.LensModel
        LIMIT 1;

        -- If the record already exists, prevent the insert and raise an error
        IF cameraTypeId IS NULL THEN
            -- Insert data into another table (e.g., CameraType) if Make, Model, and LensModel are valid
            INSERT INTO CameraType ( Make, Model, LensModel) 
            VALUES ( NEW.Make, NEW.Model, NEW.LensModel );

            -- Get the last inserted ID
            SET cameraTypeId = LAST_INSERT_ID();
        END IF;
    END IF;

    SET mediaType = IF ( (mimeTypePrefix = 'image'), 'Photo', 
                    IF ( (mimeTypePrefix = 'video'), 
                    IF ( (NEW.Duration > 5), 'Video', 'Live' ), 'Unknown') );
    
    -- Generate unique thumbnail name
    SET lastInsertMediaID = CONCAT(
        CAST(NEW.import_id AS CHAR),
        SUBSTRING(REPLACE(UUID(), '-', ''), 1, 15 - LENGTH(CAST(NEW.import_id AS CHAR)))
    );

    -- Insert into Media table
    INSERT INTO Media (FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, SourceFile, MIMEType, ThumbPath) 
        VALUES (NEW.FileName, mediaType, NEW.FileType, NEW.Software, NEW.FileSize, cameraTypeId,
        STR_TO_DATE(smallestDate, '%Y-%m-%d %H:%i:%s'), NEW.SourceFile, NEW.MIMEType,
        CONCAT('/Thumbnails/', YEAR(smallestDate), '/', DATE_FORMAT(smallestDate, '%M'), '/', lastInsertMediaID, '.webp')
    );

    -- Reuse this variable as media_id for the last Media inserted
    SET lastInsertMediaID = LAST_INSERT_ID();

    -- ///////////// NOTE ///////////////////
    -- The account number needs to be added when the user is created, so we can identify which user uploaded these media.
    -- It is necessary to insert into the UploadBy table (account, media_id).
    INSERT INTO UploadBy (account, media)
    VALUES (NEW.account, lastInsertMediaID);

    -- -- Insert into SourceFile table
    -- INSERT INTO SourceFile (media, SourceFile, MIMEType) 
    -- VALUES (lastInsertMediaID, NEW.SourceFile, NEW.MIMEType);

    -- -- Create a thumbnail path and add it to Thumbnail table
    -- INSERT INTO Thumbnail (media, ThumbPath, isImage) 
    -- VALUES (lastInsertMediaID, 
    --   CONCAT('/Thumbnails/', YEAR(smallestDate), '/', DATE_FORMAT(smallestDate, '%M'), '/', NEW.FileName),
    --   IF ( (mimeTypePrefix = 'image'), 1, 0)
    -- );

     -- Handle specific types of media
    IF mediaType = 'Photo' THEN
        -- Insert into Photo table
        INSERT INTO Photo (media, Orientation, ImageWidth, ImageHeight, Megapixels)
        VALUES (lastInsertMediaID, NEW.Orientation, NEW.ImageWidth, NEW.ImageHeight, ROUND(NEW.Megapixels, 1) );

    -- Check if the file type is a 'video'
    ELSEIF mediaType = 'Video' THEN
        SET durationDisplay = CASE
            WHEN FLOOR(NEW.Duration / 3600) > 0 THEN CONCAT(
                FLOOR(NEW.Duration / 3600), ':', 
                LPAD(FLOOR(NEW.Duration / 60) % 60, 2, '0'), ':', 
                LPAD(ROUND(NEW.Duration % 60), 2, '0')
            )
            WHEN FLOOR(NEW.Duration / 60) > 0 THEN CONCAT(
                FLOOR(NEW.Duration / 60), ':', 
                LPAD(ROUND(NEW.Duration % 60), 2, '0')
            )
            ELSE CONCAT('0:', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
        END;

        -- Insert into Video table
        INSERT INTO Video ( media, Title, Duration, DisplayDuration) 
        VALUES (lastInsertMediaID, NEW.Title, NEW.Duration, durationDisplay);

    ELSEIF mediaType = 'Live' THEN
        -- Insert into Live table
        INSERT INTO Live ( media, Title, Duration) 
        VALUES (lastInsertMediaID, NEW.Title, NEW.Duration);
    
    -- Ignore unknown or others formats from now
    END If;

    -- Handle GPS data
    IF NEW.GPSLatitude IS NOT NULL AND NEW.GPSLatitude != '' 
       AND NEW.GPSLongitude IS NOT NULL AND NEW.GPSLongitude != '' THEN

        -- Insert data into another table (e.g., Location) if GPSLatitude and GPSLongitude are valid
        INSERT INTO Location (media, GPSLatitude, GPSLongitude) 
        VALUES (lastInsertMediaID, NEW.GPSLatitude, NEW.GPSLongitude );
    END IF;

END$$



-- INSERT INTO ImportMedias ( account,
--     FileName, FileType, MIMEType, Software, Title, FileSize, Make, Model, 
--     LensModel, Orientation, CreateDate, DateCreated, CreationDate, DateTimeOriginal, 
--     FileModifyDate, MediaCreateDate, MediaModifyDate, Duration, GPSLatitude, 
--     GPSLongitude, ImageWidth, ImageHeight, SourceFile, Megapixels
-- )
-- VALUES
-- (1, 'test_import1.jpg', 'JPEG', 'image/jpeg', 'Adobe Photoshop', 'Sunset Beach', 2048000, 'Canon', 'EOS 5D Mark IV', 'EF 24-70mm f/2.8L II USM', 'Landscape', '2024-01-01', '2024-01-01', '2024-01-01', '2024-01-01', '2024-01-01', '2024-01-01', '2024-01-01', NULL, 34.052235, -118.243683, 1920, 1080, '/photos/sunset.jpg', 21.0),
-- (1, 'import_video1.mp4', 'MP4', 'video/mp4', 'Final Cut Pro', 'Mountain Adventure', 104857600, 'GoPro', 'HERO10 Black', NULL, NULL, '2024-02-15', '2024-02-15', '2024-02-15', '2024-02-15', '2024-02-15', '2024-02-15', '2024-02-15', 120.5, 39.739236, -104.990251, NULL, NULL, '/videos/adventure.mp4', 12.9),
-- (1, 'test_import4.heic', 'HEIC', 'image/heic', 'Apple Photos', 'Spring Flowers', 1024000, 'Apple', 'iPhone 13', NULL, 'Portrait', '2024-07-10', '2024-07-10', '2024-07-10', '2024-07-10', '2024-07-10', '2024-07-10', '2024-07-10', NULL, 37.774929, -122.419418, 3024, 4032, '/images/spring.heic', 12.290);


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
    im.CreateDate,
    im.ThumbPath,
    im.SourceFile,
    im.Favorite as isFavorite,
    CONCAT(DATE_FORMAT(im.CreateDate, '%b'), " ", DAY(im.CreateDate), ", ", YEAR(im.CreateDate)) AS timeFormat,
    v.DisplayDuration as duration,
    v.Title
FROM Media im
LEFT JOIN Video v ON im.media_id = v.media$$

-- =========================ALL VIEW ====================================

-- Drop the view if it exists to ensure fresh creation
DROP VIEW IF EXISTS MediaSearchView$$
CREATE VIEW MediaSearchView AS

-- Assign a ranked class name to each media item based on classification.
-- TODO: This needs to be improved to find multiple tags in the same file
WITH AiClasses AS (
    SELECT ai.media, al.ClassName,
        ROW_NUMBER() OVER (PARTITION BY ai.media ORDER BY al.ClassName DESC) AS RowNum
    FROM AiRecognition ai
    LEFT JOIN AiClass al ON ai.AiClass = al.class_id
)
SELECT
    im.media_id,
    im.FileType,
    im.FileName,
    im.CreateDate,
    -- TODO: Implement a function to automatically calculate and format the file size for display
    -- The function should handle various units (bytes, KB, MB, GB) and return a human-readable format.
    CASE
        WHEN im.FileSize < 1024 THEN CONCAT(im.FileSize, ' B')
        WHEN im.FileSize < 1024 * 1024 THEN CONCAT(ROUND(im.FileSize / 1024, 2), ' KB')
        WHEN im.FileSize < 1024 * 1024 * 1024 THEN CONCAT(ROUND(im.FileSize / (1024 * 1024), 2), ' MB')
        ELSE CONCAT(ROUND(im.FileSize / (1024 * 1024 * 1024), 2), ' GB')
    END AS fSize,
    im.FileSize,
    im.FileExt,
    ac.ClassName,
    c.Make,
    c.Model,
    p.Megapixels,
    v.DisplayDuration,
    v.Title,
    loc.City,
    loc.GPSLatitude,
    loc.GPSLongitude
FROM Media im

-- Join details for specific media types.
LEFT JOIN Photo p ON im.media_id = p.media
LEFT JOIN Live l ON im.media_id = l.media
LEFT JOIN Video v ON im.media_id = v.media
LEFT JOIN Thumbnail tn ON im.media_id = tn.media
-- Join camera and location details.
LEFT JOIN CameraType c ON im.CameraType = c.camera_id
LEFT JOIN Location loc ON im.media_id = loc.media

-- Join AI classification details with the highest priority class name.
LEFT JOIN AiClasses ac ON im.media_id = ac.media AND ac.RowNum = 1$$

-- Apply filters to exclude private, hidden, or deleted media.
-- WHERE im.Privacy <> 1 
--     AND im.Hidden <> 1 
--     AND im.DeletedStatus <> 1;

-- Test the view with an explicit query.
-- SELECT * FROM MediaSearchView;


-- Create a dynamic stored procedure for flexible media searches

DROP PROCEDURE IF EXISTS SearchMedia;
CREATE PROCEDURE SearchMedia(
    IN findYear INT,
    IN findMonth INT,
    IN findMediaType VARCHAR(50),
    IN findMake VARCHAR(100),
    IN findModel VARCHAR(100),
    IN findCity VARCHAR(100),
    IN findTag VARCHAR(100),
    IN sortColumn VARCHAR(50),
    IN sortOrder VARCHAR(4),
    IN pageSize INT,
    IN pageNumber INT
)
BEGIN
    -- Input Validation
    DECLARE whereClause TEXT DEFAULT '1=1'; -- Base condition to simplify appending filters
    DECLARE offsetIdx INT;

    -- Set default values for pageSize and pageNumber if they are NULL
    IF pageSize IS NULL OR pageSize <= 0 THEN SET pageSize = 100; END IF;
    IF pageNumber IS NULL OR pageNumber <= 0 THEN SET pageNumber = 1; END IF;

    -- Validate sorting inputs
    SET sortColumn = CASE 
        WHEN sortColumn IN ('FileType', 'CreateDate', 'FileSize') THEN sortColumn 
        ELSE 'CreateDate' 
    END;

    SET sortOrder = CASE 
        WHEN sortOrder IN ('ASC', 'DESC') THEN sortOrder 
        ELSE 'DESC' 
    END;

    -- Pagination calculation
    SET offsetIdx = (pageNumber - 1) * pageSize;

    -- Build WHERE Clause
    SET whereClause = CONCAT(
        whereClause,
        CASE WHEN findYear IS NOT NULL THEN CONCAT(' AND YEAR(CreateDate) = ', findYear) ELSE '' END,
        CASE WHEN findMonth IS NOT NULL THEN CONCAT(' AND MONTH(CreateDate) = ', findMonth) ELSE '' END,
        CASE WHEN findMediaType IS NOT NULL THEN CONCAT(' AND FileType LIKE ''%', findMediaType, '%''') ELSE '' END,
        CASE WHEN findMake IS NOT NULL THEN CONCAT(' AND Make LIKE ''%', findMake, '%''') ELSE '' END,
        CASE WHEN findModel IS NOT NULL THEN CONCAT(' AND Model LIKE ''%', findModel, '%''') ELSE '' END,
        CASE WHEN findCity IS NOT NULL THEN CONCAT(' AND City LIKE ''%', findCity, '%''') ELSE '' END,
        CASE WHEN findTag IS NOT NULL THEN CONCAT(' AND ClassName LIKE ''%', findTag, '%''') ELSE '' END
    );

    -- Construct final query
    SET @query = CONCAT(
        'SELECT FileType, FileName, CreateDate, FileSize, FileExt, URL, ',
        'Make, Model, Megapixels, ClassName, DisplayDuration, Title, City ',
        'FROM MediaSearchView ',
        'WHERE ', whereClause, ' ',
        'ORDER BY ', sortColumn, ' ', sortOrder, ' ',
        'LIMIT ', offsetIdx, ', ', pageSize
    );

    -- Debugging: Log query (optional)
    -- INSERT INTO QueryLog(queryText) VALUES (@query);

    -- Prepare and Execute query
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$



 
-- Error because MySQL does not support creating an index on a view (MediaSearchView). 
-- CREATE INDEX idx_media ON Media (
--     YEAR(CreateDate), MONTH(CreateDate), FileType, Make, Model, City, ClassName
-- );

-- Indexes can only be created on tables, not views.
-- CREATE INDEX idx_media_search ON MediaSearchView (
--     YEAR(CreateDate), MONTH(CreateDate), FileType, Make, Model, City, ClassName
-- );
-- CREATE INDEX idx_sort_create_date ON MediaSearchView (CreateDate);
-- CREATE FULLTEXT INDEX idx_fulltext_search ON MediaSearchView (Make, Model, City, ClassName);

-- CALL SearchMedia(
--     NULL,        -- findYear
--     NULL,        -- findMonth
--     NULL,        -- findMediaType
--     NULL,        -- findMake
--     NULL,        -- findModel
--     NULL,        -- findCity
--     NULL,        -- findTag
--     NULL,        -- sortBy
--     NULL,        -- sortOrder
--     4,           -- numberOfRecords
--     19           -- offsetIdx
-- );

-- ====================================================================================
/*
    Business Requirement #3: Advanced and Flexible Media Data Insights
    -----------------------------------------------------------------
    Purpose: Enable comprehensive insights into the media dataset by implementing efficient procedures 
             for diverse use cases, including album summaries, AI recognition analysis, location-based queries, 
             duplicate detection, and media type counts.

    Key Objectives:
        1. Develop a scalable system for detailed and actionable media data retrieval.
        2. Support multiple use cases dynamically, such as album-based views, AI-driven analyses, and 
           geospatial filtering.
        3. Ensure high performance for both exploratory and summary-level queries across large datasets.
        4. Handle flexible query configurations and default values for missing parameters.

    Challenges:
        - Efficiently combining metadata from related tables into meaningful summaries.
        - Ensuring scalability for high-volume datasets with diverse query requirements.
        - Addressing missing or null parameters gracefully without degrading performance.

    Assumptions:
        1. The MediaSearchView provides a consolidated and normalized view of media metadata.
        2. Input parameters may be null, requiring default fallback behavior.
        3. AI-generated labels (e.g., detection results) are accurate and consistent across media types.
        4. Location data, when available, is complete and valid.

    Implementation Plan:
        1. Create a Stored Procedure (FetchMediaSummary):
            - Handles multiple query scenarios dynamically via a section parameter.
            - Supports pagination and default parameter handling for flexible usage.
        2. Integrate Query Sections:
            - Section 1: Fetch album-level summaries with representative media.
            - Section 2: Retrieve AI-detection labels and associated media.
            - Section 3: Query media based on geospatial information.
            - Section 4: Identify and count duplicate hash codes in the dataset. Provide 
            aggregate counts of media types, favorites, and trashed items.
        3. Optimize Queries:
            - Use indexed columns in joins and filters.
            - Leverage window functions like ROW_NUMBER() for ranked data selection.
        4. Validate:
            - Test with varied section inputs and edge cases (e.g., missing parameters).
            - Ensure results are consistent with business expectations.
*/


-- Create trigger to count number of Favorite for section 1

-- Trigger has been created in the EER model. You can now test its functionality

-- DROP PROCEDURE IF EXISTS FetchMediaSummary;
-- CREATE PROCEDURE FetchMediaSummary(
--     IN section INT, 
--     IN numberOfRecords INT
-- )
-- BEGIN
--     -- Handle null parameter by providing defaults
--     IF numberOfRecords IS NULL OR numberOfRecords <= 0 THEN
--         SET numberOfRecords = 10; -- Default to 10 results per page
--     END IF;

--     -- Section 1: Fetch albums with their associated media files
--     IF section = 1 THEN
--         WITH RankedC AS (
--             SELECT al.album_id, al.title, al.mediaCount, md.*, 
--                 ROW_NUMBER() OVER (PARTITION BY al.album_id ORDER BY md.media_id) AS row_num
--             FROM Album al
--             LEFT JOIN AlbumMedia am ON al.album_id = am.album
--             LEFT JOIN Media md ON md.media_id = am.media
--         )
--         SELECT * FROM RankedC
--         WHERE row_num = 1
--         ORDER BY al.title ASC
--         LIMIT numberOfRecords;

--     -- Section 2: Fetch detection labels and associated media files
--     ELSEIF section = 2 THEN
--         WITH RankedClass AS (
--             SELECT ac.ClassName, md.*, 
--                 ROW_NUMBER() OVER (PARTITION BY ac.class_id ORDER BY md.media_id) AS row_num
--             FROM AiClass ac
--             LEFT JOIN AiRecognition ar ON ar.AiClass = ac.class_id
--             LEFT JOIN Media md ON md.media_id = ar.media
--         )
--         SELECT * FROM RankedClass
--         WHERE row_num = 1
--         ORDER BY ac.ClassName ASC
--         LIMIT numberOfRecords;

--     -- Section 3: Fetch location labels and associated media files
--     ELSEIF section = 3 THEN
--         SELECT loc.*, md.*
--         FROM Location loc
--         LEFT JOIN Media md ON loc.media = md.media_id
--         LIMIT numberOfRecords;

--     -- Section 4: Count media types
--     ELSEIF section = 4 THEN
--         -- Section 4a: Count duplicate hash codes in Media table
--         WITH DuplicateCounts AS (
--             SELECT HashCode, COUNT(*) AS CountDup
--             FROM Media
--             WHERE HashCode IS NOT NULL
--             GROUP BY HashCode
--             HAVING CountDup > 1
--         )
--         SELECT
--             -- Calculate total duplicate count
--             (SELECT SUM(CountDup) FROM DuplicateCounts) AS Duplicates,
--             -- Count based on FileType
--             COUNT(CASE WHEN FileType = 'Photo' THEN 1 END) AS Photos,
--             COUNT(CASE WHEN FileType = 'Video' THEN 1 END) AS Videos,
--             COUNT(CASE WHEN FileType = 'Live' THEN 1 END) AS Lives,
--             -- Count of favorites
--             COUNT(CASE WHEN FavoriteCount > 0 THEN 1 END) AS Favorite,
--             -- Count of trashed items
--             COUNT(CASE WHEN DeletedStatus = 1 THEN 1 END) AS Trash
--         FROM Media;

--     ELSE
--         -- Return a message if the section parameter is invalid
--         SELECT 'Invalid section value. Please provide a value between 1 and 5.' AS ErrorMessage;
--     END IF;
-- END$$


-- Example Usage:
-- CALL FetchMediaSummary(1, NULL); -- Fetch album summaries with default 10 records
-- CALL FetchMediaSummary(2, 20);   -- Fetch AI-detection labels with 20 records
-- CALL FetchMediaSummary(3, 15);   -- Fetch location-based media with 15 records
-- CALL FetchMediaSummary(4, NULL); -- Count media types




-- ===============================================================================
/*
    Business Requirement #4
    ----------------------------------------------------
    Purpose: Automate AI Metadata Processing for Media Files

    Description: Automate the processing of AI-generated metadata from TempAiTags table by dynamically 
                 inserting data into appropriate tables (Detect, Classify, etc.) based on the AI model. 
                 Ensure data consistency, referential integrity, and error handling for unsupported models.

    Challenges:
        1. Managing unsupported or unknown AI models.
        2. Avoiding redundant entries in AiRecognition.
        3. Handling floating-point precision for confidence scores and offsets.

    Assumptions:
        - Supported AI models: 'Detect', 'Classify', 'Segment'.
        - Input data in TempAiTags is validated and normalized.

    Implementation Plan:
        1. Create procedures (GenerateAIDetect, GenerateAIClassify) for model-specific processing.
        2. Implement a trigger (TempAiTags_AFTER_INSERT) to call the appropriate procedure dynamically.
        3. Enforce referential integrity and validate AI model types.
        4. Test with diverse scenarios to ensure robustness.
*/

-- Trigger for processing TempAiTags insertions
DROP TRIGGER IF EXISTS TempAiTags_AFTER_INSERT;
CREATE TRIGGER TempAiTags_AFTER_INSERT 
AFTER INSERT ON TempAiTags FOR EACH ROW
BEGIN
    -- Step 1: Insert or ignore into AiClass
    INSERT IGNORE INTO AiClass (class_id, ClassName)
    VALUES (NEW.class_id, NEW.class_name);

    -- Step 2: Insert or ignore into AiRecognition
    INSERT IGNORE INTO AiRecognition (media, AiClass, AiMode)
    VALUES (NEW.media_id, NEW.class_id, NEW.ai_model);

    -- Step 3: Handle logic based on AI model type
    IF (NEW.ai_model = 'Detect') THEN
        INSERT INTO Detect (ai_recognition, confidence, b_box)
        SELECT 
            ar.ai_recognition_id,
            NEW.confidence,
            NEW.b_box
        FROM AiRecognition ar
        WHERE ar.media = NEW.media_id
        AND ar.AiClass = NEW.class_id
        LIMIT 1;

    ELSEIF (NEW.ai_model = 'Classify') THEN
        INSERT INTO Classify (ai_recognition, confidence)
        SELECT 
            ar.ai_recognition_id,
            NEW.confidence
        FROM AiRecognition ar
        WHERE ar.media = NEW.media_id
        AND ar.AiClass = NEW.class_id
        LIMIT 1;
    
    ELSEIF (NEW.ai_model = 'Segment') THEN
        INSERT INTO Segment (ai_recognition, confidence, b_box)
        SELECT 
            ar.ai_recognition_id,
            NEW.confidence,
            NEW.b_box
        FROM AiRecognition ar
        WHERE ar.media = NEW.media_id
        AND ar.AiClass = NEW.class_id
        LIMIT 1;

    ELSE
        -- SELECT 'Unsupported AI model. Please provide a valid model (Detect, Classify or Segment)' AS ErrorMessage;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Unsupported AI model. Please provide a valid model (Detect, Classify or Segment)';
    END IF;
END$$



-- INSERT INTO TempAiTags (class_id, class_name, media_id, ai_model, confidence, b_box)
-- VALUES 
-- -- Test Case 1: Insert for AI Model 'Detect'
--     (1, 'Vehicle', 1, 'Detect', 0.95, '[50,50,200,200]'),

-- -- Test Case 2: Insert for AI Model 'Classify'
--     (2, 'Animal', 2, 'Classify', 0.90, NULL),

-- -- Test Case 3: Insert for AI Model 'Segment'
--     (3, 'Person', 3, 'Segment', 0.85, '[30,30,100,100]'),

-- -- Test Case 4: Insert Duplicate Entry for AI Model 'Detect'
--     (1, 'Vehicle', 1, 'Detect', 0.90, '[60,60,220,220]');


-- ===============================================================================
/*
    Business Requirement #5
    ----------------------------------------------------
    Purpose: Enable Admins to View and Filter User Activities and System Error Logs

    Description: Provide administrators with the ability to view user activity logs and system error logs 
                 dynamically, while allowing filtering by user attributes, error types, date ranges, and other 
                 key parameters. Ensure the system handles large datasets efficiently, maintains data consistency, 
                 and restricts access to authorized admin accounts only.

    Challenges:
        1. Efficiently querying and displaying logs for large datasets through optimized SQL views.
        2. Allowing dynamic filtering and sorting without impacting database performance.
        3. Ensuring secure access by restricting log views to users with "admin" roles.
        4. Handling complex queries for filtering, pagination, and sorting across multiple tables.

    Assumptions:
        - Only users with role_type = "admin" have access to this feature.
        - The User, UserLog, SystemLog, and ErrorLog tables are populated correctly and are consistently updated.
        - Logs must be exportable for further external analysis.

    Implementation Plan:
        1. Create Views:
            - AdminUserLogView to simplify querying user activity logs.
        2. Implement Stored Procedures:
            - GetUserLogs for dynamic filtering, sorting, and pagination of user activity logs.
            - GetErrorLogs for dynamic filtering, sorting, and pagination of error logs.
        3. Dynamic Query Handling:
            - Use stored procedures to construct queries with placeholders for flexible filters and default values for missing inputs.
            - Include pagination (page number and page size) and dynamic sorting (sort column and order)
*/


-- -- Step 1: Create Views for Simplified Log Queries
DROP VIEW IF EXISTS AdminUserLogView$$
CREATE VIEW AdminUserLogView AS
SELECT 
    u.user_id AS UserID,
    u.user_name AS UserName,
    u.user_email AS UserEmail,
    u.request_status AS UserReq,
    ul.ip_address AS IPAddress,
    ul.user_device AS UserDevice,
    ul.last_url_request AS LastURLRequest,
    ul.last_logged_in AS LastLoggedIn,
    ul.ip_address AS LastIP,
    ul.logged_at AS LogTime

FROM UserGuest u
JOIN UserLog ul ON u.user_id = ul.UserGuest$$

-- Step 2: Create Stored Procedures for Dynamic Filtering


DROP PROCEDURE IF EXISTS GetUserLogs;
CREATE PROCEDURE GetUserLogs(
    IN filterName VARCHAR(40),
    IN filterEmail VARCHAR(50),
    IN filterIp VARCHAR(45),
    IN intervalDays INT,
    IN sortColumn VARCHAR(50),
    IN sortOrder VARCHAR(4),
    IN pageNumber INT
)
BEGIN
    DECLARE skipOffset INT;
    DECLARE pageSize INT DEFAULT 100;
    DECLARE whereClause TEXT DEFAULT '1=1';
    
    -- Input Validation and Defaults
    SET sortColumn = CASE 
        WHEN sortColumn IN ('UserName', 'UserEmail', 'LastLoggedIn') THEN sortColumn 
        ELSE 'LastLoggedIn' 
    END;

    SET sortOrder = CASE 
        WHEN sortOrder IN ('ASC', 'DESC') THEN sortOrder 
        ELSE 'DESC' 
    END;

    IF pageNumber IS NULL OR pageNumber < 1 THEN SET pageNumber = 1; END IF;

    -- Calculate Offset
    SET skipOffset = (pageNumber - 1) * pageSize;

    -- Build WHERE Clause
    SET whereClause = CONCAT(
        whereClause,                                                    
        CASE WHEN filterName IS NOT NULL THEN CONCAT(' AND UserName LIKE ''%', filterName, '%''') ELSE '' END,
        CASE WHEN filterEmail IS NOT NULL THEN CONCAT(' AND UserEmail LIKE ''%', filterEmail, '%''') ELSE '' END,
        CASE WHEN filterIp IS NOT NULL THEN CONCAT(' AND IPAddress LIKE ''%', filterIp, '%''') ELSE '' END,
        CASE WHEN intervalDays IS NOT NULL THEN CONCAT(' AND LogTime >= NOW() - INTERVAL ', intervalDays, ' DAY') ELSE '' END
    );

    -- Construct Query
    SET @query = CONCAT(
        'SELECT 
            UserID, UserName, UserEmail, IPAddress, UserDevice, LastURLRequest, LastLoggedIn
        FROM AdminUserLogView 
        WHERE ', whereClause, ' 
        ORDER BY ', sortColumn, ' ', sortOrder, '
        LIMIT ', skipOffset, ', ', pageSize
    );

    -- Debugging (Optional): Log the generated query for troubleshooting
    -- INSERT INTO QueryLog(queryText) VALUES (@query);

    -- Prepare, Execute, and Cleanup
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$


-- ==============================================================================

DROP PROCEDURE IF EXISTS GetErrorLogs$$
CREATE PROCEDURE GetErrorLogs(
    IN filterType VARCHAR(10),
    IN intervalDays INT,
    IN sortColumn VARCHAR(50),
    IN sortOrder VARCHAR(4),
    IN pageNumber INT
)
BEGIN
    DECLARE skipOffset INT;
    DECLARE pageSize INT DEFAULT 100;
    DECLARE whereClause TEXT DEFAULT '1=1';

    -- Input Validation and Defaults
    SET sortColumn = CASE 
        WHEN sortColumn IN ('stack_trace', 'error_msg', 'logged_at') THEN sortColumn 
        ELSE 'logged_at' 
    END;

    SET sortOrder = CASE 
        WHEN sortOrder IN ('ASC', 'DESC') THEN sortOrder 
        ELSE 'DESC' 
    END;

    IF pageNumber IS NULL OR pageNumber < 1 THEN SET pageNumber = 1; END IF;

    -- Calculate Offset
    SET skipOffset = (pageNumber - 1) * pageSize;

    -- Build WHERE Clause
    SET whereClause = CONCAT(
        whereClause,                                                        
        CASE WHEN filterType IS NOT NULL THEN CONCAT(' AND error_type LIKE ''%', filterType, '%''') ELSE '' END,
        CASE WHEN intervalDays IS NOT NULL THEN CONCAT(' AND logged_at >= NOW() - INTERVAL ', intervalDays, ' DAY') ELSE '' END
        -- CASE WHEN intervalHours IS NOT NULL THEN CONCAT(' AND logged_at >= NOW() - INTERVAL ', intervalHours, ' HOUR') ELSE '' END
    );

    -- Construct Query
    SET @query = CONCAT(
        'SELECT 
            error_log_id, server_system, error_msg, stack_trace, error_type, logged_at
        FROM ErrorLog
        WHERE ', whereClause, ' 
        ORDER BY ', sortColumn, ' ', sortOrder, '
        LIMIT ', skipOffset, ', ', pageSize
    );

    -- Debugging (Optional): Log the generated query for troubleshooting
    -- INSERT INTO QueryLog(queryText) VALUES (@query);

    -- Prepare, Execute, and Cleanup
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$




-- -- =============================
-- -- Testing: GetUserLogs Procedure
-- -- =============================
-- -- Test Case 1: Fetch all logs, sorted by 'LastLoggedIn', default pagination
-- CALL GetUserLogs(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
-- CALL GetUserLogs(
--     NULL, -- filterName 
--     NULL, -- filterEmail 
--     NULL, -- filterIp 
--     NULL, -- intervalDays
--     NULL, -- sortColumn 
--     NULL, -- sortOrder 
--     NULL, -- pageNumber
--     NULL, -- pageSize
-- )
-- -- Test Case 2: Filter by UserName and date range
-- CALL GetUserLogs( NULL, NULL, NULL, 5, 'LastLoggedIn', 'DECS', 1, 5);

-- -- =============================
-- -- Testing: GetErrorLogs Procedure
-- -- =============================
-- -- Test Case 1: Fetch all error logs, sorted by 'LoggedAt', default pagination
-- CALL GetErrorLogs(
--     NULL, -- filterType 
--     NULL, -- filterSystemLog 
--     NULL, -- intervalDays 
--     NULL, -- sortColumn
--     NULL, -- sortOrder
--     NULL, -- pageNumber 
--     NULL  -- pageSize
-- )

-- -- Test Case 2: Filter by error type (backend) and server UUID
-- CALL GetErrorLogs('backend', '123e4567-e89b-12d3-a456-426614174000', NULL, NULL, 'ErrorType', 'ASC', 1, 10);



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
            ROW_NUMBER() OVER (
                PARTITION BY YEAR(CreateDate), MONTH(CreateDate)
                ORDER BY CreateDate
            ) AS rn
        FROM PhotoView
        WHERE inputYear = 0 OR YEAR(CreateDate) = inputYear
    )
    SELECT media_id, ThumbPath, FileType, createAtYear, createAtMonth, CONCAT(DATE_FORMAT(CreateDate, '%M'), ", ", createAtYear) as timeFormat
    FROM ranked_media
    WHERE rn = 1
    ORDER BY createAtYear DESC, createAtMonth DESC;
END $$


-- ==============================================================================
-- Find medias for All display in database

DROP PROCEDURE IF EXISTS StreamMediaYearMonth;
CREATE PROCEDURE StreamMediaYearMonth(
    IN inputMonth INT,
    IN inputYear INT,
    IN offsetInput INT,
    IN limitInput INT
)
BEGIN
    SELECT * FROM PhotoView
    WHERE (inputYear = 0 OR YEAR(CreateDate) = inputYear)
        AND (inputMonth = 0 OR MONTH(CreateDate) = inputMonth)
    ORDER BY CreateDate DESC
    LIMIT offsetInput, limitInput;
END$$