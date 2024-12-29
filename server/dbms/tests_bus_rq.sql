-- Active: 1733972794606@@127.0.0.1@3306@Photos
USE Photos;

-- SELECT * FROM ImportMedias;

/* Business Requirement #1 */
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


/* Business Requirement #2 */
-- CALL SearchMedia(NULL, NULL, NULL, NULL, NULL, NULL, 'per', NULL, NULL, NULL, NULL);
-- CALL SearchMedia(NULL, NULL, 'Video', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
-- CALL SearchMedia(2024, 11, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
-- CALL SearchMedia(NULL, NULL, NULL, NULL, NULL, 'Tokyo', NULL, NULL, NULL, NULL, NULL);
 
CALL SearchMedia(
    NULL,        -- findYear
    NULL,           -- findMonth
    NULL,        -- findMediaType
    NULL,        -- findMake
    NULL,        -- findModel
    NULL,        -- findCity
    NULL,        -- findTag
    NULL,        -- sortBy
    NULL,        -- sortOrder
    NULL,           -- numberOfRecords
    NULL           -- pageNumber
);



/* Business Requirement #3 */
-- Example Usage:
-- CALL FetchMediaSummary(1, NULL); -- Fetch album summaries with default 10 records
-- CALL FetchMediaSummary(2, 20);   -- Fetch AI-detection labels with 20 records
-- CALL FetchMediaSummary(3, 15);   -- Fetch location-based media with 15 records
-- CALL FetchMediaSummary(4, NULL); -- Count media types


/* Business Requirement #4 */
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

/* Business Requirement #5 */

-- -- =============================
-- -- Testing: GetUserLogs Procedure
-- -- =============================
-- -- Test Case 1: Fetch all logs, sorted by 'LastLoggedIn', default pagination
-- CALL GetUserLogs(
--     'Ja', -- filterName 
--     NULL, -- filterEmail 
--     NULL, -- filterIp 
--     NULL, -- intervalDays
--     NULL, -- sortColumn 
--     NULL, -- sortOrder 
--     NULL -- pageNumber
-- )
-- -- Test Case 2: Filter by UserName and date range
-- CALL GetUserLogs( NULL, NULL, NULL, 5, 'LastLoggedIn', 'DECS', NULL);

-- -- =============================
-- -- Testing: GetErrorLogs Procedure
-- -- =============================
-- -- Test Case 1: Fetch all error logs, sorted by 'LoggedAt', default pagination
-- CALL GetErrorLogs(
--     'back', -- filterType 
--     NULL, -- intervalDays 
--     NULL, -- sortColumn
--     NULL, -- sortOrder
--     NULL -- pageNumber 
-- )

-- -- Test Case 2: Filter by error type (backend) and server UUID
-- CALL GetErrorLogs('backend', NULL, NULL, 'ASC', NULL);
