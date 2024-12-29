USE Photos;

INSERT INTO ServerSystem (uuid, license_key)
VALUES
('123e4567-e89b-12d3-a456-426614174000', 'XXXX-YYYY-ZZZZ-AAAA');


INSERT INTO AIModel (ai_model_id, source_path, model, cmd, description, server_system)
VALUES
(1, '/models/classify', 'classify', 'run_classify.sh', 'Classification model', '123e4567-e89b-12d3-a456-426614174000'),
(2, '/models/detect', 'detect', 'run_detect.sh', 'Detection model', '123e4567-e89b-12d3-a456-426614174000'),
(3, '/models/segment', 'segment', 'run_segment.sh', 'Segmentation model', '123e4567-e89b-12d3-a456-426614174000');


INSERT INTO UserGuest (user_email, user_name, request_status, request_at)
VALUES
('user1@example.com', 'Alice Smith',  1, NOW()),
('jane.smith@example.com', 'Jane Smith', 0, NULL),
('john.doe@example.com', 'Carol Williams', 0, NULL);

INSERT INTO Account (user_email, created_at, status, password, role_type, m2f_isEnable)
VALUES
('user1@example.com', NOW(), 'active', 'password1', 'admin', 0),
('jane.smith@example.com', NOW(), 'active', 'password2', 'user', 1),
('john.doe@example.com', NOW(), 'suspended', 'password3', 'user', 1);


-- INSERT INTO ErrorLog ( server_system, error_msg, stack_trace, error_type, logged_at)
-- VALUES
--     ('123e4567-e89b-12d3-a456-426614174000', 'Authentication failure due to invalid token', 'InvalidTokenException: Token expired', 'backend','2024-12-12 12:15:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Frontend JS error when loading home page', 'TypeError: Cannot read property of null', 'frontend','2024-12-11 19:00:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'SQL syntax error in the query', 'SQLException: Incorrect syntax near "SELECT"', 'database','2024-12-11 08:45:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Memory leak detected in image processing service', 'OutOfMemoryError: Java heap space', 'backend','2024-12-10 21:30:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Missing image file in the frontend component', 'FileNotFoundError: image.jpg not found', 'frontend','2024-12-10 22:00:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Database deadlock detected', 'SQLDeadlockException: Timeout due to lock', 'database','2024-12-12 14:45:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Null pointer exception in backend service', 'at PhotosService.java:112', 'backend','2024-12-12 10:10:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Database connection timeout', 'SQLTimeoutException: Timeout after 30 seconds', 'database','2024-12-11 14:20:00'),
--     ('123e4567-e89b-12d3-a456-426614174000', 'Frontend UI rendering error', 'Uncaught TypeError: Cannot read property of undefined', 'frontend','2024-12-10 09:50:00');

-- INSERT INTO CameraType (camera_id, Make, Model, LensModel)
-- VALUES
-- (1, 'Canon', 'EOS R5', '24-70mm'),
-- (2, 'Sony', 'A7 III', '50mm'),
-- (3, 'Nikon', 'D850', '35mm');


-- INSERT INTO Media (FileType, FileName, CreateDate, FileSize, HashCode, URL, Privacy, Hidden, FavoriteCount, DeletedStatus, DeletionDate, Restricted, Software, CameraType, TimeUpload, FileExt)
-- VALUES
-- ('Photo', 'sunset.jpg', '2024-12-01 18:30:00', 204800, 'abc123hashcode', 'http://example.com/sunset.jpg', 1, 0, 100, 0, NULL, 0, 'Adobe Photoshop', 1, '2024-12-01 18:30:00', 'jpg'),
-- ('Video', 'holiday_trip.mp4', '2024-11-20 09:00:00', 50000000, 'def456hashcode', 'http://example.com/holiday_trip.mp4', 0, 1, 50, 0, NULL, 0, 'Final Cut Pro', 2, '2024-11-20 09:00:00', 'mp4'),
-- ('Live', 'concert_stream.m3u8', '2024-12-01 20:00:00', 1500000, 'ghi789hashcode', 'http://example.com/concert_stream.m3u8', 1, 0, 200, 0, NULL, 0, 'OBS Studio', 3, '2024-12-01 20:00:00', 'm3u8'),
-- ('Photo', 'portrait.jpg', '2024-11-15 14:00:00', 102400, 'abc123hashcode', 'http://example.com/portrait.jpg', 0, 0, 25, 0, NULL, 0, 'Lightroom', 1, '2024-11-15 14:00:00', 'jpg'),
-- ('Video', 'documentary.mp4', '2024-10-10 12:30:00', 80000000, 'jkl012hashcode', 'http://example.com/documentary.mp4', 0, 0, 10, 0, NULL, 0, 'Adobe Premiere', 2, '2024-10-10 12:30:00', 'mp4'),
-- ('Photo', 'nature_walk.jpg', '2024-12-01 08:45:00', 150000, 'lkj456hashcode', 'http://example.com/nature_walk.jpg', 0, 1, 75, 0, NULL, 0, 'Snapseed', 1, '2024-12-01 08:45:00', 'jpg'),
-- ('Photo', 'sunset_beach.jpg', '2024-11-28 18:20:00', 120000, 'abc123hashcode', 'http://example.com/sunset_beach.jpg', 1, 0, 120, 0, NULL, 1, 'Lightroom', 2, '2024-11-28 18:22:00', 'jpg'),
-- ('Live', 'workout_routine.mp4', '2024-11-15 10:00:00', 250000000, 'r4s5t6u7v8w9x0y1', 'http://example.com/workout_routine.mp4', 0, 0, 200, 0, NULL, 0, 'Final Cut Pro', 2, '2024-11-15 10:05:00', 'mp4'),
-- ('Photo', 'portrait_woman.jpg', '2024-12-01 08:00:00', 180000, 'ghi789hashcode', 'http://example.com/portrait_woman.jpg', 0, 0, 250, 0, NULL, 1, 'VSCO', 3, '2024-12-01 08:05:00', 'jpg');


-- INSERT INTO SourceFile (media, MIMEType, SourceFile)
-- VALUES
-- (1, 'image/jpeg', '/images/2024/summer_vacation/photo1.jpg'),
-- (2, 'image/png', '/images/2024/winter_trip/snowman.png'),
-- (3, 'video/mp4', '/videos/2024/family_reunion/highlights.mp4'),
-- (4, 'image/gif', '/gifs/2024/animations/funny_cat.gif'),
-- (5, 'audio/mpeg', '/audio/2024/podcasts/episode10.mp3');


-- INSERT INTO UploadBy (account, media)
-- VALUES
-- (1, 1), 
-- (2, 4), 
-- (3, 2), 
-- (1, 3),
-- (3, 5),
-- (2, 6),
-- (1, 7),
-- (3, 8),
-- (2, 9);


-- INSERT INTO Album (album_id, account, title)
-- VALUES
-- (1, 1, 'Holiday Album'),
-- (2, 2, 'Birthday Album'),
-- (3, 3, 'Concert Album'),
-- (4, 1, 'Vacation Album'),
-- (5, 2, 'Wedding Album'),
-- (6, 3, 'Family Album');


-- INSERT INTO UserLog (UserGuest, user_device, last_url_request, last_logged_in, ip_address, logged_at, user_log_id)
-- VALUES 
--     (1, 'MacBook Pro', '/dashboard', '2024-12-12 11:00:00', '192.168.1.4', '2024-12-12 11:05:00', 1004),
--     (2, 'Google Pixel 6', '/search', '2024-12-11 16:20:00', '192.168.1.5', '2024-12-11 16:25:00', 1005),
--     (2, 'Linux Server', '/admin', '2024-12-10 17:30:00', '192.168.1.6', '2024-12-10 17:35:00', 1006),
--     (1, 'iPad Pro', '/cart', '2024-12-12 14:15:00', '192.168.1.7', '2024-12-12 14:20:00', 1007),
--     (3, 'OnePlus 9', '/checkout', '2024-12-11 18:00:00', '192.168.1.8', '2024-12-11 18:05:00', 1008),
--     (1, 'Windows 11', '/wishlist', '2024-12-12 09:00:00', '192.168.1.9', '2024-12-12 09:05:00', 1009);



-- INSERT INTO AlbumMedia (album, media, caption)
-- VALUES
-- (1, 1, "Test"),
-- (2, 2, "Test"),
-- (3, 3, "Text"),
-- (1, 5, "Beautiful day"),
-- (2, 4, "New day"),
-- (3, 4, "Test");


-- INSERT INTO AiClass (class_id, ClassName)
-- VALUES
-- (1, 'Person'),
-- (2, 'Event'),
-- (3, 'Outdoor'),
-- (4, 'Animal'),
-- (5, 'Landscape'),
-- (6, 'Urban'),
-- (7, 'Portrait'),
-- (8, 'Nature'),
-- (9, 'Sports'),
-- (10, 'Food'),
-- (11, 'Abstract'),
-- (12, 'Interior');



-- INSERT INTO AiRecognition (ai_recognition_id, media, AiClass, AiMode)
-- VALUES
-- (1, 1, 1, 'Detect'),
-- (2, 1, 1, 'Classify'),
-- (3, 2, 2, 'Detect'),
-- (4, 3, 4, 'Detect'),
-- (5, 1, 5, 'Segment'),
-- (6, 2, 9, 'Segment'),
-- (7, 2, 9, 'Classify'),
-- (8, 5, 12, 'Segment'),
-- (9, 4, 4, 'Detect'),
-- (10, 3, 5, 'Classify'),
-- (11, 8, 3, 'Segment'),
-- (12, 5, 1, 'Detect');


-- INSERT INTO Classify (classify_id, ai_recognition, confidence)
-- VALUES
-- (1, 2, 0.95),
-- (2, 7, 0.80),
-- (3, 10, 0.90);


-- INSERT INTO Detect (detection_id, ai_recognition, confidence, b_box)
-- VALUES
-- (1, 1, 0.98, '{"x": 0.1, "y": 0.2, "w": 0.5, "h": 0.6}'),
-- (2, 3, 0.85, '{"x": 0.2, "y": 0.3, "w": 0.4, "h": 0.5}'),
-- (3, 4, 0.90, '{"x": 0.3, "y": 0.4, "w": 0.3, "h": 0.3}'),
-- (4, 9, 0.91, '{"x": 0.15, "y": 0.25, "w": 0.45, "h": 0.55}'),
-- (5, 12, 0.86, '{"x": 0.25, "y": 0.35, "w": 0.40, "h": 0.50}');

-- INSERT INTO Segment (segment_id, ai_recognition, confidence, b_box)
-- VALUES
-- (1, 5, 0.95, '{"x":100, "y":150, "width":50, "height":60}'), 
-- (2, 6, 0.85, '{"x":200, "y":250, "width":75, "height":80}'), 
-- (3, 8, 0.78, '{"x":300, "y":350, "width":60, "height":90}'), 
-- (4, 11, 0.65, '{"x":400, "y":450, "width":85, "height":100}'); 

-- INSERT INTO Favorite (account, media, status)
-- VALUES
-- (1, 1, 1),
-- (2, 5, 1),
-- (3, 3, 0),
-- (1, 8, 1),
-- (2, 2, 0);

-- INSERT INTO Comment (comment_id, account, media, content)
-- VALUES
-- (1, 2, 1, 'Happy birthday!'),
-- (2, 3, 3, 'Amazing Photogapth!'),
-- (3, 1, 4, 'Beautiful photo!'),
-- (4, 1, 5, 'Stunning shot!'),
-- (5, 1, 6, 'What a view!'),
-- (6, 2, 2, 'Love this scene!');

-- INSERT INTO Location (media, City, State, Country, GPSLatitude, GPSLongitude)
-- VALUES
-- (1, 'Paris', 'Île-de-France', 'France', '2.3522', '48.8566'),
-- (2, 'New York', 'NY', 'USA', '-74.0060', '40.7128'),
-- (3, 'Tokyo', 'Tokyo', 'Japan', '139.6917', '35.6895'),
-- (4, 'London', 'Greater London', 'UK', '-0.1276', '51.5074'),
-- (5, 'Berlin', 'Berlin', 'Germany', '13.4050', '52.5200'),
-- (6, 'Sydney', 'New South Wales', 'Australia', '151.2093', '-33.8688');

-- INSERT INTO Thumbnail (media, ThumbWidth, ThumbHeight, UrlThumb)
-- VALUES
-- (1, 150, 100, '/thumbnails/image1_thumb.jpg'),
-- (2, 160, 120, '/thumbnails/image2_thumb.jpg'),
-- (3, 200, 150, '/thumbnails/image3_thumb.jpg'),
-- (4, 120, 90, '/thumbnails/image4_thumb.jpg'),
-- (5, 180, 120, '/thumbnails/image5_thumb.jpg'),
-- (6, 170, 130, '/thumbnails/image6_thumb.jpg'),
-- (7, 100, 100, '/thumbnails/image7_thumb.jpg');


-- INSERT INTO Live (media, FrameCount, CurrentFrame, Duration, Title)
-- VALUES
-- (1, 500, 1, 25, 'Sunset Timelapse'),
-- (2, 1000, 300, 50, 'Sport Highlights'),
-- (3, 150, 10, 15, 'Live Music Clip');


-- INSERT INTO Video (media, Duration, Title, DisplayDuration)
-- VALUES
-- (4, 120.5, 'Holiday Highlights', '2:00'),
-- (5, 300.0, 'Nature Documentary', '5:00'),
-- (6, 15.0, 'Funny Clip', '0:15');

-- INSERT INTO Photo (media, ai_created, Orientation, ImageWidth, ImageHeight, Megapixels)
-- VALUES
-- (7, 0, 'Landscape', 1920, 1080, 2.1),
-- (8, 1, 'Portrait', 1080, 1920, 2.1),
-- (9, 0, 'Square', 1080, 1080, 1.2);

 