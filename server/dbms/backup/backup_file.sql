-- MySQL dump 10.13  Distrib 9.2.0, for macos14.7 (x86_64)
--
-- Host: localhost    Database: Photos
-- ------------------------------------------------------
-- Server version	9.2.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Account`
--

DROP TABLE IF EXISTS `Account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Account` (
  `account_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `user_email` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('active','suspended','deleted') NOT NULL DEFAULT 'active',
  `password` varchar(255) NOT NULL,
  `role_type` enum('user','admin') NOT NULL,
  `m2f_isEnable` tinyint(1) NOT NULL DEFAULT '0',
  `public_key` blob,
  PRIMARY KEY (`account_id`),
  KEY `PKFK_ACCOUNT_USER_EMAIL` (`user_email`),
  CONSTRAINT `PKFK_ACCOUNT_USER_EMAIL` FOREIGN KEY (`user_email`) REFERENCES `UserGuest` (`user_email`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Account`
--

LOCK TABLES `Account` WRITE;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
/*!40000 ALTER TABLE `Account` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`db_gallery`@`localhost`*/ /*!50003 TRIGGER `Account_BEFORE_INSERT` BEFORE INSERT ON `account` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `AiClass`
--

DROP TABLE IF EXISTS `AiClass`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AiClass` (
  `class_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ClassName` varchar(50) NOT NULL,
  `Created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Modified` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`class_id`),
  UNIQUE KEY `ClassName_UNIQUE` (`ClassName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AiClass`
--

LOCK TABLES `AiClass` WRITE;
/*!40000 ALTER TABLE `AiClass` DISABLE KEYS */;
/*!40000 ALTER TABLE `AiClass` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `AIModel`
--

DROP TABLE IF EXISTS `AIModel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AIModel` (
  `ai_model_id` int unsigned NOT NULL AUTO_INCREMENT,
  `source_path` text NOT NULL,
  `model` enum('classify','detect','segment') NOT NULL,
  `cmd` text NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `server_system` varchar(36) NOT NULL,
  PRIMARY KEY (`ai_model_id`),
  KEY `FK_AiMODEL_SERVERSYS_ID_idx` (`server_system`),
  CONSTRAINT `FK_AiMODEL_SERVERSYS_ID` FOREIGN KEY (`server_system`) REFERENCES `ServerSystem` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AIModel`
--

LOCK TABLES `AIModel` WRITE;
/*!40000 ALTER TABLE `AIModel` DISABLE KEYS */;
/*!40000 ALTER TABLE `AIModel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `AiRecognition`
--

DROP TABLE IF EXISTS `AiRecognition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AiRecognition` (
  `ai_recognition_id` int unsigned NOT NULL AUTO_INCREMENT,
  `media` int unsigned NOT NULL,
  `AiClass` int unsigned NOT NULL,
  `AiMode` enum('Detect','Classify','Segment','Face') NOT NULL,
  PRIMARY KEY (`ai_recognition_id`),
  UNIQUE KEY `UNIQUE_MEDIA_CLASS_MODE` (`media`,`AiClass`,`AiMode`),
  KEY `PKFK_AIRECOGNITION_AICLASS_ID_idx` (`AiClass`),
  CONSTRAINT `PKFK_AIMEDIALABEL_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `PKFK_AIRECOGNITION_AICLASS_ID` FOREIGN KEY (`AiClass`) REFERENCES `AiClass` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AiRecognition`
--

LOCK TABLES `AiRecognition` WRITE;
/*!40000 ALTER TABLE `AiRecognition` DISABLE KEYS */;
/*!40000 ALTER TABLE `AiRecognition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Album`
--

DROP TABLE IF EXISTS `Album`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Album` (
  `album_id` int unsigned NOT NULL AUTO_INCREMENT,
  `account` smallint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `title` varchar(50) DEFAULT NULL,
  `modify_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`album_id`),
  UNIQUE KEY `title_UNIQUE` (`title`),
  KEY `FK_ALBUM_ACCOUNT_ID_idx` (`account`),
  CONSTRAINT `FK_ALBUM_ACCOUNT_ID` FOREIGN KEY (`account`) REFERENCES `Account` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Album`
--

LOCK TABLES `Album` WRITE;
/*!40000 ALTER TABLE `Album` DISABLE KEYS */;
/*!40000 ALTER TABLE `Album` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `AlbumMedia`
--

DROP TABLE IF EXISTS `AlbumMedia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AlbumMedia` (
  `album` int unsigned NOT NULL,
  `media` int unsigned NOT NULL,
  PRIMARY KEY (`album`,`media`),
  KEY `FK_ALBUMMEDIA_MEDIA_ID_idx` (`media`),
  CONSTRAINT `PKFK_ALBUMMEDIA_ALBUM_ID` FOREIGN KEY (`album`) REFERENCES `Album` (`album_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `PKFK_ALBUMMEDIA_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AlbumMedia`
--

LOCK TABLES `AlbumMedia` WRITE;
/*!40000 ALTER TABLE `AlbumMedia` DISABLE KEYS */;
/*!40000 ALTER TABLE `AlbumMedia` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CameraType`
--

DROP TABLE IF EXISTS `CameraType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CameraType` (
  `camera_id` int unsigned NOT NULL AUTO_INCREMENT,
  `Make` varchar(50) DEFAULT NULL,
  `Model` varchar(100) DEFAULT NULL,
  `LensModel` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`camera_id`),
  KEY `CameraType_Idx` (`Make`,`Model`,`LensModel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CameraType`
--

LOCK TABLES `CameraType` WRITE;
/*!40000 ALTER TABLE `CameraType` DISABLE KEYS */;
/*!40000 ALTER TABLE `CameraType` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Classify`
--

DROP TABLE IF EXISTS `Classify`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Classify` (
  `classify_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ai_recognition` int unsigned NOT NULL,
  `confidence` decimal(18,17) NOT NULL,
  PRIMARY KEY (`classify_id`),
  KEY `PKFK_CLASSIFY_AiRECOG_ID_idx` (`ai_recognition`),
  CONSTRAINT `PKFK_CLASSIFY_AiRECOG_ID` FOREIGN KEY (`ai_recognition`) REFERENCES `AiRecognition` (`ai_recognition_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Classify`
--

LOCK TABLES `Classify` WRITE;
/*!40000 ALTER TABLE `Classify` DISABLE KEYS */;
/*!40000 ALTER TABLE `Classify` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Detect`
--

DROP TABLE IF EXISTS `Detect`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Detect` (
  `detection_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ai_recognition` int unsigned NOT NULL,
  `confidence` decimal(18,17) NOT NULL,
  `b_box` json NOT NULL,
  PRIMARY KEY (`detection_id`),
  KEY `PKFK_DETECT_AiRECOG_ID_idx` (`ai_recognition`),
  CONSTRAINT `PKFK_DETECT_AiRECOG_ID` FOREIGN KEY (`ai_recognition`) REFERENCES `AiRecognition` (`ai_recognition_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Detect`
--

LOCK TABLES `Detect` WRITE;
/*!40000 ALTER TABLE `Detect` DISABLE KEYS */;
/*!40000 ALTER TABLE `Detect` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ErrorLog`
--

DROP TABLE IF EXISTS `ErrorLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ErrorLog` (
  `error_log_id` int unsigned NOT NULL AUTO_INCREMENT,
  `error_msg` text NOT NULL,
  `stack_trace` text,
  `error_type` enum('frontend','backend','database') DEFAULT NULL,
  `server_system` varchar(36) DEFAULT NULL,
  `logged_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`error_log_id`),
  KEY `FK_ERRORLOG_SYSTEM_ID_idx` (`server_system`),
  KEY `ErrorLog_Logged_ErrorType_idx` (`logged_at`,`error_type`),
  CONSTRAINT `FK_ERRORLOG_SYSTEM_ID` FOREIGN KEY (`server_system`) REFERENCES `ServerSystem` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ErrorLog`
--

LOCK TABLES `ErrorLog` WRITE;
/*!40000 ALTER TABLE `ErrorLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `ErrorLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Face`
--

DROP TABLE IF EXISTS `Face`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Face` (
  `face_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ai_recognition` int unsigned NOT NULL,
  `confidence` decimal(18,17) NOT NULL,
  `b_box` json NOT NULL,
  PRIMARY KEY (`face_id`),
  KEY `PKFK_FACE_AiRECOG_ID_idx` (`ai_recognition`),
  CONSTRAINT `PKFK_FACE_AiRECOG_ID0` FOREIGN KEY (`ai_recognition`) REFERENCES `AiRecognition` (`ai_recognition_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Face`
--

LOCK TABLES `Face` WRITE;
/*!40000 ALTER TABLE `Face` DISABLE KEYS */;
/*!40000 ALTER TABLE `Face` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ImportMedias`
--

DROP TABLE IF EXISTS `ImportMedias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImportMedias` (
  `import_id` int unsigned NOT NULL AUTO_INCREMENT,
  `FileName` text,
  `FileType` varchar(50) DEFAULT NULL,
  `MIMEType` varchar(50) DEFAULT NULL,
  `Software` varchar(255) DEFAULT NULL,
  `Title` varchar(255) DEFAULT NULL,
  `FileSize` bigint unsigned DEFAULT NULL,
  `Make` varchar(100) DEFAULT NULL,
  `Model` varchar(100) DEFAULT NULL,
  `LensModel` varchar(255) DEFAULT NULL,
  `Orientation` varchar(50) DEFAULT NULL,
  `CreateDate` varchar(20) DEFAULT NULL,
  `DateCreated` varchar(20) DEFAULT NULL,
  `CreationDate` varchar(20) DEFAULT NULL,
  `DateTimeOriginal` varchar(20) DEFAULT NULL,
  `FileModifyDate` varchar(20) DEFAULT NULL,
  `MediaCreateDate` varchar(20) DEFAULT NULL,
  `MediaModifyDate` varchar(20) DEFAULT NULL,
  `Duration` double DEFAULT NULL,
  `GPSLatitude` double DEFAULT NULL,
  `GPSLongitude` double DEFAULT NULL,
  `ImageWidth` smallint unsigned DEFAULT NULL,
  `ImageHeight` smallint unsigned DEFAULT NULL,
  `SourceFile` text,
  `Megapixels` decimal(5,2) DEFAULT NULL,
  `account` smallint unsigned NOT NULL,
  PRIMARY KEY (`import_id`),
  KEY `FK_IMPORTMEDIAS_ACCOUNT_ID_idx` (`account`),
  CONSTRAINT `FK_IMPORTMEDIAS_ACCOUNT_ID` FOREIGN KEY (`account`) REFERENCES `Account` (`account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ImportMedias`
--

LOCK TABLES `ImportMedias` WRITE;
/*!40000 ALTER TABLE `ImportMedias` DISABLE KEYS */;
/*!40000 ALTER TABLE `ImportMedias` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`db_gallery`@`localhost`*/ /*!50003 TRIGGER `ImportMedias_AFTER_INSERT` AFTER INSERT ON `importmedias` FOR EACH ROW BEGIN
    DECLARE mimeTypePrefix VARCHAR(10);
    DECLARE smallestDate DATETIME; -- To store the smallest date if have any
    DECLARE cameraTypeId INT; -- Camera ID if have any
    DECLARE durationDisplay VARCHAR(10); -- Display duration time for videos
    DECLARE mediaType ENUM('Photo', 'Video', 'Live', 'Unknown');
    DECLARE lastInsertMediaID INT;
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
    SET thumbnailName = CONCAT(
        CAST(NEW.import_id AS CHAR),
        SUBSTRING(REPLACE(UUID(), '-', ''), 1, 15 - LENGTH(CAST(NEW.import_id AS CHAR)))
    );

    -- Insert into Media table
    INSERT INTO Media (FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, SourceFile, MIMEType, ThumbPath) 
        VALUES (NEW.FileName, mediaType, NEW.FileType, NEW.Software, NEW.FileSize, cameraTypeId,
        STR_TO_DATE(smallestDate, '%Y-%m-%d %H:%i:%s'), NEW.SourceFile, NEW.MIMEType,
        CONCAT('/Thumbnails/', YEAR(smallestDate), '/', DATE_FORMAT(smallestDate, '%M'), '/', thumbnailName, '.webp')
    );

    -- Reuse this variable as media_id for the last Media inserted
    SET lastInsertMediaID = LAST_INSERT_ID();

    -- ///////////// NOTE ///////////////////
    -- The account number needs to be added when the user is created, so we can identify which user uploaded these media.
    INSERT INTO UploadBy (account, media) VALUES (NEW.account, lastInsertMediaID);

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
            VALUES (lastInsertMediaID, NEW.Orientation, NEW.ImageWidth, NEW.ImageHeight, ROUND(NEW.Megapixels, 1));
            
        WHEN mediaType = 'Video' THEN
            SET durationDisplay = CASE
                WHEN FLOOR(NEW.Duration / 3600) > 0 THEN CONCAT(FLOOR(NEW.Duration / 3600), ':', LPAD(FLOOR(NEW.Duration / 60) % 60, 2, '0'), ':', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
                WHEN FLOOR(NEW.Duration / 60) > 0 THEN CONCAT(FLOOR(NEW.Duration / 60), ':', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
                ELSE CONCAT('0:', LPAD(ROUND(NEW.Duration % 60), 2, '0'))
            END;
            INSERT INTO Video (media, Title, Duration, DisplayDuration) 
            VALUES (lastInsertMediaID, NEW.Title, NEW.Duration, durationDisplay);
            
        WHEN mediaType = 'Live' THEN
            INSERT INTO Live (media, Title, Duration) 
            VALUES (lastInsertMediaID, NEW.Title, NEW.Duration);
    END CASE;

    -- Handle GPS data
    IF NEW.GPSLatitude IS NOT NULL AND NEW.GPSLatitude != '' 
       AND NEW.GPSLongitude IS NOT NULL AND NEW.GPSLongitude != '' THEN
        INSERT INTO Location (media, GPSLatitude, GPSLongitude) 
        VALUES (lastInsertMediaID, NEW.GPSLatitude, NEW.GPSLongitude );
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Live`
--

DROP TABLE IF EXISTS `Live`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Live` (
  `media` int unsigned NOT NULL AUTO_INCREMENT,
  `FrameCount` int DEFAULT NULL,
  `CurrentFrame` smallint DEFAULT NULL,
  `Duration` int DEFAULT NULL,
  `Title` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_LIVE_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Live`
--

LOCK TABLES `Live` WRITE;
/*!40000 ALTER TABLE `Live` DISABLE KEYS */;
/*!40000 ALTER TABLE `Live` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Location`
--

DROP TABLE IF EXISTS `Location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Location` (
  `media` int unsigned NOT NULL,
  `City` varchar(50) DEFAULT NULL,
  `State` varchar(50) DEFAULT NULL,
  `Country` varchar(50) DEFAULT NULL,
  `GPSLatitude` double DEFAULT NULL,
  `GPSLongitude` double DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_LOCATION_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Location`
--

LOCK TABLES `Location` WRITE;
/*!40000 ALTER TABLE `Location` DISABLE KEYS */;
/*!40000 ALTER TABLE `Location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Media`
--

DROP TABLE IF EXISTS `Media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Media` (
  `media_id` int unsigned NOT NULL AUTO_INCREMENT,
  `FileType` enum('Photo','Video','Live','Unknown') NOT NULL,
  `FileName` text,
  `CreateDate` datetime DEFAULT NULL,
  `FileSize` bigint unsigned DEFAULT NULL,
  `HashCode` varchar(65) DEFAULT NULL,
  `Hidden` tinyint unsigned DEFAULT '0',
  `Favorite` tinyint unsigned DEFAULT '0',
  `DeletedStatus` tinyint unsigned DEFAULT '0',
  `DeletionDate` timestamp NULL DEFAULT NULL,
  `CameraType` int unsigned DEFAULT NULL,
  `UploadAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `FileExt` varchar(10) DEFAULT NULL,
  `Software` varchar(256) DEFAULT NULL,
  `SourceFile` text,
  `MIMEType` varchar(50) DEFAULT NULL,
  `ThumbPath` text,
  `ThumbWidth` smallint DEFAULT NULL,
  `ThumbHeight` smallint DEFAULT NULL,
  PRIMARY KEY (`media_id`),
  KEY `Media_CreateDate_idx` (`CreateDate`,`FileType`),
  KEY `FK_MEDIA_SOURCEFILE_ID_idx` (`CameraType`),
  CONSTRAINT `FK_MEDIA_CAMERATYPE_ID` FOREIGN KEY (`CameraType`) REFERENCES `CameraType` (`camera_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Media`
--

LOCK TABLES `Media` WRITE;
/*!40000 ALTER TABLE `Media` DISABLE KEYS */;
/*!40000 ALTER TABLE `Media` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`db_gallery`@`localhost`*/ /*!50003 TRIGGER `Media_BEFORE_UPDATE` BEFORE UPDATE ON `media` FOR EACH ROW BEGIN

    -- Set DeletionDate to NOW() if DeletedStatus changes to 1, otherwise set to NULL
    IF OLD.DeletedStatus <> NEW.DeletedStatus THEN
        SET NEW.DeletionDate = IF(NEW.DeletedStatus = 1, NOW(), NULL);
        
        IF NEW.Favorite = 1 THEN
            SET NEW.Favorite = 0;
        END IF;
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Photo`
--

DROP TABLE IF EXISTS `Photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Photo` (
  `media` int unsigned NOT NULL,
  `Orientation` varchar(45) DEFAULT NULL,
  `ImageWidth` smallint DEFAULT NULL,
  `ImageHeight` smallint DEFAULT NULL,
  `Megapixels` double DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_PHOTO_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Photo`
--

LOCK TABLES `Photo` WRITE;
/*!40000 ALTER TABLE `Photo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Photo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `photoview`
--

DROP TABLE IF EXISTS `photoview`;
/*!50001 DROP VIEW IF EXISTS `photoview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `photoview` AS SELECT 
 1 AS `media_id`,
 1 AS `FileType`,
 1 AS `FileName`,
 1 AS `FileSize`,
 1 AS `CreateDate`,
 1 AS `UploadAt`,
 1 AS `ThumbPath`,
 1 AS `SourceFile`,
 1 AS `isFavorite`,
 1 AS `isHidden`,
 1 AS `isDeleted`,
 1 AS `CameraType`,
 1 AS `HashCode`,
 1 AS `timeFormat`,
 1 AS `duration`,
 1 AS `videoTitle`,
 1 AS `MIMEType`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `Segment`
--

DROP TABLE IF EXISTS `Segment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Segment` (
  `segment_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ai_recognition` int unsigned NOT NULL,
  `confidence` decimal(18,17) NOT NULL,
  `b_box` json NOT NULL,
  PRIMARY KEY (`segment_id`),
  KEY `PKFK_SEGMENT_AiRECOG_ID_idx` (`ai_recognition`),
  CONSTRAINT `PKFK_SEGMENT_AiRECOG_ID` FOREIGN KEY (`ai_recognition`) REFERENCES `AiRecognition` (`ai_recognition_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Segment`
--

LOCK TABLES `Segment` WRITE;
/*!40000 ALTER TABLE `Segment` DISABLE KEYS */;
/*!40000 ALTER TABLE `Segment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ServerSystem`
--

DROP TABLE IF EXISTS `ServerSystem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ServerSystem` (
  `uuid` varchar(36) NOT NULL DEFAULT 'UUID()',
  `license_key` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ServerSystem`
--

LOCK TABLES `ServerSystem` WRITE;
/*!40000 ALTER TABLE `ServerSystem` DISABLE KEYS */;
/*!40000 ALTER TABLE `ServerSystem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TempAiTags`
--

DROP TABLE IF EXISTS `TempAiTags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TempAiTags` (
  `ai_tag_id` int unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int unsigned DEFAULT NULL,
  `class_name` varchar(50) NOT NULL,
  `b_box` json DEFAULT NULL,
  `confidence` decimal(18,17) NOT NULL,
  `media_id` int unsigned NOT NULL,
  `ai_model` varchar(10) DEFAULT NULL,
  `System` char(36) DEFAULT NULL,
  PRIMARY KEY (`ai_tag_id`),
  KEY `FK_SYSTEMLOG_SERVER_ID_idx` (`System`),
  CONSTRAINT `FK_SYSTEMLOG_SERVER_ID0` FOREIGN KEY (`System`) REFERENCES `ServerSystem` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TempAiTags`
--

LOCK TABLES `TempAiTags` WRITE;
/*!40000 ALTER TABLE `TempAiTags` DISABLE KEYS */;
/*!40000 ALTER TABLE `TempAiTags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `UploadBy`
--

DROP TABLE IF EXISTS `UploadBy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UploadBy` (
  `account` smallint unsigned NOT NULL,
  `media` int unsigned NOT NULL,
  `uploaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`media`,`account`),
  KEY `PKFK_UPLOADBY_ACCOUNT_ID_idx` (`account`),
  CONSTRAINT `PKFK_UPLOADBY_ACCOUNT_ID` FOREIGN KEY (`account`) REFERENCES `Account` (`account_id`) ON UPDATE CASCADE,
  CONSTRAINT `PKFK_UPLOADBY_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `UploadBy`
--

LOCK TABLES `UploadBy` WRITE;
/*!40000 ALTER TABLE `UploadBy` DISABLE KEYS */;
/*!40000 ALTER TABLE `UploadBy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `UserGuest`
--

DROP TABLE IF EXISTS `UserGuest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UserGuest` (
  `user_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `user_email` varchar(50) NOT NULL,
  `user_name` varchar(40) NOT NULL,
  `request_status` tinyint unsigned DEFAULT NULL,
  `request_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email_UNIQUE` (`user_email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `UserGuest`
--

LOCK TABLES `UserGuest` WRITE;
/*!40000 ALTER TABLE `UserGuest` DISABLE KEYS */;
INSERT INTO `UserGuest` VALUES (1,'guasdaaesaasdaaat@Hwllo.com','Guest ASHD User',NULL,NULL);
/*!40000 ALTER TABLE `UserGuest` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `UserLog`
--

DROP TABLE IF EXISTS `UserLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UserLog` (
  `UserGuest` smallint unsigned DEFAULT NULL,
  `user_device` varchar(255) DEFAULT NULL,
  `last_url_request` varchar(200) DEFAULT NULL,
  `last_logged_in` timestamp NULL DEFAULT NULL,
  `ip_address` varchar(45) NOT NULL,
  `logged_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `user_log_id` int unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`user_log_id`),
  KEY `FK_USERLOG_USER_ID` (`UserGuest`),
  CONSTRAINT `FK_USERLOG_USER_ID` FOREIGN KEY (`UserGuest`) REFERENCES `UserGuest` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `UserLog`
--

LOCK TABLES `UserLog` WRITE;
/*!40000 ALTER TABLE `UserLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `UserLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Video`
--

DROP TABLE IF EXISTS `Video`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Video` (
  `media` int unsigned NOT NULL,
  `Duration` double DEFAULT NULL,
  `Title` varchar(255) DEFAULT NULL,
  `DisplayDuration` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_VIDEO_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Video`
--

LOCK TABLES `Video` WRITE;
/*!40000 ALTER TABLE `Video` DISABLE KEYS */;
/*!40000 ALTER TABLE `Video` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `photoview`
--

/*!50001 DROP VIEW IF EXISTS `photoview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`db_gallery`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `photoview` AS select `im`.`media_id` AS `media_id`,`im`.`FileType` AS `FileType`,`im`.`FileName` AS `FileName`,`im`.`FileSize` AS `FileSize`,`im`.`CreateDate` AS `CreateDate`,`im`.`UploadAt` AS `UploadAt`,`im`.`ThumbPath` AS `ThumbPath`,`im`.`SourceFile` AS `SourceFile`,`im`.`Favorite` AS `isFavorite`,`im`.`Hidden` AS `isHidden`,`im`.`DeletedStatus` AS `isDeleted`,`im`.`CameraType` AS `CameraType`,`im`.`HashCode` AS `HashCode`,concat(date_format(`im`.`CreateDate`,'%b'),' ',dayofmonth(`im`.`CreateDate`),', ',year(`im`.`CreateDate`)) AS `timeFormat`,`v`.`DisplayDuration` AS `duration`,`v`.`Title` AS `videoTitle`,`im`.`MIMEType` AS `MIMEType` from (`media` `im` left join `video` `v` on((`im`.`media_id` = `v`.`media`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-03-03 23:25:01
