-- MySQL dump 10.13  Distrib 9.0.1, for macos14.7 (x86_64)
--
-- Host: localhost    Database: Photos
-- ------------------------------------------------------
-- Server version	9.0.1

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Account`
--

LOCK TABLES `Account` WRITE;
/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
INSERT INTO `Account` VALUES (1,'user1@example.com','2024-12-30 20:21:18','active','password1','admin',0,NULL),(2,'jane.smith@example.com','2024-12-30 20:21:18','active','password2','user',1,NULL),(3,'john.doe@example.com','2024-12-30 20:21:18','suspended','password3','user',1,NULL);
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
-- Temporary view structure for view `adminuserlogview`
--

DROP TABLE IF EXISTS `adminuserlogview`;
/*!50001 DROP VIEW IF EXISTS `adminuserlogview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `adminuserlogview` AS SELECT 
 1 AS `UserID`,
 1 AS `UserName`,
 1 AS `UserEmail`,
 1 AS `UserReq`,
 1 AS `IPAddress`,
 1 AS `UserDevice`,
 1 AS `LastURLRequest`,
 1 AS `LastLoggedIn`,
 1 AS `LastIP`,
 1 AS `LogTime`*/;
SET character_set_client = @saved_cs_client;

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AIModel`
--

LOCK TABLES `AIModel` WRITE;
/*!40000 ALTER TABLE `AIModel` DISABLE KEYS */;
INSERT INTO `AIModel` VALUES (1,'/models/classify','classify','run_classify.sh','Classification model','123e4567-e89b-12d3-a456-426614174000'),(2,'/models/detect','detect','run_detect.sh','Detection model','123e4567-e89b-12d3-a456-426614174000'),(3,'/models/segment','segment','run_segment.sh','Segmentation model','123e4567-e89b-12d3-a456-426614174000');
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
  CONSTRAINT `FK_ALBUM_ACCOUNT_ID` FOREIGN KEY (`account`) REFERENCES `Account` (`account_id`) ON UPDATE CASCADE
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
  KEY `FK_ALBUMMEDIA_ALBUM_ID_idx` (`album`),
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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CameraType`
--

LOCK TABLES `CameraType` WRITE;
/*!40000 ALTER TABLE `CameraType` DISABLE KEYS */;
INSERT INTO `CameraType` VALUES (1,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8'),(2,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 6mm f/2'),(4,'Apple','iPhone X','iPhone X back dual camera 4mm f/1.8'),(7,'Canon','Canon EOS 5D Mark II','EF17-40mm f/4L USM'),(5,'Canon','Canon EOS 5D Mark II','EF24-70mm f/2.8L USM'),(3,'Canon','Canon EOS 5D Mark II','TS-E17mm f/4L'),(6,'NIKON CORPORATION','NIKON D3100','10.0-20.0 mm f/3.5');
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
  `FileName` varchar(255) DEFAULT NULL,
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
  `SourceFile` varchar(1024) DEFAULT NULL,
  `Megapixels` decimal(5,2) DEFAULT NULL,
  `account` smallint unsigned NOT NULL,
  PRIMARY KEY (`import_id`),
  KEY `FK_IMPORTMEDIAS_ACCOUNT_ID_idx` (`account`),
  CONSTRAINT `FK_IMPORTMEDIAS_ACCOUNT_ID` FOREIGN KEY (`account`) REFERENCES `Account` (`account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=512 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ImportMedias`
--

LOCK TABLES `ImportMedias` WRITE;
/*!40000 ALTER TABLE `ImportMedias` DISABLE KEYS */;
INSERT INTO `ImportMedias` VALUES (1,'JFL-08072018-IMACS-MACBOOKS.png','PNG','image/png','','',3415073,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2994,1871,'/database/JFL-08072018-IMACS-MACBOOKS.png',5.60,1),(2,'72test.jpg','JPEG','image/jpeg','','',1066206,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1932,1280,'/database/72test.jpg',2.50,1),(3,'Jean-Alain_Foods_with_Love_YkVkRmY.jpg','JPEG','image/jpeg','','',266472,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/Jean-Alain_Foods_with_Love_YkVkRmY.jpg',2.50,1),(4,'video__2160p_.mp4','MP4','video/mp4','','',71070000,'','','','','2019-11-02T08:33:53','','','','2023-10-10T23:15:33','2019-11-02T08:33:53','2019-11-02T08:33:53',30,0,0,3840,2160,'/database/video__2160p_.mp4',8.30,1),(5,'2015-12-01_KenrokuenGarden_ROW11637035698_1920x1080.jpg','JPEG','image/jpeg','','',355238,'','','','','','','','','2016-02-03T07:43:40','','',0,0,0,1920,1080,'/database/2015-12-01_KenrokuenGarden_ROW11637035698_1920x1080.jpg',2.10,1),(6,'IMG_4788.HEIC','HEIC','image/heic','16.7','',1219043,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Rotate 90 CW','2023-10-04T12:49:08','','','2023-10-04T12:49:08','2023-10-04T12:49:24','','',0,37.7307888888889,-122.407355555556,4032,3024,'/database/IMG_4788.HEIC',12.20,1),(7,'33t_est.jpg','JPEG','image/jpeg','','',673745,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,2537,1280,'/database/33t_est.jpg',3.20,1),(8,'US_Navy_050102-N-9593M-040_A_village_near_the_coast_of_Sumatra_lays_in_ruin_after_the_Tsunami_that_struck_South_East_Asia.jpg','JPEG','image/jpeg','Adobe Photoshop CS Macintosh','050102-N-9593M-040',393164,'NIKON CORPORATION','NIKON D2H','','Horizontal (normal)','2005-01-02T01:29:55','2005-01-02T00:00:00','','2005-01-02T01:29:55','2023-09-18T18:43:56','','',0,0,0,2100,1500,'/database/US_Navy_050102-N-9593M-040_A_village_near_the_coast_of_Sumatra_lays_in_ruin_after_the_Tsunami_that_struck_South_East_Asia.jpg',3.10,1),(9,'pexels-nataliya-vaitkevich-8468210__1080p_.mp4','MP4','video/mp4','','',5615870,'','','','','2021-06-24T15:25:45','','','','2023-10-11T07:36:59','2021-06-24T15:25:45','2021-06-24T15:25:45',14.8333333333333,0,0,1080,1920,'/database/pexels-nataliya-vaitkevich-8468210__1080p_.mp4',2.10,1),(10,'Diego_Torres_Silvestre_Moonlight..._ZkVkRQ.jpg','JPEG','image/jpeg','','',199318,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1680,1260,'/database/Diego_Torres_Silvestre_Moonlight..._ZkVkRQ.jpg',2.10,1),(11,'93test.mp4','MP4','video/mp4','','',41435560,'','','','','2023-03-29T21:52:28','','','','2023-10-11T07:39:05','2023-03-29T21:52:28','2023-03-29T21:52:28',24.02,0,0,2560,1440,'/database/93test.mp4',3.70,1),(12,'diego_torres_London_City_YkVqQmU.jpg','JPEG','image/jpeg','','',909924,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/diego_torres_London_City_YkVqQmU.jpg',2.50,1),(13,'Matt_JP_Afternoon_Swim_ZENqRQ.jpg','JPEG','image/jpeg','','',373462,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1970,1280,'/database/Matt_JP_Afternoon_Swim_ZENqRQ.jpg',2.50,1),(14,'production_id_4779866__1080p_.mp4','MP4','video/mp4','','',3257706,'','','','','2020-07-02T19:36:22','','','','2023-10-10T23:14:33','2020-07-02T19:36:22','2020-07-02T19:36:22',5.005,0,0,1920,1080,'/database/production_id_4779866__1080p_.mp4',2.10,1),(15,'kali-layers-16x9.png','PNG','image/png','','',732875,'','','','','','','','','2022-03-20T01:22:26','','',0,0,0,3840,2160,'/database/kali-layers-16x9.png',8.30,1),(16,'_83_test.jpg','JPEG','image/jpeg','','',182363,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1917,1280,'/database/_83_test.jpg',2.50,1),(17,'Foto-Rabe_Gooses__dream_YkVqQmM.jpg','JPEG','image/jpeg','','',287602,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/Foto-Rabe_Gooses__dream_YkVqQmM.jpg',2.50,1),(18,'JulienDft_Photo_lock_a0RgRg.jpg','JPEG','image/jpeg','','',571537,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1920,1280,'/database/JulienDft_Photo_lock_a0RgRg.jpg',2.50,1),(19,'pexels-sunsetoned-5913482__2160p_.mp4','MP4','video/mp4','','',21104653,'','','','','2020-11-17T18:40:23','','','','2023-10-11T07:38:41','2020-11-17T18:40:23','2020-11-17T18:40:23',7.83333333333333,0,0,2160,3840,'/database/pexels-sunsetoned-5913482__2160p_.mp4',8.30,1),(20,'pexels-leeloo-thefirst-5379765.jpg','JPEG','image/jpeg','','',3284545,'','','','','','','','','2023-10-11T07:35:17','','',0,0,0,4016,6016,'/database/pexels-leeloo-thefirst-5379765.jpg',24.20,1),(21,'Mariah_Carey_-_All_I_Want_for_Christmas_Is_You__Make_My_Wish_Come_True_Edition_.mp4','MP4','video/mp4','','Mariah Carey - All I Want for Christmas Is You (Make My Wish Come True Edition)',89285777,'','','','','0000:00:00 00:00:00','','','','2023-12-10T15:27:38','0000:00:00 00:00:00','0000:00:00 00:00:00',242.928,0,0,1920,960,'/database/Mariah_Carey_-_All_I_Want_for_Christmas_Is_You__Make_My_Wish_Come_True_Edition_.mp4',1.80,1),(22,'Rough_Seas_-_MacBook_Pro_Wallpaper.jpg','JPEG','image/jpeg','','',924968,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/Rough_Seas_-_MacBook_Pro_Wallpaper.jpg',5.20,1),(23,'pexels-filipp-romanovski-17275905.jpg','JPEG','image/jpeg','','',4013440,'','','','','','','','','2023-10-11T07:36:00','','',0,0,0,5393,8086,'/database/pexels-filipp-romanovski-17275905.jpg',43.60,1),(24,'35test.jpg','JPEG','image/jpeg','','',600618,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1920,1280,'/database/35test.jpg',2.50,1),(25,'Gic_Shade_of_flowers_YkVlSGo.jpg','JPEG','image/jpeg','','',1083466,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1920,1280,'/database/Gic_Shade_of_flowers_YkVlSGo.jpg',2.50,1),(26,'me_nicoll_Pencil_ZUFjQg.jpg','JPEG','image/jpeg','','',241883,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1706,1280,'/database/me_nicoll_Pencil_ZUFjQg.jpg',2.20,1),(27,'Glacier_Falls_-_MacBook_Pro_Wallpaper.jpg','JPEG','image/jpeg','','',719566,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/Glacier_Falls_-_MacBook_Pro_Wallpaper.jpg',5.20,1),(28,'macOS-Sierra-Wallpaper-Macbook-Wallpaper.jpg','JPEG','image/jpeg','Pixelmator 3.4','',2130212,'','','','Horizontal (normal)','','','','','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/macOS-Sierra-Wallpaper-Macbook-Wallpaper.jpg',5.20,1),(29,'ashley_Son_Airplane_a0ViSA.jpg','JPEG','image/jpeg','','',408543,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1920,1280,'/database/ashley_Son_Airplane_a0ViSA.jpg',2.50,1),(30,'2016-02-02_setsubun_JA-JP11957231259_1920x1080.jpg','JPEG','image/jpeg','','',215846,'','','','','','','','','2016-02-03T07:41:28','','',0,0,0,1920,1080,'/database/2016-02-02_setsubun_JA-JP11957231259_1920x1080.jpg',2.10,1),(31,'pexels-perry-wunderlich-5826451.jpg','JPEG','image/jpeg','','',573856,'','','','','','','','','2023-10-11T07:36:40','','',0,0,0,3000,2000,'/database/pexels-perry-wunderlich-5826451.jpg',6.00,1),(32,'71test.jpg','JPEG','image/jpeg','Pixelmator 3.7.3','',1643832,'','','','Horizontal (normal)','','','','','2023-04-07T07:08:19','','',0,0,0,3464,1948,'/database/71test.jpg',6.70,1),(33,'13test.jpg','JPEG','image/jpeg','','',336213,'','','','','','','','','2016-02-03T07:43:18','','',0,0,0,1920,1080,'/database/13test.jpg',2.10,1),(34,'IMG_4782.HEIC','HEIC','image/heic','16.7','',1123164,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 6mm f/2','Rotate 90 CW','2023-10-03T08:30:33','','','2023-10-03T08:30:33','2023-10-03T08:30:38','','',0,0,0,4032,3024,'/database/IMG_4782.HEIC',12.20,1),(35,'pexels-lokman-sevim-17788447.jpg','JPEG','image/jpeg','','',4173747,'','','','','','','','','2023-10-11T07:35:25','','',0,0,0,3648,5472,'/database/pexels-lokman-sevim-17788447.jpg',20.00,1),(36,'IMG_0438.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',821675,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0438.JPG',4.20,1),(37,'IMG_0439.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',898979,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0439.JPG',4.20,1),(38,'IMG_0416.JPG','JPEG','image/jpeg','','',288253,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0416.JPG',4.20,1),(39,'IMG_0417.JPG','JPEG','image/jpeg','','',248134,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0417.JPG',4.20,1),(40,'IMG_0429.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',1064685,'Canon','Canon EOS 5D','','Horizontal (normal)','2000-01-01T01:04:41','2000-01-01T00:00:00','','2000-01-01T01:04:41','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0429.JPG',4.20,1),(41,'IMG_0428.JPG','JPEG','image/jpeg','www.meitu.com','',622681,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0428.JPG',4.20,1),(42,'IMG_0513.JPG','JPEG','image/jpeg','','',1452125,'','NIKON D300S','','Horizontal (normal)','2011-08-27T14:55:57','2011-08-27T00:00:00','','2011-08-27T14:55:57','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0513.JPG',4.20,1),(43,'IMG_0507.JPG','JPEG','image/jpeg','','',1199480,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0507.JPG',4.20,1),(44,'IMG_0498.JPG','JPEG','image/jpeg','','',1138062,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0498.JPG',4.20,1),(45,'IMG_0467.JPG','JPEG','image/jpeg','','',534227,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0467.JPG',4.20,1),(46,'IMG_0473.JPG','JPEG','image/jpeg','','',622699,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0473.JPG',4.20,1),(47,'IMG_0472.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Windows','',431167,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0472.JPG',4.20,1),(48,'IMG_0466.JPG','JPEG','image/jpeg','','',967030,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0466.JPG',4.20,1),(49,'IMG_0499.JPG','JPEG','image/jpeg','','',693081,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0499.JPG',4.20,1),(50,'IMG_0506.JPG','JPEG','image/jpeg','','',881713,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0506.JPG',4.20,1),(51,'IMG_0512.JPG','JPEG','image/jpeg','','',1429390,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0512.JPG',4.20,1),(52,'IMG_0504.JPG','JPEG','image/jpeg','','',1001284,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0504.JPG',4.20,1),(53,'IMG_0510.JPG','JPEG','image/jpeg','www.meitu.com','',314034,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0510.JPG',4.20,1),(54,'IMG_0470.JPG','JPEG','image/jpeg','ACDSee Pro 5','',771573,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0470.JPG',4.20,1),(55,'IMG_0464.JPG','JPEG','image/jpeg','','',215167,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0464.JPG',4.20,1),(56,'IMG_0458.JPG','JPEG','image/jpeg','','',753486,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0458.JPG',4.20,1),(57,'IMG_0459.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Macintosh','',1595315,'Canon','Canon EOS 5D Mark II','TS-E17mm f/4L','Horizontal (normal)','2011-06-03T16:44:25','2011-06-03T16:44:25','','2011-06-03T16:44:25','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0459.JPG',4.20,1),(58,'IMG_0465.JPG','JPEG','image/jpeg','','',698430,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0465.JPG',4.20,1),(59,'IMG_0471.JPG','JPEG','image/jpeg','','',449131,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0471.JPG',4.20,1),(60,'IMG_0511.JPG','JPEG','image/jpeg','ACDSee Pro 5','',709270,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0511.JPG',4.20,1),(61,'IMG_0505.JPG','JPEG','image/jpeg','','',623513,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0505.JPG',4.20,1),(62,'IMG_0501.JPG','JPEG','image/jpeg','','',526219,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2011-08-12T01:24:52','','','2011-08-12T01:24:52','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0501.JPG',4.20,1),(63,'IMG_0515.JPG','JPEG','image/jpeg','','',2145959,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0515.JPG',4.20,1),(64,'IMG_0449.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',574543,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0449.JPG',4.20,1),(65,'IMG_0475.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',1024781,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0475.JPG',4.20,1),(66,'IMG_0461.JPG','JPEG','image/jpeg','','',769713,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0461.JPG',4.20,1),(67,'IMG_0460.JPG','JPEG','image/jpeg','','',725972,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0460.JPG',4.20,1),(68,'IMG_0474.JPG','JPEG','image/jpeg','Adobe Photoshop CS6 (13.0 20120305.m.415 2012/03/05:21:00:00)  (Macintosh)','',1156237,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0474.JPG',4.20,1),(69,'IMG_0448.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',673094,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0448.JPG',4.20,1),(70,'IMG_0514.JPG','JPEG','image/jpeg','','',601072,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0514.JPG',4.20,1),(71,'IMG_0500.JPG','JPEG','image/jpeg','','',1681743,'Canon','Canon EOS 60D','','Horizontal (normal)','2011-08-15T15:43:20','2011-08-15T00:00:00','','2011-08-15T15:43:20','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0500.JPG',4.20,1),(72,'IMG_0516.JPG','JPEG','image/jpeg','','',703331,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2011-07-16T12:07:04','2011-07-16T00:00:00','','2011-07-16T12:07:04','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0516.JPG',4.20,1),(73,'IMG_0502.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',615557,'Canon','Canon EOS 5D','','Horizontal (normal)','2011-01-31T04:30:54','2011-01-31T00:00:00','','2011-01-31T04:30:54','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0502.JPG',4.20,1),(74,'IMG_0489.JPG','JPEG','image/jpeg','','',776128,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0489.JPG',4.20,1),(75,'IMG_0462.JPG','JPEG','image/jpeg','','',554237,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0462.JPG',4.20,1),(76,'IMG_0476.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',1388015,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0476.JPG',4.20,1),(77,'IMG_0477.JPG','JPEG','image/jpeg','','',347814,'NIKON CORPORATION','NIKON D80','','Horizontal (normal)','2011-11-11T11:14:48','','','2011-11-11T11:14:48','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0477.JPG',4.20,1),(78,'IMG_0463.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',953815,'Canon','Canon EOS 5D','','Horizontal (normal)','2010-07-27T04:54:47','2010-07-27T00:00:00','','2010-07-27T04:54:47','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0463.JPG',4.20,1),(79,'IMG_0488.JPG','JPEG','image/jpeg','','',667872,'Canon','Canon EOS 50D','','Horizontal (normal)','2010-12-03T08:37:13','2010-12-03T00:00:00','','2010-12-03T08:37:13','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0488.JPG',4.20,1),(80,'IMG_0503.JPG','JPEG','image/jpeg','','',803044,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0503.JPG',4.20,1),(81,'IMG_0517.JPG','JPEG','image/jpeg','','',788304,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2011-08-14T10:17:30','2011-08-14T00:00:00','','2011-08-14T10:17:30','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0517.JPG',4.20,1),(82,'IMG_0485.JPG','JPEG','image/jpeg','Pixelmator 2.0.1','',1392621,'Canon','Canon EOS 350D DIGITAL','','Horizontal (normal)','2007-11-02T14:51:25','','','2007-11-02T14:51:25','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0485.JPG',4.20,1),(83,'IMG_0491.JPG','JPEG','image/jpeg','','',760983,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0491.JPG',4.20,1),(84,'IMG_0446.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',968967,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0446.JPG',4.20,1),(85,'IMG_0452.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',668604,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0452.JPG',4.20,1),(86,'IMG_0453.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',1507390,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0453.JPG',4.20,1),(87,'IMG_0447.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',743832,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0447.JPG',4.20,1),(88,'IMG_0490.JPG','JPEG','image/jpeg','','',1802865,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0490.JPG',4.20,1),(89,'IMG_0484.JPG','JPEG','image/jpeg','','',589782,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0484.JPG',4.20,1),(90,'IMG_0492.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Windows','',634164,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0492.JPG',4.20,1),(91,'IMG_0486.JPG','JPEG','image/jpeg','','',1311077,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0486.JPG',4.20,1),(92,'IMG_0451.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',757842,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0451.JPG',4.20,1),(93,'IMG_0479.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Windows','',489375,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0479.JPG',4.20,1),(94,'IMG_0478.JPG','JPEG','image/jpeg','','',901269,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0478.JPG',4.20,1),(95,'IMG_0444.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',930863,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0444.JPG',4.20,1),(96,'IMG_0450.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',1021749,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0450.JPG',4.20,1),(97,'IMG_0487.JPG','JPEG','image/jpeg','','',537363,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0487.JPG',4.20,1),(98,'IMG_0493.JPG','JPEG','image/jpeg','','',1039210,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0493.JPG',4.20,1),(99,'IMG_0508.JPG','JPEG','image/jpeg','','',705334,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0508.JPG',4.20,1),(100,'IMG_0497.JPG','JPEG','image/jpeg','','',678449,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0497.JPG',4.20,1),(101,'IMG_0483.JPG','JPEG','image/jpeg','','',1704202,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0483.JPG',4.20,1),(102,'IMG_0468.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Windows','',965272,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0468.JPG',4.20,1),(103,'IMG_0454.JPG','JPEG','image/jpeg','','',1398272,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0454.JPG',4.20,1),(104,'IMG_0440.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',695077,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0440.JPG',4.20,1),(105,'IMG_0441.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',932577,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0441.JPG',4.20,1),(106,'IMG_0455.JPG','JPEG','image/jpeg','','',1127748,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0455.JPG',4.20,1),(107,'IMG_0469.JPG','JPEG','image/jpeg','','',475838,'Canon','Canon EOS 550D','','Horizontal (normal)','2011-04-16T16:57:48','2011-04-16T00:00:00','','2011-04-16T16:57:48','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0469.JPG',4.20,1),(108,'IMG_0496.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Windows','',834244,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0496.JPG',4.20,1),(109,'IMG_0509.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Windows','',431450,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0509.JPG',4.20,1),(110,'123__IMG_0425.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Macintosh','',1416088,'Canon','Canon EOS 5D Mark II','TS-E17mm f/4L','Horizontal (normal)','2011-06-05T07:08:00','2011-06-05T07:08:00','','2011-06-05T07:08:00','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/123__IMG_0425.JPG',4.20,1),(111,'IMG_0480.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Windows','',1079169,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0480.JPG',4.20,1),(112,'IMG_0494.JPG','JPEG','image/jpeg','www.meitu.com','',360795,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0494.JPG',4.20,1),(113,'IMG_0443.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',656614,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0443.JPG',4.20,1),(114,'IMG_0457.JPG','JPEG','image/jpeg','','',488127,'Canon','Canon EOS 60D','','Horizontal (normal)','2011-07-18T10:41:51','2011-07-18T00:00:00','','2011-07-18T10:41:51','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0457.JPG',4.20,1),(115,'IMG_0456.JPG','JPEG','image/jpeg','','',1257625,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0456.JPG',4.20,1),(116,'IMG_0442.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',915038,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0442.JPG',4.20,1),(117,'IMG_0495.JPG','JPEG','image/jpeg','','',1429968,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0495.JPG',4.20,1),(118,'IMG_0431.JPG','JPEG','image/jpeg','','',531951,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0431.JPG',4.20,1),(119,'IMG_0419.JPG','JPEG','image/jpeg','','',617757,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2011-07-28T07:17:23','2011-07-28T00:00:00','','2011-07-28T07:17:23','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0419.JPG',4.20,1),(120,'IMG_0418.JPG','JPEG','image/jpeg','','',938360,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0418.JPG',4.20,1),(121,'IMG_0430.JPG','JPEG','image/jpeg','','',1525889,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0430.JPG',4.20,1),(122,'IMG_0432.JPG','JPEG','image/jpeg','Pixelmator 2.0.1','',755527,'Canon','Canon EOS DIGITAL REBEL XT','','Horizontal (normal)','2006-11-11T13:57:52','','','2006-11-11T13:57:52','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0432.JPG',4.20,1),(123,'IMG_0426.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',754074,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0426.JPG',4.20,1),(124,'__7________IM_G_0423.JPG','JPEG','image/jpeg','Pixelmator 2.0.1','',1988234,'Canon','Canon EOS 450D','','Horizontal (normal)','2010-08-03T18:57:39','','','2010-08-03T18:57:39','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/__7________IM_G_0423.JPG',4.20,1),(125,'IMG_0427.JPG','JPEG','image/jpeg','','',1534789,'','NIKON D80','','Horizontal (normal)','','','','2010-12-04T05:36:38','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0427.JPG',4.20,1),(126,'IMG_0433.JPG','JPEG','image/jpeg','','',457483,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0433.JPG',4.20,1),(127,'IMG_0437.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',669788,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0437.JPG',4.20,1),(128,'IMG_0422.JPG','JPEG','image/jpeg','','',817581,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2011-10-20T07:40:03','2011-10-20T00:00:00','','2011-10-20T07:40:03','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0422.JPG',4.20,1),(129,'IMG_0436.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',682538,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0436.JPG',4.20,1),(130,'WWDC-AR7-iPad.png','PNG','image/png','','',2269323,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/WWDC-AR7-iPad.png',4.20,1),(131,'IMG_0420.JPG','JPEG','image/jpeg','Adobe Photoshop CS5.1 Macintosh','',874273,'Canon','Canon EOS 5D','','Horizontal (normal)','2010-10-28T23:59:34','2010-10-28T00:00:00','','2010-10-28T23:59:34','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0420.JPG',4.20,1),(132,'IMG_0434.JPG','JPEG','image/jpeg','','',1066681,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0434.JPG',4.20,1),(133,'IMG_0435.JPG','JPEG','image/jpeg','Adobe Photoshop 7.0','',1104210,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0435.JPG',4.20,1),(134,'IMG_0421.JPG','JPEG','image/jpeg','','',821005,'','','','Horizontal (normal)','2011-07-27T12:20:56','2011-07-27T00:00:00','','2011-07-27T12:20:56','2024-06-12T10:31:15','','',0,0,0,2048,2048,'/database/__The_n_ew_iP_ad/IMG_0421.JPG',4.20,1),(135,'85test.jpg','JPEG','image/jpeg','','',797214,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1998,1280,'/database/85test.jpg',2.60,1),(136,'4____test.gif','GIF','image/gif','','',8807531,'','','','','','','','','2023-04-07T07:08:18','','',1,0,0,1280,720,'/database/4____test.gif',0.92,1),(137,'Luke_Ma_Cherry_Soda_a0RhRQ.jpg','JPEG','image/jpeg','','',258785,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1840,1280,'/database/Luke_Ma_Cherry_Soda_a0RhRQ.jpg',2.40,1),(138,'inspiredimages_Brown_beach_YkVqQ2Y.jpg','JPEG','image/jpeg','','',863722,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/inspiredimages_Brown_beach_YkVqQ2Y.jpg',2.50,1),(139,'video__1080p__2.mp4','MP4','video/mp4','','',8430151,'','','','','2020-01-26T09:28:43','','','','2023-10-10T23:14:48','2020-01-26T09:28:43','2020-01-26T09:28:43',31.5315,0,0,1920,1080,'/database/video__1080p__2.mp4',2.10,1),(140,'wallpaper-Dark.jpg','JPEG','image/jpeg','','',4545703,'','','','Horizontal (normal)','','','','','2023-04-30T02:47:17','','',0,0,0,6016,6016,'/database/wallpaper-Dark.jpg',36.20,1),(141,'2016-02-01_IemanjaFlowers_PT-BR10970450658_1920x1080.jpg','JPEG','image/jpeg','','',338867,'','','','','','','','','2016-02-03T07:41:46','','',0,0,0,1920,1080,'/database/2016-02-01_IemanjaFlowers_PT-BR10970450658_1920x1080.jpg',2.10,1),(142,'17_test.jpg','JPEG','image/jpeg','','',352445,'','','','','','','','','2016-02-03T07:43:58','','',0,0,0,1920,1080,'/database/17_test.jpg',2.10,1),(143,'40_test.gif','GIF','image/gif','','',393223,'','','','','','','','','2023-04-07T07:08:19','','',1.89,0,0,817,460,'/database/40_test.gif',0.38,1),(144,'FrankyChou_Travel_YkVgQWs.jpg','JPEG','image/jpeg','','',657670,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/FrankyChou_Travel_YkVgQWs.jpg',2.50,1),(145,'pexels-morteza-ghanbari-18556807.jpg','JPEG','image/jpeg','','',7606076,'','','','','','','','','2023-10-11T07:35:46','','',0,0,0,5461,8192,'/database/pexels-morteza-ghanbari-18556807.jpg',44.70,1),(146,'pexels-manish-jangid-18037510.jpg','JPEG','image/jpeg','','',2480398,'','','','','','','','','2023-10-11T07:36:24','','',0,0,0,4000,6000,'/database/pexels-manish-jangid-18037510.jpg',24.00,1),(147,'2015-11-23_OctoberMorning_ROW15719492089_1920x1080.jpg','JPEG','image/jpeg','','',189110,'','','','','','','','','2016-02-03T07:42:40','','',0,0,0,1920,1080,'/database/2015-11-23_OctoberMorning_ROW15719492089_1920x1080.jpg',2.10,1),(148,'Foundry_Sweet_Doughnuts_YkVqRWY.jpg','JPEG','image/jpeg','','',596023,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1919,1280,'/database/Foundry_Sweet_Doughnuts_YkVqRWY.jpg',2.50,1),(149,'21test.jpg','JPEG','image/jpeg','','',346803,'','','','','','','','','2016-02-03T07:41:36','','',0,0,0,1920,1080,'/database/21test.jpg',2.10,1),(150,'43test.jpg','JPEG','image/jpeg','','',639210,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/43test.jpg',2.50,1),(151,'61test.mp4','MP4','video/mp4','','',8589626,'','','','','0000:00:00 00:00:00','','','','2023-09-30T21:03:07','0000:00:00 00:00:00','0000:00:00 00:00:00',13.314,0,0,1080,1920,'/database/61test.mp4',2.10,1),(152,'108test.jpg','JPEG','image/jpeg','','',2022829,'','','','','','','','','2023-10-11T07:36:13','','',0,0,0,3633,5449,'/database/108test.jpg',19.80,1),(153,'production_id_4763824__2160p_.mp4','MP4','video/mp4','','',34082855,'','','','','2020-06-30T16:02:30','','','','2023-10-10T23:14:31','2020-06-30T16:02:30','2020-06-30T16:02:30',14.125,0,0,3840,2160,'/database/production_id_4763824__2160p_.mp4',8.30,1),(154,'Foundry_Morning_with_Milk_YkVkRWQ.jpg','JPEG','image/jpeg','','',193255,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/Foundry_Morning_with_Milk_YkVkRWQ.jpg',2.50,1),(155,'pexels-kammeran-gonzalezkeola-17838377__Original_.mp4','M4V','video/x-m4v','','Untitled Project',76182155,'','','','','2023-03-19T02:16:43','','','','2023-10-11T07:38:41','2023-03-19T02:16:43','2023-03-19T02:17:09',20.1666666666667,0,0,3840,2160,'/database/pexels-kammeran-gonzalezkeola-17838377__Original_.mp4',8.30,1),(156,'pexels-kammeran-gonzalezkeola-17838377__2160p_.mp4','MP4','video/mp4','','',64287648,'','','','','2023-08-02T22:46:35','','','','2023-10-11T07:38:39','2023-08-02T22:46:35','2023-08-02T22:46:35',20.1666666666667,0,0,3840,2160,'/database/pexels-kammeran-gonzalezkeola-17838377__2160p_.mp4',8.30,1),(157,'2015-11-30_OceanSwimRace_EN-AU11288679332_1920x1080.jpg','JPEG','image/jpeg','','',329398,'','','','','','','','','2016-02-03T07:43:48','','',0,0,0,1920,1080,'/database/2015-11-30_OceanSwimRace_EN-AU11288679332_1920x1080.jpg',2.10,1),(158,'Mathulak_Flickr_Boats_with_Sunset_akJjQA.jpg','JPEG','image/jpeg','','',328399,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,2017,1280,'/database/Mathulak_Flickr_Boats_with_Sunset_akJjQA.jpg',2.60,1),(159,'production_id_4873244__2160p_.mp4','MP4','video/mp4','','',17093064,'','','','','2020-07-15T07:21:10','','','','2023-10-10T23:15:05','2020-07-15T07:21:10','2020-07-15T07:21:10',14.12,0,0,3840,2160,'/database/production_id_4873244__2160p_.mp4',8.30,1),(160,'81test.jpg','JPEG','image/jpeg','','',959860,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2560,1440,'/database/81test.jpg',3.70,1),(161,'Marco_Tanzi_City_At_Night_ZEZiRQ.jpg','JPEG','image/jpeg','','',465692,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/Marco_Tanzi_City_At_Night_ZEZiRQ.jpg',2.50,1),(162,'diego_torres_Worbarrow_Bay_YkVqQmA.jpg','JPEG','image/jpeg','','',623685,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/diego_torres_Worbarrow_Bay_YkVqQmA.jpg',2.50,1),(163,'image020918_003511.jpg','JPEG','image/jpeg','11.4.1','',2892840,'Apple','iPhone X','iPhone X back dual camera 4mm f/1.8','Horizontal (normal)','2018-09-01T21:15:47','','','2018-09-01T21:15:47','2018-09-02T00:35:11','','',0,37.7308777777778,-122.407386111111,4032,3024,'/database/image020918_003511.jpg',12.20,1),(164,'MP4Test.mp4','MP4','video/mp4','','',141777221,'','','','','2014-12-05T14:48:37','','','','2023-08-28T09:55:34','2014-12-05T19:48:37','2014-12-05T19:48:37',185.706666666667,0,0,1280,720,'/database/MP4Test.mp4',0.92,1),(165,'IMG_3324.MOV','MOV','video/quicktime','16.4.1','',19332894,'Apple','iPhone 11 Pro Max','','','2023-04-30T20:56:10','','2023-04-30T13:56:10','','2023-04-30T13:56:10','2023-04-30T20:56:10','2023-04-30T20:56:30',19.4166666666667,0,0,1920,1080,'/database/IMG_3324.MOV',2.10,1),(166,'Coffee.gif','GIF','image/gif','','',903003,'','','','','','','','','2023-04-07T07:08:19','','',1.24,0,0,500,281,'/database/Coffee.gif',0.14,1),(167,'75test.jpg','JPEG','image/jpeg','','',640165,'','','','','','','','','2015-10-22T14:23:14','','',0,0,0,2048,1280,'/database/75test.jpg',2.60,1),(168,'12_test.jpg','JPEG','image/jpeg','','',274137,'','','','','','','','','2016-02-03T07:42:28','','',0,0,0,1920,1080,'/database/12_test.jpg',2.10,1),(169,'video__1080p_.mp4','MP4','video/mp4','','',7960318,'','','','','2019-12-12T10:58:16','','','','2023-10-10T23:14:05','2019-12-12T10:58:16','2019-12-12T10:58:16',12.2789333333333,0,0,1080,1920,'/database/video__1080p_.mp4',2.10,1),(170,'03185_calmness_1680x1050.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',1889921,'Canon','Canon EOS 5D Mark II','EF24-70mm f/2.8L USM','Horizontal (normal)','2012-08-30T17:38:54','2012-08-30T17:38:54','','2012-08-30T17:38:54','2023-04-07T07:08:18','','',0,0,0,1680,1050,'/database/03185_calmness_1680x1050.jpg',1.80,1),(171,'39test.jpg','JPEG','image/jpeg','','',756085,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,2048,1280,'/database/39test.jpg',2.60,1),(172,'5test.jpg','JPEG','image/jpeg','','',342887,'','','','','','','','','2016-02-03T07:42:34','','',0,0,0,1920,1080,'/database/5test.jpg',2.10,1),(173,'snow-winter-wood-tree-road-night-nature-imac-27.jpg','JPEG','image/jpeg','Adobe Photoshop CC (Macintosh)','',4368706,'NIKON CORPORATION','NIKON D3100','10.0-20.0 mm f/3.5','Horizontal (normal)','2017-01-01T15:38:40','2017-01-01T15:38:40','','2017-01-01T15:38:40','2023-04-07T07:08:19','','',0,0,0,3840,2400,'/database/snow-winter-wood-tree-road-night-nature-imac-27.jpg',9.20,1),(174,'16test.jpg','JPEG','image/jpeg','','',343750,'','','','','','','','','2016-02-03T07:43:10','','',0,0,0,1920,1080,'/database/16test.jpg',2.10,1),(175,'Lara_Danielle_Love_Hearts_YkViQGM.jpg','JPEG','image/jpeg','','',386082,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1706,1280,'/database/Lara_Danielle_Love_Hearts_YkViQGM.jpg',2.20,1),(176,'pexels-zehra-16983649.jpg','JPEG','image/jpeg','','',4954345,'','','','','','','','','2023-10-11T07:35:36','','',0,0,0,4000,6000,'/database/pexels-zehra-16983649.jpg',24.00,1),(177,'89test.jpg','JPEG','image/jpeg','','',950382,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/89test.jpg',5.20,1),(178,'pexels-alina-vilchenko-17435490.jpg','JPEG','image/jpeg','','',5118776,'','','','','','','','','2023-10-11T07:35:20','','',0,0,0,4000,5434,'/database/pexels-alina-vilchenko-17435490.jpg',21.70,1),(179,'noIMG_3336.HEIC','HEIC','image/heic','16.4.1','',1481002,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:13:07','2023-04-30T14:13:07','','2023-04-30T14:13:07','2023-04-30T14:13:08','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/noIMG_3336.HEIC',12.20,1),(180,'what__.HEIC','HEIC','image/heic','16.4.1','',1720444,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:14:32','','','2023-04-30T14:14:32','2023-04-30T14:14:32','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/what__.HEIC',12.20,1),(181,'BORX8909.jpg','JPEG','image/jpeg','','',234115,'','','','','2017-02-05T10:59:41','2017-02-05T10:59:41','','2017-02-05T10:59:41','2021-03-16T15:43:14','','',0,0,0,1000,667,'/database/newImport_05-07-2024/BORX8909.jpg',0.67,1),(182,'IMG_3323.HEIC','HEIC','image/heic','16.4.1','',2541260,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 6mm f/2','Horizontal (normal)','2023-04-30T13:56:05','2023-04-30T13:56:05','','2023-04-30T13:56:05','2023-04-30T13:56:38','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3323.HEIC',12.20,1),(183,'anastasia-petrova-193830-unsplash.jpg','JPEG','image/jpeg','','',3525674,'','','','','','','','','2023-04-07T07:08:18','','',0,0,0,4999,3281,'/database/newImport_05-07-2024/anastasia-petrova-193830-unsplash.jpg',16.40,1),(184,'giphy-4.gif','GIF','image/gif','','',1761740,'','','','','','','','','2019-08-20T10:59:28','','',3.72,0,0,850,567,'/database/newImport_05-07-2024/giphy-4.gif',0.48,1),(185,'IMG_3322.HEIC','HEIC','image/heic','16.4.1','',1332244,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T13:51:27','','','2023-04-30T13:51:27','2023-04-30T13:51:27','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3322.HEIC',12.20,1),(186,'IMG_3337.HEIC','HEIC','image/heic','16.4.1','',2184927,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:13:43','2023-04-30T14:13:43','','2023-04-30T14:13:43','2023-04-30T14:13:43','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3337.HEIC',12.20,1),(187,'IMG_3321.HEIC','HEIC','image/heic','16.4.1','',2023902,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T13:50:28','','','2023-04-30T13:50:28','2023-04-30T13:50:28','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3321.HEIC',12.20,1),(188,'flask4-2.gif','GIF','image/gif','','',706484,'','','','','','','','','2019-08-20T10:59:43','','',30,0,0,600,458,'/database/newImport_05-07-2024/flask4-2.gif',0.28,1),(189,'what___IMG_3339.HEIC','HEIC','image/heic','16.4.1','',1927029,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:14:36','2023-04-30T14:14:36','','2023-04-30T14:14:36','2023-04-30T14:14:36','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/what___IMG_3339.HEIC',12.20,1),(190,'70458175599__6CDFAA94-B0F7-4A66-938B-04CEDE714AC0.HEIC','HEIC','image/heic','16.4.1','',2376555,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:09:15','','','2023-04-30T14:09:15','2023-04-30T14:09:16','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/70458175599__6CDFAA94-B0F7-4A66-938B-04CEDE714AC0.HEIC',12.20,1),(191,'toy1.jpeg','JPEG','image/jpeg','Adobe Photoshop CC (Macintosh)','',1378240,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2012-12-08T16:51:18','2012-12-08T00:00:00','','2012-12-08T16:51:18','2023-12-02T12:18:17','','',0,0,0,1600,1067,'/database/newImport_05-07-2024/toy1.jpeg',1.70,1),(192,'flask3.gif','GIF','image/gif','','',6591982,'','','','','','','','','2019-08-20T10:59:42','','',30,0,0,600,449,'/database/newImport_05-07-2024/flask3.gif',0.27,1),(193,'IMG_3326_Hello.HEIC','HEIC','image/heic','16.4.1','',1749194,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Rotate 90 CW','2023-04-30T14:11:24','2023-04-30T14:11:24','','2023-04-30T14:11:24','2023-04-30T14:11:24','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3326_Hello.HEIC',12.20,1),(194,'IMG_3330.HEIC','HEIC','image/heic','16.4.1','',1201166,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Horizontal (normal)','2023-04-30T14:12:20','2023-04-30T14:12:20','','2023-04-30T14:12:20','2023-04-30T14:12:20','','',0,0,0,4032,3024,'/database/newImport_05-07-2024/IMG_3330.HEIC',12.20,1),(195,'ongliong11-color.png','PNG','image/png','','',2453985,'','','','Horizontal (normal)','','','','','2023-04-07T07:08:19','','',0,0,0,2832,1750,'/database/ongliong11-color.png',5.00,1),(196,'42test.jpg','JPEG','image/jpeg','','',814063,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/42test.jpg',2.50,1),(197,'realized1-solefield-desktop-2880-x-1800.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',3165661,'NIKON CORPORATION','NIKON D300','','Horizontal (normal)','2016-09-02T15:54:59','2016-09-02T15:54:59','','2016-09-02T15:54:59','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/realized1-solefield-desktop-2880-x-1800.jpg',5.20,1),(198,'imac-love-computer-wallpaper-1920x1080-3050-1440x900.jpg','JPEG','image/jpeg','','',96565,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,1440,900,'/database/Wallpaper/imac-love-computer-wallpaper-1920x1080-3050-1440x900.jpg',1.30,1),(199,'IMG_0003.JPG','JPEG','image/jpeg','','',56987,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0003.JPG',0.15,1),(200,'IMG_0017.JPG','JPEG','image/jpeg','','',27223,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0017.JPG',0.15,1),(201,'IMG_0006.JPG','JPEG','image/jpeg','','',42125,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0006.JPG',0.15,1),(202,'IMG_0013.JPG','JPEG','image/jpeg','','',31584,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0013.JPG',0.15,1),(203,'1IMG_0020.JPG','JPEG','image/jpeg','','',498603,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/1IMG_0020.JPG',3.10,1),(204,'IMG_0011.JPG','JPEG','image/jpeg','','',41259,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0011.JPG',0.15,1),(205,'IMG_0005.JPG','JPEG','image/jpeg','','',55846,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0005.JPG',0.15,1),(206,'IMG_0004.JPG','JPEG','image/jpeg','','',59269,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0004.JPG',0.15,1),(207,'IMG_0010.JPG','JPEG','image/jpeg','','',39554,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0010.JPG',0.15,1),(208,'IMG_0088.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',189972,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0088.JPG',0.61,1),(209,'IMG_0063.JPG','JPEG','image/jpeg','','',264767,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0063.JPG',0.61,1),(210,'IMG_0103.JPG','JPEG','image/jpeg','Adobe Photoshop CS2 Windows','',152676,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0103.JPG',0.61,1),(211,'IMG_0102.JPG','JPEG','image/jpeg','','',181700,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0102.JPG',0.61,1),(212,'Sunset-optimized-by-AR7.png','PNG','image/png','','',293980,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/Sunset-optimized-by-AR7.png',0.73,1),(213,'IMG_0062.JPG','JPEG','image/jpeg','','',229306,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0062.JPG',0.61,1),(214,'IMG_0076.JPG','JPEG','image/jpeg','','',77489,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0076.JPG',0.61,1),(215,'IMG_0089.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',375764,'SONY','DSLR-A100','','Horizontal (normal)','2009-09-21T12:32:50','2009-09-21T12:32:50','','2009-09-21T12:32:50','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0089.JPG',0.61,1),(216,'IMG_0060.JPG','JPEG','image/jpeg','','',114118,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0060.JPG',0.61,1),(217,'IMG_0048.JPG','JPEG','image/jpeg','','',339562,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0048.JPG',0.61,1),(218,'WWDC-AR7-Mac_air.jpg','JPEG','image/jpeg','iPhoto 9.5.1','',1064226,'','','','Horizontal (normal)','2014-04-04T11:54:10','2014-04-04T11:54:10','','2014-04-04T11:54:10','2024-06-12T10:31:15','','',0,0,0,2048,1280,'/database/Wallpaper/WWDC-AR7-Mac_air.jpg',2.60,1),(219,'7IMG_0019.JPG','JPEG','image/jpeg','','',463742,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/7IMG_0019.JPG',3.10,1),(220,'IMG_0114.JPG','JPEG','image/jpeg','GIMP 2.6.8','',316560,'','Canon EOS 40D','','Horizontal (normal)','','2008-07-09T18:10:52','','2008-07-09T18:10:52','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0114.JPG',0.61,1),(221,'IMG_0101.JPG','JPEG','image/jpeg','','',142550,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0101.JPG',0.61,1),(222,'2IMG_0021.JPG','JPEG','image/jpeg','','',281617,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/2IMG_0021.JPG',3.10,1),(223,'1440x900.png','PNG','image/png','','',194367,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,1440,900,'/database/Wallpaper/1440x900.png',1.30,1),(224,'IMG_0049.JPG','JPEG','image/jpeg','Adobe Photoshop CS2 Windows','',183001,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0049.JPG',0.61,1),(225,'IMG_0075.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',278204,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0075.JPG',0.61,1),(226,'IMG_0061.JPG','JPEG','image/jpeg','','',102306,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0061.JPG',0.61,1),(227,'IMG_0059.JPG','JPEG','image/jpeg','Adobe Photoshop CS2 Windows','',190671,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0059.JPG',0.61,1),(228,'IMG_0065.JPG','JPEG','image/jpeg','','',201014,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0065.JPG',0.61,1),(229,'IMG_0071.JPG','JPEG','image/jpeg','','',97591,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0071.JPG',0.61,1),(230,'Ozix-abstract-geometry.jpg','JPEG','image/jpeg','','',164067,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,744,1392,'/database/Wallpaper/Ozix-abstract-geometry.jpg',1.00,1),(231,'IMG_0105.JPG','JPEG','image/jpeg','','',315557,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0105.JPG',0.61,1),(232,'IMG_0104.JPG','JPEG','image/jpeg','','',189362,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0104.JPG',0.61,1),(233,'IMG_0110.JPG','JPEG','image/jpeg','','',148498,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0110.JPG',0.61,1),(234,'IMG_0070.JPG','JPEG','image/jpeg','','',101477,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0070.JPG',0.61,1),(235,'IMG_0064.JPG','JPEG','image/jpeg','','',207427,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0064.JPG',0.61,1),(236,'IMG_0058.JPG','JPEG','image/jpeg','','',220602,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0058.JPG',0.61,1),(237,'IMG_0099.JPG','JPEG','image/jpeg','','',160142,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0099.JPG',0.61,1),(238,'IMG_0072.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',132207,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0072.JPG',0.61,1),(239,'IMG_0066.JPG','JPEG','image/jpeg','','',224353,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0066.JPG',0.61,1),(240,'Ozix-shine.jpg','JPEG','image/jpeg','','',68115,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/Ozix-shine.jpg',0.73,1),(241,'IMG_0106.JPG','JPEG','image/jpeg','','',104679,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0106.JPG',0.61,1),(242,'IMG_0112.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',168803,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0112.JPG',0.61,1),(243,'IMG_0113.JPG','JPEG','image/jpeg','GIMP 2.6.8','',201241,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0113.JPG',0.61,1),(244,'IMG_0107.JPG','JPEG','image/jpeg','','',204297,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0107.JPG',0.61,1),(245,'Marie_Sturges_Raspberry_640x1136.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',597374,'','','','Horizontal (normal)','2013-02-17T23:58:37','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/Marie_Sturges_Raspberry_640x1136.jpg',0.73,1),(246,'IMG_0067.JPG','JPEG','image/jpeg','','',140168,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0067.JPG',0.61,1),(247,'IMG_0073.JPG','JPEG','image/jpeg','','',149234,'','','','Horizontal (normal)','','2004-09-26T00:00:00','','2004-09-26T00:00:00','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0073.JPG',0.61,1),(248,'IMG_0098.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',168987,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0098.JPG',0.61,1),(249,'IMG_0095.JPG','JPEG','image/jpeg','','',142394,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0095.JPG',0.61,1),(250,'IMG_0081.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',347366,'NIKON CORPORATION','NIKON D60','','Horizontal (normal)','2010-04-04T16:12:22','2010-04-04T16:12:22','','2010-04-04T16:12:22','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0081.JPG',0.61,1),(251,'IMG_0056.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',158814,'Canon','Canon EOS 40D','','Horizontal (normal)','2010-04-24T16:37:44','2010-04-24T16:37:44','','2010-04-24T16:37:44','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0056.JPG',0.61,1),(252,'IMG_0042.JPG','JPEG','image/jpeg','','',218492,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0042.JPG',0.61,1),(253,'5IMG_0026.JPG','JPEG','image/jpeg','','',525391,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/5IMG_0026.JPG',3.10,1),(254,'twilightseye_640x1136.jpg','JPEG','image/jpeg','Adobe Photoshop CC (Macintosh)','Twilight\'s Eye',542616,'Canon','Canon EOS 5D Mark II','EF17-40mm f/4L USM','Horizontal (normal)','2013-12-15T08:29:54','2013-12-15T08:29:54','','2013-12-15T08:29:54','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/twilightseye_640x1136.jpg',0.73,1),(255,'IMG_0043.JPG','JPEG','image/jpeg','','',339869,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0043.JPG',0.61,1),(256,'IMG_0057.JPG','JPEG','image/jpeg','','',221763,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0057.JPG',0.61,1),(257,'IMG_0080.JPG','JPEG','image/jpeg','','',145499,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0080.JPG',0.61,1),(258,'IMG_0094.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',185893,'Canon','Canon EOS 5D Mark II','','Horizontal (normal)','2010-01-03T14:44:47','2010-01-03T14:44:47','','2010-01-03T14:44:47','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0094.JPG',0.61,1),(259,'IMG_0082.JPG','JPEG','image/jpeg','','',103530,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0082.JPG',0.61,1),(260,'apple_wallpaper_coastal-sunset-green_iphone5_parallax.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',418942,'','','','Horizontal (normal)','2014-02-19T15:01:37','','','','2024-06-12T10:31:15','','',0,0,0,1040,1536,'/database/Wallpaper/apple_wallpaper_coastal-sunset-green_iphone5_parallax.jpg',1.60,1),(261,'IMG_0096.JPG','JPEG','image/jpeg','','',200873,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0096.JPG',0.61,1),(262,'IMG_0041.JPG','JPEG','image/jpeg','','',183961,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0041.JPG',0.61,1),(263,'IMG_0055.JPG','JPEG','image/jpeg','','',355716,'Canon','Canon EOS DIGITAL REBEL XSi','','Horizontal (normal)','2008-11-29T11:01:51','2008-11-29T11:01:51','','2008-11-29T11:01:51','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0055.JPG',0.61,1),(264,'IMG_0069.JPG','JPEG','image/jpeg','','',183187,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0069.JPG',0.61,1),(265,'IMG_0108.JPG','JPEG','image/jpeg','','',180760,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0108.JPG',0.61,1),(266,'iOS_7_Mavericks_by_AR7.png','PNG','image/png','','',403020,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/iOS_7_Mavericks_by_AR7.png',0.73,1),(267,'IMG_0068.JPG','JPEG','image/jpeg','','',236381,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0068.JPG',0.61,1),(268,'IMG_0054.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',293126,'NIKON CORPORATION','NIKON D5000','','Horizontal (normal)','2010-05-22T09:44:44','2010-05-22T09:44:44','','2010-05-22T09:44:44','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0054.JPG',0.61,1),(269,'IMG_0040.JPG','JPEG','image/jpeg','','',123447,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0040.JPG',0.61,1),(270,'IMG_0097.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',339179,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0097.JPG',0.61,1),(271,'IMG_0083.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',332711,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0083.JPG',0.61,1),(272,'IMG_0093.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',175022,'','E-510','','Horizontal (normal)','','2010-05-02T21:18:00','','2010-05-02T21:18:00','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0093.JPG',0.61,1),(273,'IMG_0078.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',318397,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0078.JPG',0.61,1),(274,'IMG_0044.JPG','JPEG','image/jpeg','','',236805,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0044.JPG',0.61,1),(275,'IMG_0050.JPG','JPEG','image/jpeg','','',141049,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0050.JPG',0.61,1),(276,'apple_wallpaper_picnic-table-nature_iphone5_parallax.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',185689,'','','','Horizontal (normal)','2014-03-12T02:21:43','','','','2024-06-12T10:31:15','','',0,0,0,1040,1536,'/database/Wallpaper/apple_wallpaper_picnic-table-nature_iphone5_parallax.jpg',1.60,1),(277,'metro-right.jpg','JPEG','image/jpeg','','',1955364,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,1040,1526,'/database/Wallpaper/metro-right.jpg',1.60,1),(278,'IMG_0118.JPG','JPEG','image/jpeg','','',184431,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0118.JPG',0.61,1),(279,'IMG_0119.JPG','JPEG','image/jpeg','','',328380,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0119.JPG',0.61,1),(280,'IMG_0051.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',100905,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0051.JPG',0.61,1),(281,'IMG_0045.JPG','JPEG','image/jpeg','','',274469,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0045.JPG',0.61,1),(282,'IMG_0079.JPG','JPEG','image/jpeg','','',98557,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0079.JPG',0.61,1),(283,'IMG_0092.JPG','JPEG','image/jpeg','','',119467,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0092.JPG',0.61,1),(284,'IMG_0086.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',172468,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0086.JPG',0.61,1),(285,'IMG_0090.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',214434,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0090.JPG',0.61,1),(286,'IMG_0084.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',139487,'Canon','Canon EOS 450D','','Horizontal (normal)','2010-04-18T16:10:03','2010-04-18T16:10:03','','2010-04-18T16:10:03','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0084.JPG',0.61,1),(287,'IMG_0053.JPG','JPEG','image/jpeg','','',174667,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0053.JPG',0.61,1),(288,'IMG_0047.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',183878,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0047.JPG',0.61,1),(289,'Marie_Sturges_Blueberry_640x1136.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',412107,'','','','Horizontal (normal)','2013-02-18T00:09:20','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/Marie_Sturges_Blueberry_640x1136.jpg',0.73,1),(290,'IMG_0046.JPG','JPEG','image/jpeg','','',170636,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0046.JPG',0.61,1),(291,'IMG_0052.JPG','JPEG','image/jpeg','','',176280,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0052.JPG',0.61,1),(292,'IMG_0085.JPG','JPEG','image/jpeg','Adobe Photoshop CS3 Macintosh','',189930,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0085.JPG',0.61,1),(293,'IMG_0091.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',143124,'NIKON CORPORATION','NIKON D90','','Horizontal (normal)','2009-07-06T22:09:45','2009-07-06T22:09:45','','2009-07-06T22:09:45','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0091.JPG',0.61,1),(294,'IMG_0035.JPG','JPEG','image/jpeg','','',203134,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0035.JPG',0.61,1),(295,'IMG_0021.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',218927,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0021.JPG',0.61,1),(296,'IMG_0009.JPG','JPEG','image/jpeg','','',51663,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0009.JPG',0.15,1),(297,'metro-middle.jpg','JPEG','image/jpeg','','',1962666,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,1040,1526,'/database/Wallpaper/metro-middle.jpg',1.60,1),(298,'IMG_0008.JPG','JPEG','image/jpeg','','',42279,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0008.JPG',0.15,1),(299,'IMG_0020.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',185325,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0020.JPG',0.61,1),(300,'IMG_0034.JPG','JPEG','image/jpeg','','',143815,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0034.JPG',0.61,1),(301,'IMG_0022.JPG','JPEG','image/jpeg','','',71001,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0022.JPG',0.61,1),(302,'IMG_0036.JPG','JPEG','image/jpeg','Adobe Photoshop CS4 Macintosh','',213193,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0036.JPG',0.61,1),(303,'3IMG_0024.JPG','JPEG','image/jpeg','','',596411,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/3IMG_0024.JPG',3.10,1),(304,'Abstraction-Bubbles-Texture-Color-Creativity.jpg','JPEG','image/jpeg','','',97997,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1920,1200,'/database/Wallpaper/Abstraction-Bubbles-Texture-Color-Creativity.jpg',2.30,1),(305,'Ozix-red-stars.jpg','JPEG','image/jpeg','','',133928,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,744,1392,'/database/Wallpaper/Ozix-red-stars.jpg',1.00,1),(306,'IMG_0037.JPG','JPEG','image/jpeg','','',85137,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0037.JPG',0.61,1),(307,'IMG_0023.JPG','JPEG','image/jpeg','','',228272,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0023.JPG',0.61,1),(308,'IMG_0027.JPG','JPEG','image/jpeg','','',214570,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0027.JPG',0.61,1),(309,'IMG_0033.JPG','JPEG','image/jpeg','','',166923,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0033.JPG',0.61,1),(310,'8IMG_0017.JPG','JPEG','image/jpeg','','',125064,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/8IMG_0017.JPG',3.10,1),(311,'ios7-style-retina-wallpaper.jpg','JPEG','image/jpeg','','',422090,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,2880,1800,'/database/Wallpaper/ios7-style-retina-wallpaper.jpg',5.20,1),(312,'IMG_0032.JPG','JPEG','image/jpeg','','',213473,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0032.JPG',0.61,1),(313,'IMG_0026.JPG','JPEG','image/jpeg','Adobe Photoshop CS5 Macintosh','',173532,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0026.JPG',0.61,1),(314,'6IMG_0027.JPG','JPEG','image/jpeg','','',613236,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/6IMG_0027.JPG',3.10,1),(315,'IMG_0018.JPG','JPEG','image/jpeg','','',54193,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,320,480,'/database/Wallpaper/IMG_0018.JPG',0.15,1),(316,'IMG_0030.JPG','JPEG','image/jpeg','','',139634,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0030.JPG',0.61,1),(317,'IMG_0024.JPG','JPEG','image/jpeg','','',244686,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0024.JPG',0.61,1),(318,'BMFtc_lCAAEOmCY.jpg-large.jpeg','JPEG','image/jpeg','','',163559,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,1023,1820,'/database/Wallpaper/BMFtc_lCAAEOmCY.jpg-large.jpeg',1.90,1),(319,'4IMG_0013.JPG','JPEG','image/jpeg','','',311966,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,1536,2048,'/database/Wallpaper/4IMG_0013.JPG',3.10,1),(320,'BMkwvRbCIAQfI8h.jpg-large.jpeg','JPEG','image/jpeg','','',8872,'','','','','','','','','2024-06-12T10:31:15','','',0,0,0,640,1136,'/database/Wallpaper/BMkwvRbCIAQfI8h.jpg-large.jpeg',0.73,1),(321,'IMG_0025.JPG','JPEG','image/jpeg','','',145014,'','','','Horizontal (normal)','','','','','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0025.JPG',0.61,1),(322,'IMG_0031.JPG','JPEG','image/jpeg','COOLPIX L1V1.2','',167084,'NIKON','COOLPIX L1','','Horizontal (normal)','2006-02-11T13:07:10','2006-02-11T13:07:10','','2006-02-11T13:07:10','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0031.JPG',0.61,1),(323,'IMG_0019.JPG','JPEG','image/jpeg','','',129709,'','','','Horizontal (normal)','','2005-04-29T00:00:00','','2005-04-29T00:00:00','2024-06-12T10:31:15','','',0,0,0,640,960,'/database/Wallpaper/IMG_0019.JPG',0.61,1),(324,'9Bombs_Blue_Ocean_YkViRmE.jpg','JPEG','image/jpeg','','',308012,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1920,1280,'/database/9Bombs_Blue_Ocean_YkViRmE.jpg',2.50,1),(325,'diego_torres_Night_Ocean_YkVqQmY.jpg','JPEG','image/jpeg','','',623750,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/diego_torres_Night_Ocean_YkVqQmY.jpg',2.50,1),(326,'82test.jpg','JPEG','image/jpeg','','',5271706,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,5120,3493,'/database/82test.jpg',17.90,1),(327,'apple_store_oxmoor_steeber.jpg','JPEG','image/jpeg','','',1200867,'','','','','','','','','2023-04-07T07:08:18','','',0,0,0,2560,1440,'/database/apple_store_oxmoor_steeber.jpg',3.70,1),(328,'49test.jpg','JPEG','image/jpeg','','',247852,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/49test.jpg',2.50,1),(329,'2016-02-02_UpsideDown_ROW12246886594_1920x1080.jpg','JPEG','image/jpeg','','',337516,'','','','','','','','','2016-02-03T07:41:40','','',0,0,0,1920,1080,'/database/2016-02-02_UpsideDown_ROW12246886594_1920x1080.jpg',2.10,1),(330,'iPadPro_Wallpaper.png','PNG','image/png','','',32231940,'','','','Rotate 270 CW','2020-03-18T17:09:36','','','','2023-04-07T07:08:18','','',0,0,0,4084,5450,'/database/iPadPro_Wallpaper.png',22.30,1),(331,'14test.jpg','JPEG','image/jpeg','','',332132,'','','','','','','','','2016-02-03T07:43:16','','',0,0,0,1920,1080,'/database/14test.jpg',2.10,1),(332,'66test.jpg','JPEG','image/jpeg','','',300768,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1812,1280,'/database/66test.jpg',2.30,1),(333,'2015-12-02_BearGlacierLake_ROW11778213520_1920x1080.jpg','JPEG','image/jpeg','','',331312,'','','','','','','','','2016-02-03T07:43:36','','',0,0,0,1920,1080,'/database/2015-12-02_BearGlacierLake_ROW11778213520_1920x1080.jpg',2.10,1),(334,'76test.jpg','JPEG','image/jpeg','','',446850,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/76test.jpg',2.50,1),(335,'57test.gif','GIF','image/gif','','',1370088,'','','','','','','','','2023-04-07T07:08:18','','',1.14,0,0,500,281,'/database/57test.gif',0.14,1),(336,'38__test.jpg','JPEG','image/jpeg','','',383286,'','','','Horizontal (normal)','','','','','2023-04-07T07:08:19','','',0,0,0,1920,1280,'/database/38__test.jpg',2.50,1),(337,'The_Baja_-_MacBook_Pro_Wallpaper.jpg','JPEG','image/jpeg','','',2097891,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2880,1800,'/database/The_Baja_-_MacBook_Pro_Wallpaper.jpg',5.20,1),(338,'50test.jpg','JPEG','image/jpeg','','',133154,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1920,1280,'/database/50test.jpg',2.50,1),(339,'32test.jpg','JPEG','image/jpeg','','',225720,'','','','','','','','','2015-10-22T14:23:16','','',0,0,0,1920,1280,'/database/32test.jpg',2.50,1),(340,'03045_spectrumarray_1680x1050.jpg','JPEG','image/jpeg','Adobe Photoshop CS6 (Macintosh)','',1368953,'Canon','Canon EOS 5D Mark II','EF24-70mm f/2.8L USM','Horizontal (normal)','2012-02-04T05:28:18','2012-02-04T05:28:18','','2012-02-04T05:28:18','2023-04-07T07:08:18','','',0,0,0,1680,1050,'/database/03045_spectrumarray_1680x1050.jpg',1.80,1),(341,'Lies_Thru_a_Lens_The_Yellow_Fields_YkVjR2E.jpg','JPEG','image/jpeg','','',1141526,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1885,1280,'/database/Lies_Thru_a_Lens_The_Yellow_Fields_YkVjR2E.jpg',2.40,1),(342,'photo-1464621922360-27f3bf0eca75.jpeg','JPEG','image/jpeg','','',508735,'','','','','','','','','2023-04-07T07:08:19','','',0,0,0,2702,1801,'/database/photo-1464621922360-27f3bf0eca75.jpeg',4.90,1),(343,'production_id_4237839__2160p_.mp4','MP4','video/mp4','','',34464883,'','','','','2020-04-25T11:45:05','','','','2023-10-11T07:36:54','2020-04-25T11:45:05','2020-04-25T11:45:05',15.5572083333333,0,0,3840,2160,'/database/production_id_4237839__2160p_.mp4',8.30,1),(344,'pexels-ibrahim-bennett-18522098__Original_.mp4','MP4','video/mp4','','',93075412,'','','','','2023-09-26T03:07:21','','','','2023-10-11T07:37:10','2023-09-26T03:07:21','2023-09-26T03:07:21',26.667,0,0,1920,1080,'/database/pexels-ibrahim-bennett-18522098__Original_.mp4',2.10,1),(345,'John_Fowler_A_Branch_on_The_Beach_YkVgQGA.jpg','JPEG','image/jpeg','','',672512,'','','','','','','','','2015-10-22T14:23:20','','',0,0,0,1937,1280,'/database/John_Fowler_A_Branch_on_The_Beach_YkVgQGA.jpg',2.50,1),(346,'48test.jpg','JPEG','image/jpeg','','',651620,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1706,1280,'/database/48test.jpg',2.20,1),(347,'testHeic.heic','HEIC','image/heic','12.1.1','',1214692,'Apple','iPhone X','iPhone X back dual camera 4mm f/1.8','Rotate 90 CW','2019-01-07T18:58:48','','','2019-01-07T18:58:48','2023-06-26T01:39:53','','',0,37.6774666666667,-122.467505555556,4032,3024,'/database/testHeic.heic',12.20,1),(348,'IMG_4787.HEIC','HEIC','image/heic','16.7','',1564596,'Apple','iPhone 11 Pro Max','iPhone 11 Pro Max back triple camera 4.25mm f/1.8','Rotate 90 CW','2023-10-04T12:49:03','','','2023-10-04T12:49:03','2023-10-04T12:49:03','','',0,37.7307916666667,-122.407341666667,4032,3024,'/database/IMG_4787.HEIC',12.20,1),(349,'103test.jpg','JPEG','image/jpeg','','',4212139,'','','','','','','','','2023-10-11T07:36:19','','',0,0,0,3622,5433,'/database/103test.jpg',19.70,1),(350,'15test.jpg','JPEG','image/jpeg','','',340708,'','','','','','','','','2016-02-03T07:43:02','','',0,0,0,1920,1080,'/database/15test.jpg',2.10,1),(351,'pexels-israel-torres-18290834.jpg','JPEG','image/jpeg','','',7418174,'','','','','','','','','2023-10-11T07:35:55','','',0,0,0,5061,8192,'/database/pexels-israel-torres-18290834.jpg',41.50,1),(352,'alan_f_Eiffel_Tower__akJhSQ.jpg','JPEG','image/jpeg','','',705884,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1981,1280,'/database/alan_f_Eiffel_Tower__akJhSQ.jpg',2.50,1),(353,'production_id_4911644__2160p_.mp4','MP4','video/mp4','','',46274500,'','','','','2020-07-20T15:02:55','','','','2023-10-10T23:14:12','2020-07-20T15:02:55','2020-07-20T15:02:55',17.0503666666667,0,0,3840,2160,'/database/production_id_4911644__2160p_.mp4',8.30,1),(354,'77test.jpg','JPEG','image/jpeg','','',407642,'','','','','','','','','2015-10-22T14:23:18','','',0,0,0,1706,1280,'/database/77test.jpg',2.20,1);
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
    DECLARE durationDisplay VARCHAR(20); -- Display duration time for videos
    DECLARE mediaType VARCHAR(7); -- Media Type for ENUM (Photo/Video/Live/Unknown)
	DECLARE generateMediaID VARCHAR(15); -- Create a random string for an URL
    

    -- Extract MIME type prefix (e.g., 'image' from 'image/png')
    SET mimeTypePrefix = SUBSTRING_INDEX(NEW.MIMEType, '/', 1);  -- 'image' from 'image/png'

    -- Determine the smallest valid date among multiple fields. Use CASE statements to handle invalid date values
    SET smallestDate = LEAST(
        IF((NEW.CreateDate = '' OR NEW.CreateDate = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.CreateDate),
        IF((NEW.DateCreated = '' OR NEW.DateCreated = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.DateCreated),
        IF((NEW.CreationDate = '' OR NEW.CreationDate = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.CreationDate),
        IF((NEW.DateTimeOriginal = '' OR NEW.DateTimeOriginal = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.DateTimeOriginal),
        IF((NEW.FileModifyDate = '' OR NEW.FileModifyDate = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.FileModifyDate),
        IF((NEW.MediaCreateDate = '' OR NEW.MediaCreateDate = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.MediaCreateDate),
        IF((NEW.MediaModifyDate = '' OR NEW.MediaModifyDate = '0000:00:00 00:00:00'), '9999-12-31 23:59:59', NEW.MediaModifyDate)
    );
    
    -- Handle camera type association:
    -- Check if Make, Model, and LensModel are not NULL or empty
    IF NEW.Make IS NOT NULL AND NEW.Make != '' 
       AND NEW.Model IS NOT NULL AND NEW.Model != '' 
       AND NEW.LensModel IS NOT NULL AND NEW.LensModel != '' THEN
        
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
                    IF ( (NEW.Duration > 6), 'Video', 'Live' ), 'Unknown') );
    
    -- Generate unique media URL string
    SET generateMediaID = CONCAT(
        CAST(NEW.import_id AS CHAR),
        SUBSTRING(REPLACE(UUID(), '-', ''), 1, 15 - LENGTH(CAST(NEW.import_id AS CHAR)))
    );

    -- Insert into Media table
    INSERT INTO Media (FileName, FileType, FileExt, Software, FileSize, CameraType, CreateDate, URL) 
    VALUES (NEW.FileName, mediaType, NEW.FileType, NEW.Software, NEW.FileSize, cameraTypeId,
    STR_TO_DATE(smallestDate, '%Y-%m-%d %H:%i:%s'), generateMediaID);

    -- Reuse this variable as media_id for the last Media inserted
    SET generateMediaID = LAST_INSERT_ID();


    -- ///////////// NOTE ///////////////////
    -- The account number needs to be added when the user is created, so we can identify which user uploaded these media.
    -- It is necessary to insert into the UploadBy table (account, media_id).
    INSERT INTO UploadBy (account, media)
    VALUES (NEW.account, generateMediaID);

    -- Insert into SourceFile table
    INSERT INTO SourceFile (media, SourceFile, MIMEType) 
    VALUES (generateMediaID, NEW.SourceFile, NEW.MIMEType);

     -- Handle specific types of media
    IF mediaType = 'Photo' THEN
        
        -- Insert into Photo table
        INSERT INTO Photo (media, Orientation, ImageWidth, ImageHeight, Megapixels)
        VALUES (generateMediaID, NEW.Orientation, NEW.ImageWidth, NEW.ImageHeight, ROUND(NEW.Megapixels, 1) );

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
        VALUES (generateMediaID, NEW.Title, NEW.Duration, durationDisplay);

    ELSEIF mediaType = 'Live' THEN
        -- Insert into Live table
        INSERT INTO Live ( media, Title, Duration) 
        VALUES (generateMediaID, NEW.Title, NEW.Duration);
    
    -- Ignore unknown or others formats from now
    END If;

    -- Handle GPS data
    IF NEW.GPSLatitude IS NOT NULL AND NEW.GPSLatitude != '' 
       AND NEW.GPSLongitude IS NOT NULL AND NEW.GPSLongitude != '' THEN

        -- Insert data into another table (e.g., Location) if GPSLatitude and GPSLongitude are valid
        INSERT INTO Location (media, GPSLatitude, GPSLongitude) 
        VALUES (generateMediaID, NEW.GPSLatitude, NEW.GPSLongitude );

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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Live`
--

LOCK TABLES `Live` WRITE;
/*!40000 ALTER TABLE `Live` DISABLE KEYS */;
INSERT INTO `Live` VALUES (14,NULL,NULL,5,'');
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
INSERT INTO `Location` VALUES (6,NULL,NULL,NULL,37.7307888888889,-122.407355555556),(163,NULL,NULL,NULL,37.7308777777778,-122.407386111111),(347,NULL,NULL,NULL,37.6774666666667,-122.467505555556),(348,NULL,NULL,NULL,37.7307916666667,-122.407341666667);
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
  `FileName` varchar(255) DEFAULT NULL,
  `CreateDate` datetime DEFAULT NULL,
  `FileSize` bigint unsigned DEFAULT NULL,
  `HashCode` varchar(256) DEFAULT NULL,
  `URL` text,
  `Privacy` tinyint unsigned DEFAULT '1',
  `Hidden` tinyint unsigned DEFAULT '0',
  `Favorite` tinyint unsigned DEFAULT '0',
  `DeletedStatus` tinyint unsigned DEFAULT '0',
  `DeletionDate` timestamp NULL DEFAULT NULL,
  `Restricted` tinyint unsigned DEFAULT '0',
  `CameraType` int unsigned DEFAULT NULL,
  `TimeUpload` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `FileExt` varchar(10) DEFAULT NULL,
  `Software` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`media_id`),
  KEY `FK_MEDIA_CAMERATYPE_ID_idx` (`CameraType`),
  KEY `Media_CreateDate_idx` (`CreateDate`,`FileType`),
  CONSTRAINT `FK_MEDIA_SOURCEFILE_ID` FOREIGN KEY (`CameraType`) REFERENCES `CameraType` (`camera_id`)
) ENGINE=InnoDB AUTO_INCREMENT=355 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Media`
--

LOCK TABLES `Media` WRITE;
/*!40000 ALTER TABLE `Media` DISABLE KEYS */;
INSERT INTO `Media` VALUES (1,'Photo','JFL-08072018-IMACS-MACBOOKS.png','2023-04-07 07:08:19',3415073,NULL,'1a28c1180c6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(2,'Photo','72test.jpg','2015-10-22 14:23:16',1066206,NULL,'2a28c1d6ac6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(3,'Photo','Jean-Alain_Foods_with_Love_YkVkRmY.jpg','2015-10-22 14:23:16',266472,NULL,'3a28c2436c6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(4,'Video','video__2160p_.mp4','2019-11-02 08:33:53',71070000,NULL,'4a28c2e90c6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(5,'Photo','2015-12-01_KenrokuenGarden_ROW11637035698_1920x1080.jpg','2016-02-03 07:43:40',355238,NULL,'5a28c37bec6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(6,'Photo','IMG_4788.HEIC','2023-10-04 12:49:08',1219043,NULL,'6a28c452ec6eb11',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.7'),(7,'Photo','33t_est.jpg','2015-10-22 14:23:20',673745,NULL,'7a28c4b8cc6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(8,'Photo','US_Navy_050102-N-9593M-040_A_village_near_the_coast_of_Sumatra_lays_in_ruin_after_the_Tsunami_that_struck_South_East_Asia.jpg','2005-01-02 00:00:00',393164,NULL,'8a28c5398c6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS Macintosh'),(9,'Video','pexels-nataliya-vaitkevich-8468210__1080p_.mp4','2021-06-24 15:25:45',5615870,NULL,'9a28c5af0c6eb11',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(10,'Photo','Diego_Torres_Silvestre_Moonlight..._ZkVkRQ.jpg','2015-10-22 14:23:18',199318,NULL,'10a28c61e4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(11,'Video','93test.mp4','2023-03-29 21:52:28',41435560,NULL,'11a28c67b6c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(12,'Photo','diego_torres_London_City_YkVqQmU.jpg','2015-10-22 14:23:20',909924,NULL,'12a28c71f2c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(13,'Photo','Matt_JP_Afternoon_Swim_ZENqRQ.jpg','2015-10-22 14:23:18',373462,NULL,'13a28c7a62c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(14,'Live','production_id_4779866__1080p_.mp4','2020-07-02 19:36:22',3257706,NULL,'14a28c7f94c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(15,'Photo','kali-layers-16x9.png','2022-03-20 01:22:26',732875,NULL,'15a28c8d7cc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(16,'Photo','_83_test.jpg','2015-10-22 14:23:16',182363,NULL,'16a28c929ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(17,'Photo','Foto-Rabe_Gooses__dream_YkVqQmM.jpg','2015-10-22 14:23:16',287602,NULL,'17a28c9844c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(18,'Photo','JulienDft_Photo_lock_a0RgRg.jpg','2015-10-22 14:23:18',571537,NULL,'18a28c9de4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(19,'Video','pexels-sunsetoned-5913482__2160p_.mp4','2020-11-17 18:40:23',21104653,NULL,'19a28ca514c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(20,'Photo','pexels-leeloo-thefirst-5379765.jpg','2023-10-11 07:35:17',3284545,NULL,'20a28cab7cc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(21,'Video','Mariah_Carey_-_All_I_Want_for_Christmas_Is_You__Make_My_Wish_Come_True_Edition_.mp4','2023-12-10 15:27:38',89285777,NULL,'21a28cb1c6c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(22,'Photo','Rough_Seas_-_MacBook_Pro_Wallpaper.jpg','2023-04-07 07:08:19',924968,NULL,'22a28cb702c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(23,'Photo','pexels-filipp-romanovski-17275905.jpg','2023-10-11 07:36:00',4013440,NULL,'23a28cbc0cc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(24,'Photo','35test.jpg','2015-10-22 14:23:18',600618,NULL,'24a28cc12ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(25,'Photo','Gic_Shade_of_flowers_YkVlSGo.jpg','2015-10-22 14:23:18',1083466,NULL,'25a28ccb48c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(26,'Photo','me_nicoll_Pencil_ZUFjQg.jpg','2015-10-22 14:23:18',241883,NULL,'26a28cd070c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(27,'Photo','Glacier_Falls_-_MacBook_Pro_Wallpaper.jpg','2023-04-07 07:08:19',719566,NULL,'27a28cd598c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(28,'Photo','macOS-Sierra-Wallpaper-Macbook-Wallpaper.jpg','2023-04-07 07:08:19',2130212,NULL,'28a28cdc50c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Pixelmator 3.4'),(29,'Photo','ashley_Son_Airplane_a0ViSA.jpg','2015-10-22 14:23:18',408543,NULL,'29a28ce18cc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(30,'Photo','2016-02-02_setsubun_JA-JP11957231259_1920x1080.jpg','2016-02-03 07:41:28',215846,NULL,'30a28ce6c8c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(31,'Photo','pexels-perry-wunderlich-5826451.jpg','2023-10-11 07:36:40',573856,NULL,'31a28ced58c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(32,'Photo','71test.jpg','2023-04-07 07:08:19',1643832,NULL,'32a28cf384c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Pixelmator 3.7.3'),(33,'Photo','13test.jpg','2016-02-03 07:43:18',336213,NULL,'33a28cf924c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(34,'Photo','IMG_4782.HEIC','2023-10-03 08:30:33',1123164,NULL,'34a28d054ac6eb1',1,0,0,0,NULL,0,2,'2024-12-30 20:21:19','HEIC','16.7'),(35,'Photo','pexels-lokman-sevim-17788447.jpg','2023-10-11 07:35:25',4173747,NULL,'35a28d14f4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(36,'Photo','IMG_0438.JPG','2024-06-12 10:31:15',821675,NULL,'36a28d1df0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(37,'Photo','IMG_0439.JPG','2024-06-12 10:31:15',898979,NULL,'37a28d2778c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(38,'Photo','IMG_0416.JPG','2024-06-12 10:31:15',288253,NULL,'38a28d2dccc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(39,'Photo','IMG_0417.JPG','2024-06-12 10:31:15',248134,NULL,'39a28d3696c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(40,'Photo','IMG_0429.JPG','2000-01-01 00:00:00',1064685,NULL,'40a28d3ec0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(41,'Photo','IMG_0428.JPG','2024-06-12 10:31:15',622681,NULL,'41a28d4b54c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','www.meitu.com'),(42,'Photo','IMG_0513.JPG','2011-08-27 00:00:00',1452125,NULL,'42a28d51b2c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(43,'Photo','IMG_0507.JPG','2024-06-12 10:31:15',1199480,NULL,'43a28d57c0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(44,'Photo','IMG_0498.JPG','2024-06-12 10:31:15',1138062,NULL,'44a28d5d6ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(45,'Photo','IMG_0467.JPG','2024-06-12 10:31:15',534227,NULL,'45a28d64e0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(46,'Photo','IMG_0473.JPG','2024-06-12 10:31:15',622699,NULL,'46a28d723cc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(47,'Photo','IMG_0472.JPG','2024-06-12 10:31:15',431167,NULL,'47a28d79bcc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Windows'),(48,'Photo','IMG_0466.JPG','2024-06-12 10:31:15',967030,NULL,'48a28d7f66c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(49,'Photo','IMG_0499.JPG','2024-06-12 10:31:15',693081,NULL,'49a28d86d2c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(50,'Photo','IMG_0506.JPG','2024-06-12 10:31:15',881713,NULL,'50a28d94c4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(51,'Photo','IMG_0512.JPG','2024-06-12 10:31:15',1429390,NULL,'51a28da0a4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(52,'Photo','IMG_0504.JPG','2024-06-12 10:31:15',1001284,NULL,'52a28da810c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(53,'Photo','IMG_0510.JPG','2024-06-12 10:31:15',314034,NULL,'53a28dadc4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','www.meitu.com'),(54,'Photo','IMG_0470.JPG','2024-06-12 10:31:15',771573,NULL,'54a28db526c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','ACDSee Pro 5'),(55,'Photo','IMG_0464.JPG','2024-06-12 10:31:15',215167,NULL,'55a28dbcb0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(56,'Photo','IMG_0458.JPG','2024-06-12 10:31:15',753486,NULL,'56a28dc638c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(57,'Photo','IMG_0459.JPG','2011-06-03 16:44:25',1595315,NULL,'57a28dd362c6eb1',1,0,0,0,NULL,0,3,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Macintosh'),(58,'Photo','IMG_0465.JPG','2024-06-12 10:31:15',698430,NULL,'58a28dd98ec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(59,'Photo','IMG_0471.JPG','2024-06-12 10:31:15',449131,NULL,'59a28ddfc4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(60,'Photo','IMG_0511.JPG','2024-06-12 10:31:15',709270,NULL,'60a28e01acc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','ACDSee Pro 5'),(61,'Photo','IMG_0505.JPG','2024-06-12 10:31:15',623513,NULL,'61a28e07ecc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(62,'Photo','IMG_0501.JPG','2011-08-12 01:24:52',526219,NULL,'62a28e0ddcc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(63,'Photo','IMG_0515.JPG','2024-06-12 10:31:15',2145959,NULL,'63a28e13a4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(64,'Photo','IMG_0449.JPG','2024-06-12 10:31:15',574543,NULL,'64a28e19a8c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(65,'Photo','IMG_0475.JPG','2024-06-12 10:31:15',1024781,NULL,'65a28e1f66c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(66,'Photo','IMG_0461.JPG','2024-06-12 10:31:15',769713,NULL,'66a28e2510c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(67,'Photo','IMG_0460.JPG','2024-06-12 10:31:15',725972,NULL,'67a28e2abac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(68,'Photo','IMG_0474.JPG','2024-06-12 10:31:15',1156237,NULL,'68a28e306ec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (13.0 20120305.m.415 2012/03/05:21:00:00)  (Macintosh)'),(69,'Photo','IMG_0448.JPG','2024-06-12 10:31:15',673094,NULL,'69a28e365ec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(70,'Photo','IMG_0514.JPG','2024-06-12 10:31:15',601072,NULL,'70a28e3c08c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(71,'Photo','IMG_0500.JPG','2011-08-15 00:00:00',1681743,NULL,'71a28e41d0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(72,'Photo','IMG_0516.JPG','2011-07-16 00:00:00',703331,NULL,'72a28e53fac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(73,'Photo','IMG_0502.JPG','2011-01-31 00:00:00',615557,NULL,'73a28e5b52c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(74,'Photo','IMG_0489.JPG','2024-06-12 10:31:15',776128,NULL,'74a28e6192c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(75,'Photo','IMG_0462.JPG','2024-06-12 10:31:15',554237,NULL,'75a28e67b4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(76,'Photo','IMG_0476.JPG','2024-06-12 10:31:15',1388015,NULL,'76a28e6dccc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(77,'Photo','IMG_0477.JPG','2011-11-11 11:14:48',347814,NULL,'77a28e73dac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(78,'Photo','IMG_0463.JPG','2010-07-27 00:00:00',953815,NULL,'78a28e7a1ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(79,'Photo','IMG_0488.JPG','2010-12-03 00:00:00',667872,NULL,'79a28e8014c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(80,'Photo','IMG_0503.JPG','2024-06-12 10:31:15',803044,NULL,'80a28e9db0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(81,'Photo','IMG_0517.JPG','2011-08-14 00:00:00',788304,NULL,'81a28eaa62c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(82,'Photo','IMG_0485.JPG','2007-11-02 14:51:25',1392621,NULL,'82a28eb908c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Pixelmator 2.0.1'),(83,'Photo','IMG_0491.JPG','2024-06-12 10:31:15',760983,NULL,'83a28ebf52c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(84,'Photo','IMG_0446.JPG','2024-06-12 10:31:15',968967,NULL,'84a28ec592c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(85,'Photo','IMG_0452.JPG','2024-06-12 10:31:15',668604,NULL,'85a28ecbbec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(86,'Photo','IMG_0453.JPG','2024-06-12 10:31:15',1507390,NULL,'86a28ed582c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(87,'Photo','IMG_0447.JPG','2024-06-12 10:31:15',743832,NULL,'87a28ee0fec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(88,'Photo','IMG_0490.JPG','2024-06-12 10:31:15',1802865,NULL,'88a28eead6c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(89,'Photo','IMG_0484.JPG','2024-06-12 10:31:15',589782,NULL,'89a28ef486c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(90,'Photo','IMG_0492.JPG','2024-06-12 10:31:15',634164,NULL,'90a28efa8ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Windows'),(91,'Photo','IMG_0486.JPG','2024-06-12 10:31:15',1311077,NULL,'91a28f00acc6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(92,'Photo','IMG_0451.JPG','2024-06-12 10:31:15',757842,NULL,'92a28f06b0c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(93,'Photo','IMG_0479.JPG','2024-06-12 10:31:15',489375,NULL,'93a28f0cb4c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Windows'),(94,'Photo','IMG_0478.JPG','2024-06-12 10:31:15',901269,NULL,'94a28f2064c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(95,'Photo','IMG_0444.JPG','2024-06-12 10:31:15',930863,NULL,'95a28f29cec6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(96,'Photo','IMG_0450.JPG','2024-06-12 10:31:15',1021749,NULL,'96a28f3c52c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(97,'Photo','IMG_0487.JPG','2024-06-12 10:31:15',537363,NULL,'97a28f4756c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(98,'Photo','IMG_0493.JPG','2024-06-12 10:31:15',1039210,NULL,'98a28f5278c6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(99,'Photo','IMG_0508.JPG','2024-06-12 10:31:15',705334,NULL,'99a28f5d4ac6eb1',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(100,'Photo','IMG_0497.JPG','2024-06-12 10:31:15',678449,NULL,'100a28f6650c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(101,'Photo','IMG_0483.JPG','2024-06-12 10:31:15',1704202,NULL,'101a28f6edec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(102,'Photo','IMG_0468.JPG','2024-06-12 10:31:15',965272,NULL,'102a28f792ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Windows'),(103,'Photo','IMG_0454.JPG','2024-06-12 10:31:15',1398272,NULL,'103a28f8f36c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(104,'Photo','IMG_0440.JPG','2024-06-12 10:31:15',695077,NULL,'104a28f97f6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(105,'Photo','IMG_0441.JPG','2024-06-12 10:31:15',932577,NULL,'105a28fa02ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(106,'Photo','IMG_0455.JPG','2024-06-12 10:31:15',1127748,NULL,'106a28fa7e6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(107,'Photo','IMG_0469.JPG','2011-04-16 00:00:00',475838,NULL,'107a28fb010c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(108,'Photo','IMG_0496.JPG','2024-06-12 10:31:15',834244,NULL,'108a28fc3fcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Windows'),(109,'Photo','IMG_0509.JPG','2024-06-12 10:31:15',431450,NULL,'109a28fcbe0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Windows'),(110,'Photo','123__IMG_0425.JPG','2011-06-05 07:08:00',1416088,NULL,'110a28fd5f4c6eb',1,0,0,0,NULL,0,3,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Macintosh'),(111,'Photo','IMG_0480.JPG','2024-06-12 10:31:15',1079169,NULL,'111a28fdd4cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Windows'),(112,'Photo','IMG_0494.JPG','2024-06-12 10:31:15',360795,NULL,'112a28fe4e0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','www.meitu.com'),(113,'Photo','IMG_0443.JPG','2024-06-12 10:31:15',656614,NULL,'113a28febfcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(114,'Photo','IMG_0457.JPG','2011-07-18 00:00:00',488127,NULL,'114a28ff34ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(115,'Photo','IMG_0456.JPG','2024-06-12 10:31:15',1257625,NULL,'115a28ffa52c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(116,'Photo','IMG_0442.JPG','2024-06-12 10:31:15',915038,NULL,'116a2900132c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(117,'Photo','IMG_0495.JPG','2024-06-12 10:31:15',1429968,NULL,'117a29009f2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(118,'Photo','IMG_0431.JPG','2024-06-12 10:31:15',531951,NULL,'118a2901488c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(119,'Photo','IMG_0419.JPG','2011-07-28 00:00:00',617757,NULL,'119a2901dc0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(120,'Photo','IMG_0418.JPG','2024-06-12 10:31:15',938360,NULL,'120a29024f0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(121,'Photo','IMG_0430.JPG','2024-06-12 10:31:15',1525889,NULL,'121a2902c34c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(122,'Photo','IMG_0432.JPG','2006-11-11 13:57:52',755527,NULL,'122a2903684c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Pixelmator 2.0.1'),(123,'Photo','IMG_0426.JPG','2024-06-12 10:31:15',754074,NULL,'123a2903f12c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(124,'Photo','__7________IM_G_0423.JPG','2010-08-03 18:57:39',1988234,NULL,'124a29046bac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Pixelmator 2.0.1'),(125,'Photo','IMG_0427.JPG','2010-12-04 05:36:38',1534789,NULL,'125a2904e08c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(126,'Photo','IMG_0433.JPG','2024-06-12 10:31:15',457483,NULL,'126a29055f6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(127,'Photo','IMG_0437.JPG','2024-06-12 10:31:15',669788,NULL,'127a2905d30c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(128,'Photo','IMG_0422.JPG','2011-10-20 00:00:00',817581,NULL,'128a290642ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(129,'Photo','IMG_0436.JPG','2024-06-12 10:31:15',682538,NULL,'129a2906b5ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(130,'Photo','WWDC-AR7-iPad.png','2024-06-12 10:31:15',2269323,NULL,'130a2907252c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(131,'Photo','IMG_0420.JPG','2010-10-28 00:00:00',874273,NULL,'131a2907a72c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5.1 Macintosh'),(132,'Photo','IMG_0434.JPG','2024-06-12 10:31:15',1066681,NULL,'132a290826ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(133,'Photo','IMG_0435.JPG','2024-06-12 10:31:15',1104210,NULL,'133a2908a26c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop 7.0'),(134,'Photo','IMG_0421.JPG','2011-07-27 00:00:00',821005,NULL,'134a29091d8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(135,'Photo','85test.jpg','2015-10-22 14:23:18',797214,NULL,'135a29099c6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(136,'Photo','4____test.gif','2023-04-07 07:08:18',8807531,NULL,'136a290a1c8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(137,'Photo','Luke_Ma_Cherry_Soda_a0RhRQ.jpg','2015-10-22 14:23:20',258785,NULL,'137a290a984c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(138,'Photo','inspiredimages_Brown_beach_YkVqQ2Y.jpg','2015-10-22 14:23:16',863722,NULL,'138a290b17cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(139,'Video','video__1080p__2.mp4','2020-01-26 09:28:43',8430151,NULL,'139a290b956c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(140,'Photo','wallpaper-Dark.jpg','2023-04-30 02:47:17',4545703,NULL,'140a290c1f8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(141,'Photo','2016-02-01_IemanjaFlowers_PT-BR10970450658_1920x1080.jpg','2016-02-03 07:41:46',338867,NULL,'141a290ca22c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(142,'Photo','17_test.jpg','2016-02-03 07:43:58',352445,NULL,'142a290d1fcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(143,'Photo','40_test.gif','2023-04-07 07:08:19',393223,NULL,'143a290db48c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(144,'Photo','FrankyChou_Travel_YkVgQWs.jpg','2015-10-22 14:23:20',657670,NULL,'144a290e390c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(145,'Photo','pexels-morteza-ghanbari-18556807.jpg','2023-10-11 07:35:46',7606076,NULL,'145a290ebb0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(146,'Photo','pexels-manish-jangid-18037510.jpg','2023-10-11 07:36:24',2480398,NULL,'146a290f3a8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(147,'Photo','2015-11-23_OctoberMorning_ROW15719492089_1920x1080.jpg','2016-02-03 07:42:40',189110,NULL,'147a290fbaac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(148,'Photo','Foundry_Sweet_Doughnuts_YkVqRWY.jpg','2015-10-22 14:23:20',596023,NULL,'148a29103a2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(149,'Photo','21test.jpg','2016-02-03 07:41:36',346803,NULL,'149a2910b9ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(150,'Photo','43test.jpg','2015-10-22 14:23:20',639210,NULL,'150a29113cec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(151,'Video','61test.mp4','2023-09-30 21:03:07',8589626,NULL,'151a2911c52c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(152,'Photo','108test.jpg','2023-10-11 07:36:13',2022829,NULL,'152a2912526c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(153,'Video','production_id_4763824__2160p_.mp4','2020-06-30 16:02:30',34082855,NULL,'153a2912d6ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(154,'Photo','Foundry_Morning_with_Milk_YkVkRWQ.jpg','2015-10-22 14:23:20',193255,NULL,'154a291361ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(155,'Video','pexels-kammeran-gonzalezkeola-17838377__Original_.mp4','2023-03-19 02:16:43',76182155,NULL,'155a2913e6cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','M4V',''),(156,'Video','pexels-kammeran-gonzalezkeola-17838377__2160p_.mp4','2023-08-02 22:46:35',64287648,NULL,'156a2914704c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(157,'Photo','2015-11-30_OceanSwimRace_EN-AU11288679332_1920x1080.jpg','2016-02-03 07:43:48',329398,NULL,'157a2914f92c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(158,'Photo','Mathulak_Flickr_Boats_with_Sunset_akJjQA.jpg','2015-10-22 14:23:18',328399,NULL,'158a29158cac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(159,'Video','production_id_4873244__2160p_.mp4','2020-07-15 07:21:10',17093064,NULL,'159a2917382c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(160,'Photo','81test.jpg','2023-04-07 07:08:19',959860,NULL,'160a2917d6ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(161,'Photo','Marco_Tanzi_City_At_Night_ZEZiRQ.jpg','2015-10-22 14:23:16',465692,NULL,'161a29186c4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(162,'Photo','diego_torres_Worbarrow_Bay_YkVqQmA.jpg','2015-10-22 14:23:16',623685,NULL,'162a2918fd4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(163,'Photo','image020918_003511.jpg','2018-09-01 21:15:47',2892840,NULL,'163a2919d4ec6eb',1,0,0,0,NULL,0,4,'2024-12-30 20:21:19','JPEG','11.4.1'),(164,'Video','MP4Test.mp4','2014-12-05 14:48:37',141777221,NULL,'164a291a816c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(165,'Video','IMG_3324.MOV','2023-04-30 13:56:10',19332894,NULL,'165a291b22ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MOV','16.4.1'),(166,'Photo','Coffee.gif','2023-04-07 07:08:19',903003,NULL,'166a291bb8ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(167,'Photo','75test.jpg','2015-10-22 14:23:14',640165,NULL,'167a291c486c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(168,'Photo','12_test.jpg','2016-02-03 07:42:28',274137,NULL,'168a291cdd2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(169,'Video','video__1080p_.mp4','2019-12-12 10:58:16',7960318,NULL,'169a291d6bac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(170,'Photo','03185_calmness_1680x1050.jpg','2012-08-30 17:38:54',1889921,NULL,'170a291e380c6eb',1,0,0,0,NULL,0,5,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(171,'Photo','39test.jpg','2015-10-22 14:23:20',756085,NULL,'171a291ecccc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(172,'Photo','5test.jpg','2016-02-03 07:42:34',342887,NULL,'172a291f618c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(173,'Photo','snow-winter-wood-tree-road-night-nature-imac-27.jpg','2017-01-01 15:38:40',4368706,NULL,'173a29202cac6eb',1,0,0,0,NULL,0,6,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CC (Macintosh)'),(174,'Photo','16test.jpg','2016-02-03 07:43:10',343750,NULL,'174a2920c5cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(175,'Photo','Lara_Danielle_Love_Hearts_YkViQGM.jpg','2015-10-22 14:23:18',386082,NULL,'175a29215b2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(176,'Photo','pexels-zehra-16983649.jpg','2023-10-11 07:35:36',4954345,NULL,'176a2921ef4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(177,'Photo','89test.jpg','2023-04-07 07:08:19',950382,NULL,'177a29227e6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(178,'Photo','pexels-alina-vilchenko-17435490.jpg','2023-10-11 07:35:20',5118776,NULL,'178a29230d8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(179,'Photo','noIMG_3336.HEIC','2023-04-30 14:13:07',1481002,NULL,'179a2923c4ac6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(180,'Photo','what__.HEIC','2023-04-30 14:14:32',1720444,NULL,'180a2925220c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(181,'Photo','BORX8909.jpg','2017-02-05 10:59:41',234115,NULL,'181a2925bc6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(182,'Photo','IMG_3323.HEIC','2023-04-30 13:56:05',2541260,NULL,'182a2926738c6eb',1,0,0,0,NULL,0,2,'2024-12-30 20:21:19','HEIC','16.4.1'),(183,'Photo','anastasia-petrova-193830-unsplash.jpg','2023-04-07 07:08:18',3525674,NULL,'183a2927084c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(184,'Photo','giphy-4.gif','2019-08-20 10:59:28',1761740,NULL,'184a2927994c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(185,'Photo','IMG_3322.HEIC','2023-04-30 13:51:27',1332244,NULL,'185a2928538c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(186,'Photo','IMG_3337.HEIC','2023-04-30 14:13:43',2184927,NULL,'186a29290d2c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(187,'Photo','IMG_3321.HEIC','2023-04-30 13:50:28',2023902,NULL,'187a2929e1ac6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(188,'Photo','flask4-2.gif','2019-08-20 10:59:43',706484,NULL,'188a292a7d4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(189,'Photo','what___IMG_3339.HEIC','2023-04-30 14:14:36',1927029,NULL,'189a292b3aac6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(190,'Photo','70458175599__6CDFAA94-B0F7-4A66-938B-04CEDE714AC0.HEIC','2023-04-30 14:09:15',2376555,NULL,'190a292bf58c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(191,'Photo','toy1.jpeg','2012-12-08 00:00:00',1378240,NULL,'191a292c8a4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CC (Macintosh)'),(192,'Photo','flask3.gif','2019-08-20 10:59:42',6591982,NULL,'192a292d1bec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(193,'Photo','IMG_3326_Hello.HEIC','2023-04-30 14:11:24',1749194,NULL,'193a292dd6cc6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(194,'Photo','IMG_3330.HEIC','2023-04-30 14:12:20',1201166,NULL,'194a292e910c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.4.1'),(195,'Photo','ongliong11-color.png','2023-04-07 07:08:19',2453985,NULL,'195a292f27ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(196,'Photo','42test.jpg','2015-10-22 14:23:20',814063,NULL,'196a292fb94c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(197,'Photo','realized1-solefield-desktop-2880-x-1800.jpg','2016-09-02 15:54:59',3165661,NULL,'197a29304e0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(198,'Photo','imac-love-computer-wallpaper-1920x1080-3050-1440x900.jpg','2024-06-12 10:31:15',96565,NULL,'198a2930de6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(199,'Photo','IMG_0003.JPG','2024-06-12 10:31:15',56987,NULL,'199a29316f6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(200,'Photo','IMG_0017.JPG','2024-06-12 10:31:15',27223,NULL,'200a2931ff2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(201,'Photo','IMG_0006.JPG','2024-06-12 10:31:15',42125,NULL,'201a293292ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(202,'Photo','IMG_0013.JPG','2024-06-12 10:31:15',31584,NULL,'202a2933226c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(203,'Photo','1IMG_0020.JPG','2024-06-12 10:31:15',498603,NULL,'203a2933b54c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(204,'Photo','IMG_0011.JPG','2024-06-12 10:31:15',41259,NULL,'204a293567ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(205,'Photo','IMG_0005.JPG','2024-06-12 10:31:15',55846,NULL,'205a29360cac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(206,'Photo','IMG_0004.JPG','2024-06-12 10:31:15',59269,NULL,'206a2936aacc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(207,'Photo','IMG_0010.JPG','2024-06-12 10:31:15',39554,NULL,'207a293742ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(208,'Photo','IMG_0088.JPG','2024-06-12 10:31:15',189972,NULL,'208a2937d94c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(209,'Photo','IMG_0063.JPG','2024-06-12 10:31:15',264767,NULL,'209a29386eac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(210,'Photo','IMG_0103.JPG','2024-06-12 10:31:15',152676,NULL,'210a29390aec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS2 Windows'),(211,'Photo','IMG_0102.JPG','2024-06-12 10:31:15',181700,NULL,'211a2939a0ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(212,'Photo','Sunset-optimized-by-AR7.png','2024-06-12 10:31:15',293980,NULL,'212a293a332c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(213,'Photo','IMG_0062.JPG','2024-06-12 10:31:15',229306,NULL,'213a293aca6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(214,'Photo','IMG_0076.JPG','2024-06-12 10:31:15',77489,NULL,'214a293b89ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(215,'Photo','IMG_0089.JPG','2009-09-21 12:32:50',375764,NULL,'215a293c2f4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(216,'Photo','IMG_0060.JPG','2024-06-12 10:31:15',114118,NULL,'216a293cc0ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(217,'Photo','IMG_0048.JPG','2024-06-12 10:31:15',339562,NULL,'217a293d500c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(218,'Photo','WWDC-AR7-Mac_air.jpg','2014-04-04 11:54:10',1064226,NULL,'218a293dde8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','iPhoto 9.5.1'),(219,'Photo','7IMG_0019.JPG','2024-06-12 10:31:15',463742,NULL,'219a293e6b2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(220,'Photo','IMG_0114.JPG','2008-07-09 18:10:52',316560,NULL,'220a293efccc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','GIMP 2.6.8'),(221,'Photo','IMG_0101.JPG','2024-06-12 10:31:15',142550,NULL,'221a293f8aac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(222,'Photo','2IMG_0021.JPG','2024-06-12 10:31:15',281617,NULL,'222a294030ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(223,'Photo','1440x900.png','2024-06-12 10:31:15',194367,NULL,'223a2940bf6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(224,'Photo','IMG_0049.JPG','2024-06-12 10:31:15',183001,NULL,'224a2941510c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS2 Windows'),(225,'Photo','IMG_0075.JPG','2024-06-12 10:31:15',278204,NULL,'225a2941e16c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(226,'Photo','IMG_0061.JPG','2024-06-12 10:31:15',102306,NULL,'226a29426fec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(227,'Photo','IMG_0059.JPG','2024-06-12 10:31:15',190671,NULL,'227a2942fd2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS2 Windows'),(228,'Photo','IMG_0065.JPG','2024-06-12 10:31:15',201014,NULL,'228a29438b0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(229,'Photo','IMG_0071.JPG','2024-06-12 10:31:15',97591,NULL,'229a29441cac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(230,'Photo','Ozix-abstract-geometry.jpg','2024-06-12 10:31:15',164067,NULL,'230a2944aa8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(231,'Photo','IMG_0105.JPG','2024-06-12 10:31:15',315557,NULL,'231a294539ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(232,'Photo','IMG_0104.JPG','2024-06-12 10:31:15',189362,NULL,'232a2945c8cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(233,'Photo','IMG_0110.JPG','2024-06-12 10:31:15',148498,NULL,'233a2946574c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(234,'Photo','IMG_0070.JPG','2024-06-12 10:31:15',101477,NULL,'234a2946eacc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(235,'Photo','IMG_0064.JPG','2024-06-12 10:31:15',207427,NULL,'235a294779ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(236,'Photo','IMG_0058.JPG','2024-06-12 10:31:15',220602,NULL,'236a29481e4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(237,'Photo','IMG_0099.JPG','2024-06-12 10:31:15',160142,NULL,'237a2948b30c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(238,'Photo','IMG_0072.JPG','2024-06-12 10:31:15',132207,NULL,'238a2949490c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(239,'Photo','IMG_0066.JPG','2024-06-12 10:31:15',224353,NULL,'239a2949da0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(240,'Photo','Ozix-shine.jpg','2024-06-12 10:31:15',68115,NULL,'240a294a6a6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(241,'Photo','IMG_0106.JPG','2024-06-12 10:31:15',104679,NULL,'241a294b146c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(242,'Photo','IMG_0112.JPG','2024-06-12 10:31:15',168803,NULL,'242a294c8cac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(243,'Photo','IMG_0113.JPG','2024-06-12 10:31:15',201241,NULL,'243a294d342c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','GIMP 2.6.8'),(244,'Photo','IMG_0107.JPG','2024-06-12 10:31:15',204297,NULL,'244a294dd2ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(245,'Photo','Marie_Sturges_Raspberry_640x1136.jpg','2013-02-17 23:58:37',597374,NULL,'245a294e76ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(246,'Photo','IMG_0067.JPG','2024-06-12 10:31:15',140168,NULL,'246a294f156c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(247,'Photo','IMG_0073.JPG','2004-09-26 00:00:00',149234,NULL,'247a294fda4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(248,'Photo','IMG_0098.JPG','2024-06-12 10:31:15',168987,NULL,'248a29507aec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(249,'Photo','IMG_0095.JPG','2024-06-12 10:31:15',142394,NULL,'249a295119ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(250,'Photo','IMG_0081.JPG','2010-04-04 16:12:22',347366,NULL,'250a2951b7cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(251,'Photo','IMG_0056.JPG','2010-04-24 16:37:44',158814,NULL,'251a2952e14c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(252,'Photo','IMG_0042.JPG','2024-06-12 10:31:15',218492,NULL,'252a2953918c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(253,'Photo','5IMG_0026.JPG','2024-06-12 10:31:15',525391,NULL,'253a2954340c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(254,'Photo','twilightseye_640x1136.jpg','2013-12-15 08:29:54',542616,NULL,'254a295513cc6eb',1,0,0,0,NULL,0,7,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CC (Macintosh)'),(255,'Photo','IMG_0043.JPG','2024-06-12 10:31:15',339869,NULL,'255a2955bc8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(256,'Photo','IMG_0057.JPG','2024-06-12 10:31:15',221763,NULL,'256a29565fac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(257,'Photo','IMG_0080.JPG','2024-06-12 10:31:15',145499,NULL,'257a2957004c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(258,'Photo','IMG_0094.JPG','2010-01-03 14:44:47',185893,NULL,'258a2957a18c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(259,'Photo','IMG_0082.JPG','2024-06-12 10:31:15',103530,NULL,'259a295844ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(260,'Photo','apple_wallpaper_coastal-sunset-green_iphone5_parallax.jpg','2014-02-19 15:01:37',418942,NULL,'260a2958ed6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(261,'Photo','IMG_0096.JPG','2024-06-12 10:31:15',200873,NULL,'261a29598eac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(262,'Photo','IMG_0041.JPG','2024-06-12 10:31:15',183961,NULL,'262a295a2e0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(263,'Photo','IMG_0055.JPG','2008-11-29 11:01:51',355716,NULL,'263a295aceac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(264,'Photo','IMG_0069.JPG','2024-06-12 10:31:15',183187,NULL,'264a295b73ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(265,'Photo','IMG_0108.JPG','2024-06-12 10:31:15',180760,NULL,'265a295c14ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(266,'Photo','iOS_7_Mavericks_by_AR7.png','2024-06-12 10:31:15',403020,NULL,'266a295cb4ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(267,'Photo','IMG_0068.JPG','2024-06-12 10:31:15',236381,NULL,'267a295d56cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(268,'Photo','IMG_0054.JPG','2010-05-22 09:44:44',293126,NULL,'268a295df94c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(269,'Photo','IMG_0040.JPG','2024-06-12 10:31:15',123447,NULL,'269a295e9eec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(270,'Photo','IMG_0097.JPG','2024-06-12 10:31:15',339179,NULL,'270a295f3f8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(271,'Photo','IMG_0083.JPG','2024-06-12 10:31:15',332711,NULL,'271a295fe0cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(272,'Photo','IMG_0093.JPG','2010-05-02 21:18:00',175022,NULL,'272a296082ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(273,'Photo','IMG_0078.JPG','2024-06-12 10:31:15',318397,NULL,'273a296127ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(274,'Photo','IMG_0044.JPG','2024-06-12 10:31:15',236805,NULL,'274a2961ca2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(275,'Photo','IMG_0050.JPG','2024-06-12 10:31:15',141049,NULL,'275a29626c0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(276,'Photo','apple_wallpaper_picnic-table-nature_iphone5_parallax.jpg','2014-03-12 02:21:43',185689,NULL,'276a29630e8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(277,'Photo','metro-right.jpg','2024-06-12 10:31:15',1955364,NULL,'277a2963c00c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(278,'Photo','IMG_0118.JPG','2024-06-12 10:31:15',184431,NULL,'278a2964696c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(279,'Photo','IMG_0119.JPG','2024-06-12 10:31:15',328380,NULL,'279a29650f0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(280,'Photo','IMG_0051.JPG','2024-06-12 10:31:15',100905,NULL,'280a2965d34c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(281,'Photo','IMG_0045.JPG','2024-06-12 10:31:15',274469,NULL,'281a2966798c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(282,'Photo','IMG_0079.JPG','2024-06-12 10:31:15',98557,NULL,'282a296721ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(283,'Photo','IMG_0092.JPG','2024-06-12 10:31:15',119467,NULL,'283a2967c60c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(284,'Photo','IMG_0086.JPG','2024-06-12 10:31:15',172468,NULL,'284a29686b0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(285,'Photo','IMG_0090.JPG','2024-06-12 10:31:15',214434,NULL,'285a296929ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(286,'Photo','IMG_0084.JPG','2010-04-18 16:10:03',139487,NULL,'286a2969d76c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(287,'Photo','IMG_0053.JPG','2024-06-12 10:31:15',174667,NULL,'287a296a82ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(288,'Photo','IMG_0047.JPG','2024-06-12 10:31:15',183878,NULL,'288a296b298c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(289,'Photo','Marie_Sturges_Blueberry_640x1136.jpg','2013-02-18 00:09:20',412107,NULL,'289a296bcfcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(290,'Photo','IMG_0046.JPG','2024-06-12 10:31:15',170636,NULL,'290a296c7d8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(291,'Photo','IMG_0052.JPG','2024-06-12 10:31:15',176280,NULL,'291a296d282c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(292,'Photo','IMG_0085.JPG','2024-06-12 10:31:15',189930,NULL,'292a296dd04c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS3 Macintosh'),(293,'Photo','IMG_0091.JPG','2009-07-06 22:09:45',143124,NULL,'293a296e7b8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(294,'Photo','IMG_0035.JPG','2024-06-12 10:31:15',203134,NULL,'294a296f294c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(295,'Photo','IMG_0021.JPG','2024-06-12 10:31:15',218927,NULL,'295a296fd2ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(296,'Photo','IMG_0009.JPG','2024-06-12 10:31:15',51663,NULL,'296a29707f2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(297,'Photo','metro-middle.jpg','2024-06-12 10:31:15',1962666,NULL,'297a2971274c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(298,'Photo','IMG_0008.JPG','2024-06-12 10:31:15',42279,NULL,'298a2971d00c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(299,'Photo','IMG_0020.JPG','2024-06-12 10:31:15',185325,NULL,'299a2972782c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(300,'Photo','IMG_0034.JPG','2024-06-12 10:31:15',143815,NULL,'300a2973236c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(301,'Photo','IMG_0022.JPG','2024-06-12 10:31:15',71001,NULL,'301a2973e48c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(302,'Photo','IMG_0036.JPG','2024-06-12 10:31:15',213193,NULL,'302a29748f2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS4 Macintosh'),(303,'Photo','3IMG_0024.JPG','2024-06-12 10:31:15',596411,NULL,'303a2975388c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(304,'Photo','Abstraction-Bubbles-Texture-Color-Creativity.jpg','2024-06-12 10:31:15',97997,NULL,'304a2975e1ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(305,'Photo','Ozix-red-stars.jpg','2024-06-12 10:31:15',133928,NULL,'305a2976922c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(306,'Photo','IMG_0037.JPG','2024-06-12 10:31:15',85137,NULL,'306a29773ccc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(307,'Photo','IMG_0023.JPG','2024-06-12 10:31:15',228272,NULL,'307a2977e6cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(308,'Photo','IMG_0027.JPG','2024-06-12 10:31:15',214570,NULL,'308a297890cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(309,'Photo','IMG_0033.JPG','2024-06-12 10:31:15',166923,NULL,'309a29793acc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(310,'Photo','8IMG_0017.JPG','2024-06-12 10:31:15',125064,NULL,'310a297b1fcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(311,'Photo','ios7-style-retina-wallpaper.jpg','2024-06-12 10:31:15',422090,NULL,'311a297bdaac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(312,'Photo','IMG_0032.JPG','2024-06-12 10:31:15',213473,NULL,'312a297c8ccc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(313,'Photo','IMG_0026.JPG','2024-06-12 10:31:15',173532,NULL,'313a297e064c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS5 Macintosh'),(314,'Photo','6IMG_0027.JPG','2024-06-12 10:31:15',613236,NULL,'314a297ec30c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(315,'Photo','IMG_0018.JPG','2024-06-12 10:31:15',54193,NULL,'315a297f73ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(316,'Photo','IMG_0030.JPG','2024-06-12 10:31:15',139634,NULL,'316a298022ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(317,'Photo','IMG_0024.JPG','2024-06-12 10:31:15',244686,NULL,'317a2980d0ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(318,'Photo','BMFtc_lCAAEOmCY.jpg-large.jpeg','2024-06-12 10:31:15',163559,NULL,'318a29817dcc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(319,'Photo','4IMG_0013.JPG','2024-06-12 10:31:15',311966,NULL,'319a29822eac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(320,'Photo','BMkwvRbCIAQfI8h.jpg-large.jpeg','2024-06-12 10:31:15',8872,NULL,'320a2982db2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(321,'Photo','IMG_0025.JPG','2024-06-12 10:31:15',145014,NULL,'321a298387ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(322,'Photo','IMG_0031.JPG','2006-02-11 13:07:10',167084,NULL,'322a298434cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','COOLPIX L1V1.2'),(323,'Photo','IMG_0019.JPG','2005-04-29 00:00:00',129709,NULL,'323a2984e46c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(324,'Photo','9Bombs_Blue_Ocean_YkViRmE.jpg','2015-10-22 14:23:18',308012,NULL,'324a298590ec6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(325,'Photo','diego_torres_Night_Ocean_YkVqQmY.jpg','2015-10-22 14:23:16',623750,NULL,'325a2986c78c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(326,'Photo','82test.jpg','2023-04-07 07:08:19',5271706,NULL,'326a29877a4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(327,'Photo','apple_store_oxmoor_steeber.jpg','2023-04-07 07:08:18',1200867,NULL,'327a298826cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(328,'Photo','49test.jpg','2015-10-22 14:23:16',247852,NULL,'328a2988d34c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(329,'Photo','2016-02-02_UpsideDown_ROW12246886594_1920x1080.jpg','2016-02-03 07:41:40',337516,NULL,'329a29897b6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(330,'Photo','iPadPro_Wallpaper.png','2020-03-18 17:09:36',32231940,NULL,'330a298a210c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','PNG',''),(331,'Photo','14test.jpg','2016-02-03 07:43:16',332132,NULL,'331a298ac88c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(332,'Photo','66test.jpg','2015-10-22 14:23:18',300768,NULL,'332a298b6ecc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(333,'Photo','2015-12-02_BearGlacierLake_ROW11778213520_1920x1080.jpg','2016-02-03 07:43:36',331312,NULL,'333a298c1e6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(334,'Photo','76test.jpg','2015-10-22 14:23:16',446850,NULL,'334a298cd08c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(335,'Photo','57test.gif','2023-04-07 07:08:18',1370088,NULL,'335a298d7b2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','GIF',''),(336,'Photo','38__test.jpg','2023-04-07 07:08:19',383286,NULL,'336a298e216c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(337,'Photo','The_Baja_-_MacBook_Pro_Wallpaper.jpg','2023-04-07 07:08:19',2097891,NULL,'337a298ecb6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(338,'Photo','50test.jpg','2015-10-22 14:23:20',133154,NULL,'338a298f71ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(339,'Photo','32test.jpg','2015-10-22 14:23:16',225720,NULL,'339a29901c4c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(340,'Photo','03045_spectrumarray_1680x1050.jpg','2012-02-04 05:28:18',1368953,NULL,'340a2990f02c6eb',1,0,0,0,NULL,0,5,'2024-12-30 20:21:19','JPEG','Adobe Photoshop CS6 (Macintosh)'),(341,'Photo','Lies_Thru_a_Lens_The_Yellow_Fields_YkVjR2E.jpg','2015-10-22 14:23:20',1141526,NULL,'341a2991a10c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(342,'Photo','photo-1464621922360-27f3bf0eca75.jpeg','2023-04-07 07:08:19',508735,NULL,'342a29924f6c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(343,'Video','production_id_4237839__2160p_.mp4','2020-04-25 11:45:05',34464883,NULL,'343a2992f82c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(344,'Video','pexels-ibrahim-bennett-18522098__Original_.mp4','2023-09-26 03:07:21',93075412,NULL,'344a2993a7cc6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(345,'Photo','John_Fowler_A_Branch_on_The_Beach_YkVgQGA.jpg','2015-10-22 14:23:20',672512,NULL,'345a2994530c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(346,'Photo','48test.jpg','2015-10-22 14:23:18',651620,NULL,'346a2995034c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(347,'Photo','testHeic.heic','2019-01-07 18:58:48',1214692,NULL,'347a2995d90c6eb',1,0,0,0,NULL,0,4,'2024-12-30 20:21:19','HEIC','12.1.1'),(348,'Photo','IMG_4787.HEIC','2023-10-04 12:49:03',1564596,NULL,'348a2996bc8c6eb',1,0,0,0,NULL,0,1,'2024-12-30 20:21:19','HEIC','16.7'),(349,'Photo','103test.jpg','2023-10-11 07:36:19',4212139,NULL,'349a299778ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(350,'Photo','15test.jpg','2016-02-03 07:43:02',340708,NULL,'350a299822ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(351,'Photo','pexels-israel-torres-18290834.jpg','2023-10-11 07:35:55',7418174,NULL,'351a2998ce8c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(352,'Photo','alan_f_Eiffel_Tower__akJhSQ.jpg','2015-10-22 14:23:18',705884,NULL,'352a299976ac6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG',''),(353,'Video','production_id_4911644__2160p_.mp4','2020-07-20 15:02:55',46274500,NULL,'353a299a1e2c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','MP4',''),(354,'Photo','77test.jpg','2015-10-22 14:23:18',407642,NULL,'354a299aca0c6eb',1,0,0,0,NULL,0,NULL,'2024-12-30 20:21:19','JPEG','');
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
    IF OLD.DeletedStatus != NEW.DeletedStatus THEN
        SET NEW.DeletionDate = IF(NEW.DeletedStatus = 1, NOW(), NULL);
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `mediasearchview`
--

DROP TABLE IF EXISTS `mediasearchview`;
/*!50001 DROP VIEW IF EXISTS `mediasearchview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `mediasearchview` AS SELECT 
 1 AS `media_id`,
 1 AS `FileType`,
 1 AS `FileName`,
 1 AS `CreateDate`,
 1 AS `fSize`,
 1 AS `FileSize`,
 1 AS `FileExt`,
 1 AS `URL`,
 1 AS `ClassName`,
 1 AS `Make`,
 1 AS `Model`,
 1 AS `Megapixels`,
 1 AS `DisplayDuration`,
 1 AS `Title`,
 1 AS `City`,
 1 AS `GPSLatitude`,
 1 AS `GPSLongitude`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `Photo`
--

DROP TABLE IF EXISTS `Photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Photo` (
  `media` int unsigned NOT NULL,
  `ai_created` tinyint(1) DEFAULT '0',
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
INSERT INTO `Photo` VALUES (1,0,'',2994,1871,5.6),(2,0,'',1932,1280,2.5),(3,0,'',1920,1280,2.5),(5,0,'',1920,1080,2.1),(6,0,'Rotate 90 CW',4032,3024,12.2),(7,0,'',2537,1280,3.2),(8,0,'Horizontal (normal)',2100,1500,3.1),(10,0,'',1680,1260,2.1),(12,0,'',1920,1280,2.5),(13,0,'',1970,1280,2.5),(15,0,'',3840,2160,8.3),(16,0,'',1917,1280,2.5),(17,0,'',1920,1280,2.5),(18,0,'',1920,1280,2.5),(20,0,'',4016,6016,24.2),(22,0,'',2880,1800,5.2),(23,0,'',5393,8086,43.6),(24,0,'',1920,1280,2.5),(25,0,'',1920,1280,2.5),(26,0,'',1706,1280,2.2),(27,0,'',2880,1800,5.2),(28,0,'Horizontal (normal)',2880,1800,5.2),(29,0,'',1920,1280,2.5),(30,0,'',1920,1080,2.1),(31,0,'',3000,2000,6),(32,0,'Horizontal (normal)',3464,1948,6.7),(33,0,'',1920,1080,2.1),(34,0,'Rotate 90 CW',4032,3024,12.2),(35,0,'',3648,5472,20),(36,0,'Horizontal (normal)',2048,2048,4.2),(37,0,'Horizontal (normal)',2048,2048,4.2),(38,0,'Horizontal (normal)',2048,2048,4.2),(39,0,'Horizontal (normal)',2048,2048,4.2),(40,0,'Horizontal (normal)',2048,2048,4.2),(41,0,'Horizontal (normal)',2048,2048,4.2),(42,0,'Horizontal (normal)',2048,2048,4.2),(43,0,'Horizontal (normal)',2048,2048,4.2),(44,0,'Horizontal (normal)',2048,2048,4.2),(45,0,'Horizontal (normal)',2048,2048,4.2),(46,0,'Horizontal (normal)',2048,2048,4.2),(47,0,'Horizontal (normal)',2048,2048,4.2),(48,0,'Horizontal (normal)',2048,2048,4.2),(49,0,'Horizontal (normal)',2048,2048,4.2),(50,0,'Horizontal (normal)',2048,2048,4.2),(51,0,'Horizontal (normal)',2048,2048,4.2),(52,0,'Horizontal (normal)',2048,2048,4.2),(53,0,'Horizontal (normal)',2048,2048,4.2),(54,0,'Horizontal (normal)',2048,2048,4.2),(55,0,'Horizontal (normal)',2048,2048,4.2),(56,0,'Horizontal (normal)',2048,2048,4.2),(57,0,'Horizontal (normal)',2048,2048,4.2),(58,0,'Horizontal (normal)',2048,2048,4.2),(59,0,'Horizontal (normal)',2048,2048,4.2),(60,0,'Horizontal (normal)',2048,2048,4.2),(61,0,'Horizontal (normal)',2048,2048,4.2),(62,0,'Horizontal (normal)',2048,2048,4.2),(63,0,'Horizontal (normal)',2048,2048,4.2),(64,0,'Horizontal (normal)',2048,2048,4.2),(65,0,'Horizontal (normal)',2048,2048,4.2),(66,0,'Horizontal (normal)',2048,2048,4.2),(67,0,'Horizontal (normal)',2048,2048,4.2),(68,0,'Horizontal (normal)',2048,2048,4.2),(69,0,'Horizontal (normal)',2048,2048,4.2),(70,0,'Horizontal (normal)',2048,2048,4.2),(71,0,'Horizontal (normal)',2048,2048,4.2),(72,0,'Horizontal (normal)',2048,2048,4.2),(73,0,'Horizontal (normal)',2048,2048,4.2),(74,0,'Horizontal (normal)',2048,2048,4.2),(75,0,'Horizontal (normal)',2048,2048,4.2),(76,0,'Horizontal (normal)',2048,2048,4.2),(77,0,'Horizontal (normal)',2048,2048,4.2),(78,0,'Horizontal (normal)',2048,2048,4.2),(79,0,'Horizontal (normal)',2048,2048,4.2),(80,0,'Horizontal (normal)',2048,2048,4.2),(81,0,'Horizontal (normal)',2048,2048,4.2),(82,0,'Horizontal (normal)',2048,2048,4.2),(83,0,'Horizontal (normal)',2048,2048,4.2),(84,0,'Horizontal (normal)',2048,2048,4.2),(85,0,'Horizontal (normal)',2048,2048,4.2),(86,0,'Horizontal (normal)',2048,2048,4.2),(87,0,'Horizontal (normal)',2048,2048,4.2),(88,0,'Horizontal (normal)',2048,2048,4.2),(89,0,'Horizontal (normal)',2048,2048,4.2),(90,0,'Horizontal (normal)',2048,2048,4.2),(91,0,'Horizontal (normal)',2048,2048,4.2),(92,0,'Horizontal (normal)',2048,2048,4.2),(93,0,'Horizontal (normal)',2048,2048,4.2),(94,0,'Horizontal (normal)',2048,2048,4.2),(95,0,'Horizontal (normal)',2048,2048,4.2),(96,0,'Horizontal (normal)',2048,2048,4.2),(97,0,'Horizontal (normal)',2048,2048,4.2),(98,0,'Horizontal (normal)',2048,2048,4.2),(99,0,'Horizontal (normal)',2048,2048,4.2),(100,0,'Horizontal (normal)',2048,2048,4.2),(101,0,'Horizontal (normal)',2048,2048,4.2),(102,0,'Horizontal (normal)',2048,2048,4.2),(103,0,'Horizontal (normal)',2048,2048,4.2),(104,0,'Horizontal (normal)',2048,2048,4.2),(105,0,'Horizontal (normal)',2048,2048,4.2),(106,0,'Horizontal (normal)',2048,2048,4.2),(107,0,'Horizontal (normal)',2048,2048,4.2),(108,0,'Horizontal (normal)',2048,2048,4.2),(109,0,'Horizontal (normal)',2048,2048,4.2),(110,0,'Horizontal (normal)',2048,2048,4.2),(111,0,'Horizontal (normal)',2048,2048,4.2),(112,0,'Horizontal (normal)',2048,2048,4.2),(113,0,'Horizontal (normal)',2048,2048,4.2),(114,0,'Horizontal (normal)',2048,2048,4.2),(115,0,'Horizontal (normal)',2048,2048,4.2),(116,0,'Horizontal (normal)',2048,2048,4.2),(117,0,'Horizontal (normal)',2048,2048,4.2),(118,0,'Horizontal (normal)',2048,2048,4.2),(119,0,'Horizontal (normal)',2048,2048,4.2),(120,0,'Horizontal (normal)',2048,2048,4.2),(121,0,'Horizontal (normal)',2048,2048,4.2),(122,0,'Horizontal (normal)',2048,2048,4.2),(123,0,'Horizontal (normal)',2048,2048,4.2),(124,0,'Horizontal (normal)',2048,2048,4.2),(125,0,'Horizontal (normal)',2048,2048,4.2),(126,0,'Horizontal (normal)',2048,2048,4.2),(127,0,'Horizontal (normal)',2048,2048,4.2),(128,0,'Horizontal (normal)',2048,2048,4.2),(129,0,'Horizontal (normal)',2048,2048,4.2),(130,0,'',2048,2048,4.2),(131,0,'Horizontal (normal)',2048,2048,4.2),(132,0,'Horizontal (normal)',2048,2048,4.2),(133,0,'Horizontal (normal)',2048,2048,4.2),(134,0,'Horizontal (normal)',2048,2048,4.2),(135,0,'',1998,1280,2.6),(136,0,'',1280,720,0.9),(137,0,'',1840,1280,2.4),(138,0,'',1920,1280,2.5),(140,0,'Horizontal (normal)',6016,6016,36.2),(141,0,'',1920,1080,2.1),(142,0,'',1920,1080,2.1),(143,0,'',817,460,0.4),(144,0,'',1920,1280,2.5),(145,0,'',5461,8192,44.7),(146,0,'',4000,6000,24),(147,0,'',1920,1080,2.1),(148,0,'',1919,1280,2.5),(149,0,'',1920,1080,2.1),(150,0,'',1920,1280,2.5),(152,0,'',3633,5449,19.8),(154,0,'',1920,1280,2.5),(157,0,'',1920,1080,2.1),(158,0,'',2017,1280,2.6),(160,0,'',2560,1440,3.7),(161,0,'',1920,1280,2.5),(162,0,'',1920,1280,2.5),(163,0,'Horizontal (normal)',4032,3024,12.2),(166,0,'',500,281,0.1),(167,0,'',2048,1280,2.6),(168,0,'',1920,1080,2.1),(170,0,'Horizontal (normal)',1680,1050,1.8),(171,0,'',2048,1280,2.6),(172,0,'',1920,1080,2.1),(173,0,'Horizontal (normal)',3840,2400,9.2),(174,0,'',1920,1080,2.1),(175,0,'',1706,1280,2.2),(176,0,'',4000,6000,24),(177,0,'',2880,1800,5.2),(178,0,'',4000,5434,21.7),(179,0,'Horizontal (normal)',4032,3024,12.2),(180,0,'Horizontal (normal)',4032,3024,12.2),(181,0,'',1000,667,0.7),(182,0,'Horizontal (normal)',4032,3024,12.2),(183,0,'',4999,3281,16.4),(184,0,'',850,567,0.5),(185,0,'Horizontal (normal)',4032,3024,12.2),(186,0,'Horizontal (normal)',4032,3024,12.2),(187,0,'Horizontal (normal)',4032,3024,12.2),(188,0,'',600,458,0.3),(189,0,'Horizontal (normal)',4032,3024,12.2),(190,0,'Horizontal (normal)',4032,3024,12.2),(191,0,'Horizontal (normal)',1600,1067,1.7),(192,0,'',600,449,0.3),(193,0,'Rotate 90 CW',4032,3024,12.2),(194,0,'Horizontal (normal)',4032,3024,12.2),(195,0,'Horizontal (normal)',2832,1750,5),(196,0,'',1920,1280,2.5),(197,0,'Horizontal (normal)',2880,1800,5.2),(198,0,'',1440,900,1.3),(199,0,'Horizontal (normal)',320,480,0.2),(200,0,'Horizontal (normal)',320,480,0.2),(201,0,'Horizontal (normal)',320,480,0.2),(202,0,'Horizontal (normal)',320,480,0.2),(203,0,'Horizontal (normal)',1536,2048,3.1),(204,0,'Horizontal (normal)',320,480,0.2),(205,0,'Horizontal (normal)',320,480,0.2),(206,0,'Horizontal (normal)',320,480,0.2),(207,0,'Horizontal (normal)',320,480,0.2),(208,0,'Horizontal (normal)',640,960,0.6),(209,0,'Horizontal (normal)',640,960,0.6),(210,0,'Horizontal (normal)',640,960,0.6),(211,0,'Horizontal (normal)',640,960,0.6),(212,0,'',640,1136,0.7),(213,0,'Horizontal (normal)',640,960,0.6),(214,0,'Horizontal (normal)',640,960,0.6),(215,0,'Horizontal (normal)',640,960,0.6),(216,0,'Horizontal (normal)',640,960,0.6),(217,0,'Horizontal (normal)',640,960,0.6),(218,0,'Horizontal (normal)',2048,1280,2.6),(219,0,'Horizontal (normal)',1536,2048,3.1),(220,0,'Horizontal (normal)',640,960,0.6),(221,0,'Horizontal (normal)',640,960,0.6),(222,0,'Horizontal (normal)',1536,2048,3.1),(223,0,'',1440,900,1.3),(224,0,'Horizontal (normal)',640,960,0.6),(225,0,'Horizontal (normal)',640,960,0.6),(226,0,'Horizontal (normal)',640,960,0.6),(227,0,'Horizontal (normal)',640,960,0.6),(228,0,'Horizontal (normal)',640,960,0.6),(229,0,'Horizontal (normal)',640,960,0.6),(230,0,'',744,1392,1),(231,0,'Horizontal (normal)',640,960,0.6),(232,0,'Horizontal (normal)',640,960,0.6),(233,0,'Horizontal (normal)',640,960,0.6),(234,0,'Horizontal (normal)',640,960,0.6),(235,0,'Horizontal (normal)',640,960,0.6),(236,0,'Horizontal (normal)',640,960,0.6),(237,0,'Horizontal (normal)',640,960,0.6),(238,0,'Horizontal (normal)',640,960,0.6),(239,0,'Horizontal (normal)',640,960,0.6),(240,0,'Horizontal (normal)',640,1136,0.7),(241,0,'Horizontal (normal)',640,960,0.6),(242,0,'Horizontal (normal)',640,960,0.6),(243,0,'Horizontal (normal)',640,960,0.6),(244,0,'Horizontal (normal)',640,960,0.6),(245,0,'Horizontal (normal)',640,1136,0.7),(246,0,'Horizontal (normal)',640,960,0.6),(247,0,'Horizontal (normal)',640,960,0.6),(248,0,'Horizontal (normal)',640,960,0.6),(249,0,'Horizontal (normal)',640,960,0.6),(250,0,'Horizontal (normal)',640,960,0.6),(251,0,'Horizontal (normal)',640,960,0.6),(252,0,'Horizontal (normal)',640,960,0.6),(253,0,'Horizontal (normal)',1536,2048,3.1),(254,0,'Horizontal (normal)',640,1136,0.7),(255,0,'Horizontal (normal)',640,960,0.6),(256,0,'Horizontal (normal)',640,960,0.6),(257,0,'Horizontal (normal)',640,960,0.6),(258,0,'Horizontal (normal)',640,960,0.6),(259,0,'Horizontal (normal)',640,960,0.6),(260,0,'Horizontal (normal)',1040,1536,1.6),(261,0,'Horizontal (normal)',640,960,0.6),(262,0,'Horizontal (normal)',640,960,0.6),(263,0,'Horizontal (normal)',640,960,0.6),(264,0,'Horizontal (normal)',640,960,0.6),(265,0,'Horizontal (normal)',640,960,0.6),(266,0,'',640,1136,0.7),(267,0,'Horizontal (normal)',640,960,0.6),(268,0,'Horizontal (normal)',640,960,0.6),(269,0,'Horizontal (normal)',640,960,0.6),(270,0,'Horizontal (normal)',640,960,0.6),(271,0,'Horizontal (normal)',640,960,0.6),(272,0,'Horizontal (normal)',640,960,0.6),(273,0,'Horizontal (normal)',640,960,0.6),(274,0,'Horizontal (normal)',640,960,0.6),(275,0,'Horizontal (normal)',640,960,0.6),(276,0,'Horizontal (normal)',1040,1536,1.6),(277,0,'',1040,1526,1.6),(278,0,'Horizontal (normal)',640,960,0.6),(279,0,'Horizontal (normal)',640,960,0.6),(280,0,'Horizontal (normal)',640,960,0.6),(281,0,'Horizontal (normal)',640,960,0.6),(282,0,'Horizontal (normal)',640,960,0.6),(283,0,'Horizontal (normal)',640,960,0.6),(284,0,'Horizontal (normal)',640,960,0.6),(285,0,'Horizontal (normal)',640,960,0.6),(286,0,'Horizontal (normal)',640,960,0.6),(287,0,'Horizontal (normal)',640,960,0.6),(288,0,'Horizontal (normal)',640,960,0.6),(289,0,'Horizontal (normal)',640,1136,0.7),(290,0,'Horizontal (normal)',640,960,0.6),(291,0,'Horizontal (normal)',640,960,0.6),(292,0,'Horizontal (normal)',640,960,0.6),(293,0,'Horizontal (normal)',640,960,0.6),(294,0,'Horizontal (normal)',640,960,0.6),(295,0,'Horizontal (normal)',640,960,0.6),(296,0,'Horizontal (normal)',320,480,0.2),(297,0,'',1040,1526,1.6),(298,0,'Horizontal (normal)',320,480,0.2),(299,0,'Horizontal (normal)',640,960,0.6),(300,0,'Horizontal (normal)',640,960,0.6),(301,0,'Horizontal (normal)',640,960,0.6),(302,0,'Horizontal (normal)',640,960,0.6),(303,0,'Horizontal (normal)',1536,2048,3.1),(304,0,'Horizontal (normal)',1920,1200,2.3),(305,0,'Horizontal (normal)',744,1392,1),(306,0,'Horizontal (normal)',640,960,0.6),(307,0,'Horizontal (normal)',640,960,0.6),(308,0,'Horizontal (normal)',640,960,0.6),(309,0,'Horizontal (normal)',640,960,0.6),(310,0,'Horizontal (normal)',1536,2048,3.1),(311,0,'',2880,1800,5.2),(312,0,'Horizontal (normal)',640,960,0.6),(313,0,'Horizontal (normal)',640,960,0.6),(314,0,'Horizontal (normal)',1536,2048,3.1),(315,0,'Horizontal (normal)',320,480,0.2),(316,0,'Horizontal (normal)',640,960,0.6),(317,0,'Horizontal (normal)',640,960,0.6),(318,0,'',1023,1820,1.9),(319,0,'Horizontal (normal)',1536,2048,3.1),(320,0,'',640,1136,0.7),(321,0,'Horizontal (normal)',640,960,0.6),(322,0,'Horizontal (normal)',640,960,0.6),(323,0,'Horizontal (normal)',640,960,0.6),(324,0,'',1920,1280,2.5),(325,0,'',1920,1280,2.5),(326,0,'',5120,3493,17.9),(327,0,'',2560,1440,3.7),(328,0,'',1920,1280,2.5),(329,0,'',1920,1080,2.1),(330,0,'Rotate 270 CW',4084,5450,22.3),(331,0,'',1920,1080,2.1),(332,0,'',1812,1280,2.3),(333,0,'',1920,1080,2.1),(334,0,'',1920,1280,2.5),(335,0,'',500,281,0.1),(336,0,'Horizontal (normal)',1920,1280,2.5),(337,0,'',2880,1800,5.2),(338,0,'',1920,1280,2.5),(339,0,'',1920,1280,2.5),(340,0,'Horizontal (normal)',1680,1050,1.8),(341,0,'',1885,1280,2.4),(342,0,'',2702,1801,4.9),(345,0,'',1937,1280,2.5),(346,0,'',1706,1280,2.2),(347,0,'Rotate 90 CW',4032,3024,12.2),(348,0,'Rotate 90 CW',4032,3024,12.2),(349,0,'',3622,5433,19.7),(350,0,'',1920,1080,2.1),(351,0,'',5061,8192,41.5),(352,0,'',1981,1280,2.5),(354,0,'',1706,1280,2.2);
/*!40000 ALTER TABLE `Photo` ENABLE KEYS */;
UNLOCK TABLES;

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
INSERT INTO `ServerSystem` VALUES ('123e4567-e89b-12d3-a456-426614174000','XXXX-YYYY-ZZZZ-AAAA');
/*!40000 ALTER TABLE `ServerSystem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `SourceFile`
--

DROP TABLE IF EXISTS `SourceFile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SourceFile` (
  `media` int unsigned NOT NULL,
  `MIMEType` varchar(50) DEFAULT NULL,
  `SourceFile` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_SOURCEFILE_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `SourceFile`
--

LOCK TABLES `SourceFile` WRITE;
/*!40000 ALTER TABLE `SourceFile` DISABLE KEYS */;
INSERT INTO `SourceFile` VALUES (1,'image/png','/database/JFL-08072018-IMACS-MACBOOKS.png'),(2,'image/jpeg','/database/72test.jpg'),(3,'image/jpeg','/database/Jean-Alain_Foods_with_Love_YkVkRmY.jpg'),(4,'video/mp4','/database/video__2160p_.mp4'),(5,'image/jpeg','/database/2015-12-01_KenrokuenGarden_ROW11637035698_1920x1080.jpg'),(6,'image/heic','/database/IMG_4788.HEIC'),(7,'image/jpeg','/database/33t_est.jpg'),(8,'image/jpeg','/database/US_Navy_050102-N-9593M-040_A_village_near_the_coast_of_Sumatra_lays_in_ruin_after_the_Tsunami_that_struck_South_East_Asia.jpg'),(9,'video/mp4','/database/pexels-nataliya-vaitkevich-8468210__1080p_.mp4'),(10,'image/jpeg','/database/Diego_Torres_Silvestre_Moonlight..._ZkVkRQ.jpg'),(11,'video/mp4','/database/93test.mp4'),(12,'image/jpeg','/database/diego_torres_London_City_YkVqQmU.jpg'),(13,'image/jpeg','/database/Matt_JP_Afternoon_Swim_ZENqRQ.jpg'),(14,'video/mp4','/database/production_id_4779866__1080p_.mp4'),(15,'image/png','/database/kali-layers-16x9.png'),(16,'image/jpeg','/database/_83_test.jpg'),(17,'image/jpeg','/database/Foto-Rabe_Gooses__dream_YkVqQmM.jpg'),(18,'image/jpeg','/database/JulienDft_Photo_lock_a0RgRg.jpg'),(19,'video/mp4','/database/pexels-sunsetoned-5913482__2160p_.mp4'),(20,'image/jpeg','/database/pexels-leeloo-thefirst-5379765.jpg'),(21,'video/mp4','/database/Mariah_Carey_-_All_I_Want_for_Christmas_Is_You__Make_My_Wish_Come_True_Edition_.mp4'),(22,'image/jpeg','/database/Rough_Seas_-_MacBook_Pro_Wallpaper.jpg'),(23,'image/jpeg','/database/pexels-filipp-romanovski-17275905.jpg'),(24,'image/jpeg','/database/35test.jpg'),(25,'image/jpeg','/database/Gic_Shade_of_flowers_YkVlSGo.jpg'),(26,'image/jpeg','/database/me_nicoll_Pencil_ZUFjQg.jpg'),(27,'image/jpeg','/database/Glacier_Falls_-_MacBook_Pro_Wallpaper.jpg'),(28,'image/jpeg','/database/macOS-Sierra-Wallpaper-Macbook-Wallpaper.jpg'),(29,'image/jpeg','/database/ashley_Son_Airplane_a0ViSA.jpg'),(30,'image/jpeg','/database/2016-02-02_setsubun_JA-JP11957231259_1920x1080.jpg'),(31,'image/jpeg','/database/pexels-perry-wunderlich-5826451.jpg'),(32,'image/jpeg','/database/71test.jpg'),(33,'image/jpeg','/database/13test.jpg'),(34,'image/heic','/database/IMG_4782.HEIC'),(35,'image/jpeg','/database/pexels-lokman-sevim-17788447.jpg'),(36,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0438.JPG'),(37,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0439.JPG'),(38,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0416.JPG'),(39,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0417.JPG'),(40,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0429.JPG'),(41,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0428.JPG'),(42,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0513.JPG'),(43,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0507.JPG'),(44,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0498.JPG'),(45,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0467.JPG'),(46,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0473.JPG'),(47,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0472.JPG'),(48,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0466.JPG'),(49,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0499.JPG'),(50,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0506.JPG'),(51,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0512.JPG'),(52,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0504.JPG'),(53,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0510.JPG'),(54,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0470.JPG'),(55,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0464.JPG'),(56,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0458.JPG'),(57,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0459.JPG'),(58,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0465.JPG'),(59,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0471.JPG'),(60,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0511.JPG'),(61,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0505.JPG'),(62,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0501.JPG'),(63,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0515.JPG'),(64,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0449.JPG'),(65,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0475.JPG'),(66,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0461.JPG'),(67,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0460.JPG'),(68,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0474.JPG'),(69,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0448.JPG'),(70,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0514.JPG'),(71,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0500.JPG'),(72,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0516.JPG'),(73,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0502.JPG'),(74,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0489.JPG'),(75,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0462.JPG'),(76,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0476.JPG'),(77,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0477.JPG'),(78,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0463.JPG'),(79,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0488.JPG'),(80,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0503.JPG'),(81,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0517.JPG'),(82,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0485.JPG'),(83,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0491.JPG'),(84,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0446.JPG'),(85,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0452.JPG'),(86,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0453.JPG'),(87,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0447.JPG'),(88,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0490.JPG'),(89,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0484.JPG'),(90,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0492.JPG'),(91,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0486.JPG'),(92,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0451.JPG'),(93,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0479.JPG'),(94,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0478.JPG'),(95,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0444.JPG'),(96,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0450.JPG'),(97,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0487.JPG'),(98,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0493.JPG'),(99,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0508.JPG'),(100,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0497.JPG'),(101,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0483.JPG'),(102,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0468.JPG'),(103,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0454.JPG'),(104,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0440.JPG'),(105,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0441.JPG'),(106,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0455.JPG'),(107,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0469.JPG'),(108,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0496.JPG'),(109,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0509.JPG'),(110,'image/jpeg','/database/__The_n_ew_iP_ad/123__IMG_0425.JPG'),(111,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0480.JPG'),(112,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0494.JPG'),(113,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0443.JPG'),(114,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0457.JPG'),(115,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0456.JPG'),(116,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0442.JPG'),(117,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0495.JPG'),(118,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0431.JPG'),(119,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0419.JPG'),(120,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0418.JPG'),(121,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0430.JPG'),(122,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0432.JPG'),(123,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0426.JPG'),(124,'image/jpeg','/database/__The_n_ew_iP_ad/__7________IM_G_0423.JPG'),(125,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0427.JPG'),(126,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0433.JPG'),(127,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0437.JPG'),(128,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0422.JPG'),(129,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0436.JPG'),(130,'image/png','/database/__The_n_ew_iP_ad/WWDC-AR7-iPad.png'),(131,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0420.JPG'),(132,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0434.JPG'),(133,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0435.JPG'),(134,'image/jpeg','/database/__The_n_ew_iP_ad/IMG_0421.JPG'),(135,'image/jpeg','/database/85test.jpg'),(136,'image/gif','/database/4____test.gif'),(137,'image/jpeg','/database/Luke_Ma_Cherry_Soda_a0RhRQ.jpg'),(138,'image/jpeg','/database/inspiredimages_Brown_beach_YkVqQ2Y.jpg'),(139,'video/mp4','/database/video__1080p__2.mp4'),(140,'image/jpeg','/database/wallpaper-Dark.jpg'),(141,'image/jpeg','/database/2016-02-01_IemanjaFlowers_PT-BR10970450658_1920x1080.jpg'),(142,'image/jpeg','/database/17_test.jpg'),(143,'image/gif','/database/40_test.gif'),(144,'image/jpeg','/database/FrankyChou_Travel_YkVgQWs.jpg'),(145,'image/jpeg','/database/pexels-morteza-ghanbari-18556807.jpg'),(146,'image/jpeg','/database/pexels-manish-jangid-18037510.jpg'),(147,'image/jpeg','/database/2015-11-23_OctoberMorning_ROW15719492089_1920x1080.jpg'),(148,'image/jpeg','/database/Foundry_Sweet_Doughnuts_YkVqRWY.jpg'),(149,'image/jpeg','/database/21test.jpg'),(150,'image/jpeg','/database/43test.jpg'),(151,'video/mp4','/database/61test.mp4'),(152,'image/jpeg','/database/108test.jpg'),(153,'video/mp4','/database/production_id_4763824__2160p_.mp4'),(154,'image/jpeg','/database/Foundry_Morning_with_Milk_YkVkRWQ.jpg'),(155,'video/x-m4v','/database/pexels-kammeran-gonzalezkeola-17838377__Original_.mp4'),(156,'video/mp4','/database/pexels-kammeran-gonzalezkeola-17838377__2160p_.mp4'),(157,'image/jpeg','/database/2015-11-30_OceanSwimRace_EN-AU11288679332_1920x1080.jpg'),(158,'image/jpeg','/database/Mathulak_Flickr_Boats_with_Sunset_akJjQA.jpg'),(159,'video/mp4','/database/production_id_4873244__2160p_.mp4'),(160,'image/jpeg','/database/81test.jpg'),(161,'image/jpeg','/database/Marco_Tanzi_City_At_Night_ZEZiRQ.jpg'),(162,'image/jpeg','/database/diego_torres_Worbarrow_Bay_YkVqQmA.jpg'),(163,'image/jpeg','/database/image020918_003511.jpg'),(164,'video/mp4','/database/MP4Test.mp4'),(165,'video/quicktime','/database/IMG_3324.MOV'),(166,'image/gif','/database/Coffee.gif'),(167,'image/jpeg','/database/75test.jpg'),(168,'image/jpeg','/database/12_test.jpg'),(169,'video/mp4','/database/video__1080p_.mp4'),(170,'image/jpeg','/database/03185_calmness_1680x1050.jpg'),(171,'image/jpeg','/database/39test.jpg'),(172,'image/jpeg','/database/5test.jpg'),(173,'image/jpeg','/database/snow-winter-wood-tree-road-night-nature-imac-27.jpg'),(174,'image/jpeg','/database/16test.jpg'),(175,'image/jpeg','/database/Lara_Danielle_Love_Hearts_YkViQGM.jpg'),(176,'image/jpeg','/database/pexels-zehra-16983649.jpg'),(177,'image/jpeg','/database/89test.jpg'),(178,'image/jpeg','/database/pexels-alina-vilchenko-17435490.jpg'),(179,'image/heic','/database/newImport_05-07-2024/noIMG_3336.HEIC'),(180,'image/heic','/database/newImport_05-07-2024/what__.HEIC'),(181,'image/jpeg','/database/newImport_05-07-2024/BORX8909.jpg'),(182,'image/heic','/database/newImport_05-07-2024/IMG_3323.HEIC'),(183,'image/jpeg','/database/newImport_05-07-2024/anastasia-petrova-193830-unsplash.jpg'),(184,'image/gif','/database/newImport_05-07-2024/giphy-4.gif'),(185,'image/heic','/database/newImport_05-07-2024/IMG_3322.HEIC'),(186,'image/heic','/database/newImport_05-07-2024/IMG_3337.HEIC'),(187,'image/heic','/database/newImport_05-07-2024/IMG_3321.HEIC'),(188,'image/gif','/database/newImport_05-07-2024/flask4-2.gif'),(189,'image/heic','/database/newImport_05-07-2024/what___IMG_3339.HEIC'),(190,'image/heic','/database/newImport_05-07-2024/70458175599__6CDFAA94-B0F7-4A66-938B-04CEDE714AC0.HEIC'),(191,'image/jpeg','/database/newImport_05-07-2024/toy1.jpeg'),(192,'image/gif','/database/newImport_05-07-2024/flask3.gif'),(193,'image/heic','/database/newImport_05-07-2024/IMG_3326_Hello.HEIC'),(194,'image/heic','/database/newImport_05-07-2024/IMG_3330.HEIC'),(195,'image/png','/database/ongliong11-color.png'),(196,'image/jpeg','/database/42test.jpg'),(197,'image/jpeg','/database/realized1-solefield-desktop-2880-x-1800.jpg'),(198,'image/jpeg','/database/Wallpaper/imac-love-computer-wallpaper-1920x1080-3050-1440x900.jpg'),(199,'image/jpeg','/database/Wallpaper/IMG_0003.JPG'),(200,'image/jpeg','/database/Wallpaper/IMG_0017.JPG'),(201,'image/jpeg','/database/Wallpaper/IMG_0006.JPG'),(202,'image/jpeg','/database/Wallpaper/IMG_0013.JPG'),(203,'image/jpeg','/database/Wallpaper/1IMG_0020.JPG'),(204,'image/jpeg','/database/Wallpaper/IMG_0011.JPG'),(205,'image/jpeg','/database/Wallpaper/IMG_0005.JPG'),(206,'image/jpeg','/database/Wallpaper/IMG_0004.JPG'),(207,'image/jpeg','/database/Wallpaper/IMG_0010.JPG'),(208,'image/jpeg','/database/Wallpaper/IMG_0088.JPG'),(209,'image/jpeg','/database/Wallpaper/IMG_0063.JPG'),(210,'image/jpeg','/database/Wallpaper/IMG_0103.JPG'),(211,'image/jpeg','/database/Wallpaper/IMG_0102.JPG'),(212,'image/png','/database/Wallpaper/Sunset-optimized-by-AR7.png'),(213,'image/jpeg','/database/Wallpaper/IMG_0062.JPG'),(214,'image/jpeg','/database/Wallpaper/IMG_0076.JPG'),(215,'image/jpeg','/database/Wallpaper/IMG_0089.JPG'),(216,'image/jpeg','/database/Wallpaper/IMG_0060.JPG'),(217,'image/jpeg','/database/Wallpaper/IMG_0048.JPG'),(218,'image/jpeg','/database/Wallpaper/WWDC-AR7-Mac_air.jpg'),(219,'image/jpeg','/database/Wallpaper/7IMG_0019.JPG'),(220,'image/jpeg','/database/Wallpaper/IMG_0114.JPG'),(221,'image/jpeg','/database/Wallpaper/IMG_0101.JPG'),(222,'image/jpeg','/database/Wallpaper/2IMG_0021.JPG'),(223,'image/png','/database/Wallpaper/1440x900.png'),(224,'image/jpeg','/database/Wallpaper/IMG_0049.JPG'),(225,'image/jpeg','/database/Wallpaper/IMG_0075.JPG'),(226,'image/jpeg','/database/Wallpaper/IMG_0061.JPG'),(227,'image/jpeg','/database/Wallpaper/IMG_0059.JPG'),(228,'image/jpeg','/database/Wallpaper/IMG_0065.JPG'),(229,'image/jpeg','/database/Wallpaper/IMG_0071.JPG'),(230,'image/jpeg','/database/Wallpaper/Ozix-abstract-geometry.jpg'),(231,'image/jpeg','/database/Wallpaper/IMG_0105.JPG'),(232,'image/jpeg','/database/Wallpaper/IMG_0104.JPG'),(233,'image/jpeg','/database/Wallpaper/IMG_0110.JPG'),(234,'image/jpeg','/database/Wallpaper/IMG_0070.JPG'),(235,'image/jpeg','/database/Wallpaper/IMG_0064.JPG'),(236,'image/jpeg','/database/Wallpaper/IMG_0058.JPG'),(237,'image/jpeg','/database/Wallpaper/IMG_0099.JPG'),(238,'image/jpeg','/database/Wallpaper/IMG_0072.JPG'),(239,'image/jpeg','/database/Wallpaper/IMG_0066.JPG'),(240,'image/jpeg','/database/Wallpaper/Ozix-shine.jpg'),(241,'image/jpeg','/database/Wallpaper/IMG_0106.JPG'),(242,'image/jpeg','/database/Wallpaper/IMG_0112.JPG'),(243,'image/jpeg','/database/Wallpaper/IMG_0113.JPG'),(244,'image/jpeg','/database/Wallpaper/IMG_0107.JPG'),(245,'image/jpeg','/database/Wallpaper/Marie_Sturges_Raspberry_640x1136.jpg'),(246,'image/jpeg','/database/Wallpaper/IMG_0067.JPG'),(247,'image/jpeg','/database/Wallpaper/IMG_0073.JPG'),(248,'image/jpeg','/database/Wallpaper/IMG_0098.JPG'),(249,'image/jpeg','/database/Wallpaper/IMG_0095.JPG'),(250,'image/jpeg','/database/Wallpaper/IMG_0081.JPG'),(251,'image/jpeg','/database/Wallpaper/IMG_0056.JPG'),(252,'image/jpeg','/database/Wallpaper/IMG_0042.JPG'),(253,'image/jpeg','/database/Wallpaper/5IMG_0026.JPG'),(254,'image/jpeg','/database/Wallpaper/twilightseye_640x1136.jpg'),(255,'image/jpeg','/database/Wallpaper/IMG_0043.JPG'),(256,'image/jpeg','/database/Wallpaper/IMG_0057.JPG'),(257,'image/jpeg','/database/Wallpaper/IMG_0080.JPG'),(258,'image/jpeg','/database/Wallpaper/IMG_0094.JPG'),(259,'image/jpeg','/database/Wallpaper/IMG_0082.JPG'),(260,'image/jpeg','/database/Wallpaper/apple_wallpaper_coastal-sunset-green_iphone5_parallax.jpg'),(261,'image/jpeg','/database/Wallpaper/IMG_0096.JPG'),(262,'image/jpeg','/database/Wallpaper/IMG_0041.JPG'),(263,'image/jpeg','/database/Wallpaper/IMG_0055.JPG'),(264,'image/jpeg','/database/Wallpaper/IMG_0069.JPG'),(265,'image/jpeg','/database/Wallpaper/IMG_0108.JPG'),(266,'image/png','/database/Wallpaper/iOS_7_Mavericks_by_AR7.png'),(267,'image/jpeg','/database/Wallpaper/IMG_0068.JPG'),(268,'image/jpeg','/database/Wallpaper/IMG_0054.JPG'),(269,'image/jpeg','/database/Wallpaper/IMG_0040.JPG'),(270,'image/jpeg','/database/Wallpaper/IMG_0097.JPG'),(271,'image/jpeg','/database/Wallpaper/IMG_0083.JPG'),(272,'image/jpeg','/database/Wallpaper/IMG_0093.JPG'),(273,'image/jpeg','/database/Wallpaper/IMG_0078.JPG'),(274,'image/jpeg','/database/Wallpaper/IMG_0044.JPG'),(275,'image/jpeg','/database/Wallpaper/IMG_0050.JPG'),(276,'image/jpeg','/database/Wallpaper/apple_wallpaper_picnic-table-nature_iphone5_parallax.jpg'),(277,'image/jpeg','/database/Wallpaper/metro-right.jpg'),(278,'image/jpeg','/database/Wallpaper/IMG_0118.JPG'),(279,'image/jpeg','/database/Wallpaper/IMG_0119.JPG'),(280,'image/jpeg','/database/Wallpaper/IMG_0051.JPG'),(281,'image/jpeg','/database/Wallpaper/IMG_0045.JPG'),(282,'image/jpeg','/database/Wallpaper/IMG_0079.JPG'),(283,'image/jpeg','/database/Wallpaper/IMG_0092.JPG'),(284,'image/jpeg','/database/Wallpaper/IMG_0086.JPG'),(285,'image/jpeg','/database/Wallpaper/IMG_0090.JPG'),(286,'image/jpeg','/database/Wallpaper/IMG_0084.JPG'),(287,'image/jpeg','/database/Wallpaper/IMG_0053.JPG'),(288,'image/jpeg','/database/Wallpaper/IMG_0047.JPG'),(289,'image/jpeg','/database/Wallpaper/Marie_Sturges_Blueberry_640x1136.jpg'),(290,'image/jpeg','/database/Wallpaper/IMG_0046.JPG'),(291,'image/jpeg','/database/Wallpaper/IMG_0052.JPG'),(292,'image/jpeg','/database/Wallpaper/IMG_0085.JPG'),(293,'image/jpeg','/database/Wallpaper/IMG_0091.JPG'),(294,'image/jpeg','/database/Wallpaper/IMG_0035.JPG'),(295,'image/jpeg','/database/Wallpaper/IMG_0021.JPG'),(296,'image/jpeg','/database/Wallpaper/IMG_0009.JPG'),(297,'image/jpeg','/database/Wallpaper/metro-middle.jpg'),(298,'image/jpeg','/database/Wallpaper/IMG_0008.JPG'),(299,'image/jpeg','/database/Wallpaper/IMG_0020.JPG'),(300,'image/jpeg','/database/Wallpaper/IMG_0034.JPG'),(301,'image/jpeg','/database/Wallpaper/IMG_0022.JPG'),(302,'image/jpeg','/database/Wallpaper/IMG_0036.JPG'),(303,'image/jpeg','/database/Wallpaper/3IMG_0024.JPG'),(304,'image/jpeg','/database/Wallpaper/Abstraction-Bubbles-Texture-Color-Creativity.jpg'),(305,'image/jpeg','/database/Wallpaper/Ozix-red-stars.jpg'),(306,'image/jpeg','/database/Wallpaper/IMG_0037.JPG'),(307,'image/jpeg','/database/Wallpaper/IMG_0023.JPG'),(308,'image/jpeg','/database/Wallpaper/IMG_0027.JPG'),(309,'image/jpeg','/database/Wallpaper/IMG_0033.JPG'),(310,'image/jpeg','/database/Wallpaper/8IMG_0017.JPG'),(311,'image/jpeg','/database/Wallpaper/ios7-style-retina-wallpaper.jpg'),(312,'image/jpeg','/database/Wallpaper/IMG_0032.JPG'),(313,'image/jpeg','/database/Wallpaper/IMG_0026.JPG'),(314,'image/jpeg','/database/Wallpaper/6IMG_0027.JPG'),(315,'image/jpeg','/database/Wallpaper/IMG_0018.JPG'),(316,'image/jpeg','/database/Wallpaper/IMG_0030.JPG'),(317,'image/jpeg','/database/Wallpaper/IMG_0024.JPG'),(318,'image/jpeg','/database/Wallpaper/BMFtc_lCAAEOmCY.jpg-large.jpeg'),(319,'image/jpeg','/database/Wallpaper/4IMG_0013.JPG'),(320,'image/jpeg','/database/Wallpaper/BMkwvRbCIAQfI8h.jpg-large.jpeg'),(321,'image/jpeg','/database/Wallpaper/IMG_0025.JPG'),(322,'image/jpeg','/database/Wallpaper/IMG_0031.JPG'),(323,'image/jpeg','/database/Wallpaper/IMG_0019.JPG'),(324,'image/jpeg','/database/9Bombs_Blue_Ocean_YkViRmE.jpg'),(325,'image/jpeg','/database/diego_torres_Night_Ocean_YkVqQmY.jpg'),(326,'image/jpeg','/database/82test.jpg'),(327,'image/jpeg','/database/apple_store_oxmoor_steeber.jpg'),(328,'image/jpeg','/database/49test.jpg'),(329,'image/jpeg','/database/2016-02-02_UpsideDown_ROW12246886594_1920x1080.jpg'),(330,'image/png','/database/iPadPro_Wallpaper.png'),(331,'image/jpeg','/database/14test.jpg'),(332,'image/jpeg','/database/66test.jpg'),(333,'image/jpeg','/database/2015-12-02_BearGlacierLake_ROW11778213520_1920x1080.jpg'),(334,'image/jpeg','/database/76test.jpg'),(335,'image/gif','/database/57test.gif'),(336,'image/jpeg','/database/38__test.jpg'),(337,'image/jpeg','/database/The_Baja_-_MacBook_Pro_Wallpaper.jpg'),(338,'image/jpeg','/database/50test.jpg'),(339,'image/jpeg','/database/32test.jpg'),(340,'image/jpeg','/database/03045_spectrumarray_1680x1050.jpg'),(341,'image/jpeg','/database/Lies_Thru_a_Lens_The_Yellow_Fields_YkVjR2E.jpg'),(342,'image/jpeg','/database/photo-1464621922360-27f3bf0eca75.jpeg'),(343,'video/mp4','/database/production_id_4237839__2160p_.mp4'),(344,'video/mp4','/database/pexels-ibrahim-bennett-18522098__Original_.mp4'),(345,'image/jpeg','/database/John_Fowler_A_Branch_on_The_Beach_YkVgQGA.jpg'),(346,'image/jpeg','/database/48test.jpg'),(347,'image/heic','/database/testHeic.heic'),(348,'image/heic','/database/IMG_4787.HEIC'),(349,'image/jpeg','/database/103test.jpg'),(350,'image/jpeg','/database/15test.jpg'),(351,'image/jpeg','/database/pexels-israel-torres-18290834.jpg'),(352,'image/jpeg','/database/alan_f_Eiffel_Tower__akJhSQ.jpg'),(353,'video/mp4','/database/production_id_4911644__2160p_.mp4'),(354,'image/jpeg','/database/77test.jpg');
/*!40000 ALTER TABLE `SourceFile` ENABLE KEYS */;
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
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`db_gallery`@`localhost`*/ /*!50003 TRIGGER `TempAiTags_AFTER_INSERT` AFTER INSERT ON `tempaitags` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Thumbnail`
--

DROP TABLE IF EXISTS `Thumbnail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Thumbnail` (
  `media` int unsigned NOT NULL,
  `ThumbWidth` smallint DEFAULT NULL,
  `ThumbHeight` smallint DEFAULT NULL,
  `SourceThumb` varchar(1024) DEFAULT NULL,
  `UrlThumb` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_THUMBNAIL_MEDIA_ID` FOREIGN KEY (`media`) REFERENCES `Media` (`media_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Thumbnail`
--

LOCK TABLES `Thumbnail` WRITE;
/*!40000 ALTER TABLE `Thumbnail` DISABLE KEYS */;
/*!40000 ALTER TABLE `Thumbnail` ENABLE KEYS */;
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
INSERT INTO `UploadBy` VALUES (1,1,'2024-12-30 20:21:19'),(1,2,'2024-12-30 20:21:19'),(1,3,'2024-12-30 20:21:19'),(1,4,'2024-12-30 20:21:19'),(1,5,'2024-12-30 20:21:19'),(1,6,'2024-12-30 20:21:19'),(1,7,'2024-12-30 20:21:19'),(1,8,'2024-12-30 20:21:19'),(1,9,'2024-12-30 20:21:19'),(1,10,'2024-12-30 20:21:19'),(1,11,'2024-12-30 20:21:19'),(1,12,'2024-12-30 20:21:19'),(1,13,'2024-12-30 20:21:19'),(1,14,'2024-12-30 20:21:19'),(1,15,'2024-12-30 20:21:19'),(1,16,'2024-12-30 20:21:19'),(1,17,'2024-12-30 20:21:19'),(1,18,'2024-12-30 20:21:19'),(1,19,'2024-12-30 20:21:19'),(1,20,'2024-12-30 20:21:19'),(1,21,'2024-12-30 20:21:19'),(1,22,'2024-12-30 20:21:19'),(1,23,'2024-12-30 20:21:19'),(1,24,'2024-12-30 20:21:19'),(1,25,'2024-12-30 20:21:19'),(1,26,'2024-12-30 20:21:19'),(1,27,'2024-12-30 20:21:19'),(1,28,'2024-12-30 20:21:19'),(1,29,'2024-12-30 20:21:19'),(1,30,'2024-12-30 20:21:19'),(1,31,'2024-12-30 20:21:19'),(1,32,'2024-12-30 20:21:19'),(1,33,'2024-12-30 20:21:19'),(1,34,'2024-12-30 20:21:19'),(1,35,'2024-12-30 20:21:19'),(1,36,'2024-12-30 20:21:19'),(1,37,'2024-12-30 20:21:19'),(1,38,'2024-12-30 20:21:19'),(1,39,'2024-12-30 20:21:19'),(1,40,'2024-12-30 20:21:19'),(1,41,'2024-12-30 20:21:19'),(1,42,'2024-12-30 20:21:19'),(1,43,'2024-12-30 20:21:19'),(1,44,'2024-12-30 20:21:19'),(1,45,'2024-12-30 20:21:19'),(1,46,'2024-12-30 20:21:19'),(1,47,'2024-12-30 20:21:19'),(1,48,'2024-12-30 20:21:19'),(1,49,'2024-12-30 20:21:19'),(1,50,'2024-12-30 20:21:19'),(1,51,'2024-12-30 20:21:19'),(1,52,'2024-12-30 20:21:19'),(1,53,'2024-12-30 20:21:19'),(1,54,'2024-12-30 20:21:19'),(1,55,'2024-12-30 20:21:19'),(1,56,'2024-12-30 20:21:19'),(1,57,'2024-12-30 20:21:19'),(1,58,'2024-12-30 20:21:19'),(1,59,'2024-12-30 20:21:19'),(1,60,'2024-12-30 20:21:19'),(1,61,'2024-12-30 20:21:19'),(1,62,'2024-12-30 20:21:19'),(1,63,'2024-12-30 20:21:19'),(1,64,'2024-12-30 20:21:19'),(1,65,'2024-12-30 20:21:19'),(1,66,'2024-12-30 20:21:19'),(1,67,'2024-12-30 20:21:19'),(1,68,'2024-12-30 20:21:19'),(1,69,'2024-12-30 20:21:19'),(1,70,'2024-12-30 20:21:19'),(1,71,'2024-12-30 20:21:19'),(1,72,'2024-12-30 20:21:19'),(1,73,'2024-12-30 20:21:19'),(1,74,'2024-12-30 20:21:19'),(1,75,'2024-12-30 20:21:19'),(1,76,'2024-12-30 20:21:19'),(1,77,'2024-12-30 20:21:19'),(1,78,'2024-12-30 20:21:19'),(1,79,'2024-12-30 20:21:19'),(1,80,'2024-12-30 20:21:19'),(1,81,'2024-12-30 20:21:19'),(1,82,'2024-12-30 20:21:19'),(1,83,'2024-12-30 20:21:19'),(1,84,'2024-12-30 20:21:19'),(1,85,'2024-12-30 20:21:19'),(1,86,'2024-12-30 20:21:19'),(1,87,'2024-12-30 20:21:19'),(1,88,'2024-12-30 20:21:19'),(1,89,'2024-12-30 20:21:19'),(1,90,'2024-12-30 20:21:19'),(1,91,'2024-12-30 20:21:19'),(1,92,'2024-12-30 20:21:19'),(1,93,'2024-12-30 20:21:19'),(1,94,'2024-12-30 20:21:19'),(1,95,'2024-12-30 20:21:19'),(1,96,'2024-12-30 20:21:19'),(1,97,'2024-12-30 20:21:19'),(1,98,'2024-12-30 20:21:19'),(1,99,'2024-12-30 20:21:19'),(1,100,'2024-12-30 20:21:19'),(1,101,'2024-12-30 20:21:19'),(1,102,'2024-12-30 20:21:19'),(1,103,'2024-12-30 20:21:19'),(1,104,'2024-12-30 20:21:19'),(1,105,'2024-12-30 20:21:19'),(1,106,'2024-12-30 20:21:19'),(1,107,'2024-12-30 20:21:19'),(1,108,'2024-12-30 20:21:19'),(1,109,'2024-12-30 20:21:19'),(1,110,'2024-12-30 20:21:19'),(1,111,'2024-12-30 20:21:19'),(1,112,'2024-12-30 20:21:19'),(1,113,'2024-12-30 20:21:19'),(1,114,'2024-12-30 20:21:19'),(1,115,'2024-12-30 20:21:19'),(1,116,'2024-12-30 20:21:19'),(1,117,'2024-12-30 20:21:19'),(1,118,'2024-12-30 20:21:19'),(1,119,'2024-12-30 20:21:19'),(1,120,'2024-12-30 20:21:19'),(1,121,'2024-12-30 20:21:19'),(1,122,'2024-12-30 20:21:19'),(1,123,'2024-12-30 20:21:19'),(1,124,'2024-12-30 20:21:19'),(1,125,'2024-12-30 20:21:19'),(1,126,'2024-12-30 20:21:19'),(1,127,'2024-12-30 20:21:19'),(1,128,'2024-12-30 20:21:19'),(1,129,'2024-12-30 20:21:19'),(1,130,'2024-12-30 20:21:19'),(1,131,'2024-12-30 20:21:19'),(1,132,'2024-12-30 20:21:19'),(1,133,'2024-12-30 20:21:19'),(1,134,'2024-12-30 20:21:19'),(1,135,'2024-12-30 20:21:19'),(1,136,'2024-12-30 20:21:19'),(1,137,'2024-12-30 20:21:19'),(1,138,'2024-12-30 20:21:19'),(1,139,'2024-12-30 20:21:19'),(1,140,'2024-12-30 20:21:19'),(1,141,'2024-12-30 20:21:19'),(1,142,'2024-12-30 20:21:19'),(1,143,'2024-12-30 20:21:19'),(1,144,'2024-12-30 20:21:19'),(1,145,'2024-12-30 20:21:19'),(1,146,'2024-12-30 20:21:19'),(1,147,'2024-12-30 20:21:19'),(1,148,'2024-12-30 20:21:19'),(1,149,'2024-12-30 20:21:19'),(1,150,'2024-12-30 20:21:19'),(1,151,'2024-12-30 20:21:19'),(1,152,'2024-12-30 20:21:19'),(1,153,'2024-12-30 20:21:19'),(1,154,'2024-12-30 20:21:19'),(1,155,'2024-12-30 20:21:19'),(1,156,'2024-12-30 20:21:19'),(1,157,'2024-12-30 20:21:19'),(1,158,'2024-12-30 20:21:19'),(1,159,'2024-12-30 20:21:19'),(1,160,'2024-12-30 20:21:19'),(1,161,'2024-12-30 20:21:19'),(1,162,'2024-12-30 20:21:19'),(1,163,'2024-12-30 20:21:19'),(1,164,'2024-12-30 20:21:19'),(1,165,'2024-12-30 20:21:19'),(1,166,'2024-12-30 20:21:19'),(1,167,'2024-12-30 20:21:19'),(1,168,'2024-12-30 20:21:19'),(1,169,'2024-12-30 20:21:19'),(1,170,'2024-12-30 20:21:19'),(1,171,'2024-12-30 20:21:19'),(1,172,'2024-12-30 20:21:19'),(1,173,'2024-12-30 20:21:19'),(1,174,'2024-12-30 20:21:19'),(1,175,'2024-12-30 20:21:19'),(1,176,'2024-12-30 20:21:19'),(1,177,'2024-12-30 20:21:19'),(1,178,'2024-12-30 20:21:19'),(1,179,'2024-12-30 20:21:19'),(1,180,'2024-12-30 20:21:19'),(1,181,'2024-12-30 20:21:19'),(1,182,'2024-12-30 20:21:19'),(1,183,'2024-12-30 20:21:19'),(1,184,'2024-12-30 20:21:19'),(1,185,'2024-12-30 20:21:19'),(1,186,'2024-12-30 20:21:19'),(1,187,'2024-12-30 20:21:19'),(1,188,'2024-12-30 20:21:19'),(1,189,'2024-12-30 20:21:19'),(1,190,'2024-12-30 20:21:19'),(1,191,'2024-12-30 20:21:19'),(1,192,'2024-12-30 20:21:19'),(1,193,'2024-12-30 20:21:19'),(1,194,'2024-12-30 20:21:19'),(1,195,'2024-12-30 20:21:19'),(1,196,'2024-12-30 20:21:19'),(1,197,'2024-12-30 20:21:19'),(1,198,'2024-12-30 20:21:19'),(1,199,'2024-12-30 20:21:19'),(1,200,'2024-12-30 20:21:19'),(1,201,'2024-12-30 20:21:19'),(1,202,'2024-12-30 20:21:19'),(1,203,'2024-12-30 20:21:19'),(1,204,'2024-12-30 20:21:19'),(1,205,'2024-12-30 20:21:19'),(1,206,'2024-12-30 20:21:19'),(1,207,'2024-12-30 20:21:19'),(1,208,'2024-12-30 20:21:19'),(1,209,'2024-12-30 20:21:19'),(1,210,'2024-12-30 20:21:19'),(1,211,'2024-12-30 20:21:19'),(1,212,'2024-12-30 20:21:19'),(1,213,'2024-12-30 20:21:19'),(1,214,'2024-12-30 20:21:19'),(1,215,'2024-12-30 20:21:19'),(1,216,'2024-12-30 20:21:19'),(1,217,'2024-12-30 20:21:19'),(1,218,'2024-12-30 20:21:19'),(1,219,'2024-12-30 20:21:19'),(1,220,'2024-12-30 20:21:19'),(1,221,'2024-12-30 20:21:19'),(1,222,'2024-12-30 20:21:19'),(1,223,'2024-12-30 20:21:19'),(1,224,'2024-12-30 20:21:19'),(1,225,'2024-12-30 20:21:19'),(1,226,'2024-12-30 20:21:19'),(1,227,'2024-12-30 20:21:19'),(1,228,'2024-12-30 20:21:19'),(1,229,'2024-12-30 20:21:19'),(1,230,'2024-12-30 20:21:19'),(1,231,'2024-12-30 20:21:19'),(1,232,'2024-12-30 20:21:19'),(1,233,'2024-12-30 20:21:19'),(1,234,'2024-12-30 20:21:19'),(1,235,'2024-12-30 20:21:19'),(1,236,'2024-12-30 20:21:19'),(1,237,'2024-12-30 20:21:19'),(1,238,'2024-12-30 20:21:19'),(1,239,'2024-12-30 20:21:19'),(1,240,'2024-12-30 20:21:19'),(1,241,'2024-12-30 20:21:19'),(1,242,'2024-12-30 20:21:19'),(1,243,'2024-12-30 20:21:19'),(1,244,'2024-12-30 20:21:19'),(1,245,'2024-12-30 20:21:19'),(1,246,'2024-12-30 20:21:19'),(1,247,'2024-12-30 20:21:19'),(1,248,'2024-12-30 20:21:19'),(1,249,'2024-12-30 20:21:19'),(1,250,'2024-12-30 20:21:19'),(1,251,'2024-12-30 20:21:19'),(1,252,'2024-12-30 20:21:19'),(1,253,'2024-12-30 20:21:19'),(1,254,'2024-12-30 20:21:19'),(1,255,'2024-12-30 20:21:19'),(1,256,'2024-12-30 20:21:19'),(1,257,'2024-12-30 20:21:19'),(1,258,'2024-12-30 20:21:19'),(1,259,'2024-12-30 20:21:19'),(1,260,'2024-12-30 20:21:19'),(1,261,'2024-12-30 20:21:19'),(1,262,'2024-12-30 20:21:19'),(1,263,'2024-12-30 20:21:19'),(1,264,'2024-12-30 20:21:19'),(1,265,'2024-12-30 20:21:19'),(1,266,'2024-12-30 20:21:19'),(1,267,'2024-12-30 20:21:19'),(1,268,'2024-12-30 20:21:19'),(1,269,'2024-12-30 20:21:19'),(1,270,'2024-12-30 20:21:19'),(1,271,'2024-12-30 20:21:19'),(1,272,'2024-12-30 20:21:19'),(1,273,'2024-12-30 20:21:19'),(1,274,'2024-12-30 20:21:19'),(1,275,'2024-12-30 20:21:19'),(1,276,'2024-12-30 20:21:19'),(1,277,'2024-12-30 20:21:19'),(1,278,'2024-12-30 20:21:19'),(1,279,'2024-12-30 20:21:19'),(1,280,'2024-12-30 20:21:19'),(1,281,'2024-12-30 20:21:19'),(1,282,'2024-12-30 20:21:19'),(1,283,'2024-12-30 20:21:19'),(1,284,'2024-12-30 20:21:19'),(1,285,'2024-12-30 20:21:19'),(1,286,'2024-12-30 20:21:19'),(1,287,'2024-12-30 20:21:19'),(1,288,'2024-12-30 20:21:19'),(1,289,'2024-12-30 20:21:19'),(1,290,'2024-12-30 20:21:19'),(1,291,'2024-12-30 20:21:19'),(1,292,'2024-12-30 20:21:19'),(1,293,'2024-12-30 20:21:19'),(1,294,'2024-12-30 20:21:19'),(1,295,'2024-12-30 20:21:19'),(1,296,'2024-12-30 20:21:19'),(1,297,'2024-12-30 20:21:19'),(1,298,'2024-12-30 20:21:19'),(1,299,'2024-12-30 20:21:19'),(1,300,'2024-12-30 20:21:19'),(1,301,'2024-12-30 20:21:19'),(1,302,'2024-12-30 20:21:19'),(1,303,'2024-12-30 20:21:19'),(1,304,'2024-12-30 20:21:19'),(1,305,'2024-12-30 20:21:19'),(1,306,'2024-12-30 20:21:19'),(1,307,'2024-12-30 20:21:19'),(1,308,'2024-12-30 20:21:19'),(1,309,'2024-12-30 20:21:19'),(1,310,'2024-12-30 20:21:19'),(1,311,'2024-12-30 20:21:19'),(1,312,'2024-12-30 20:21:19'),(1,313,'2024-12-30 20:21:19'),(1,314,'2024-12-30 20:21:19'),(1,315,'2024-12-30 20:21:19'),(1,316,'2024-12-30 20:21:19'),(1,317,'2024-12-30 20:21:19'),(1,318,'2024-12-30 20:21:19'),(1,319,'2024-12-30 20:21:19'),(1,320,'2024-12-30 20:21:19'),(1,321,'2024-12-30 20:21:19'),(1,322,'2024-12-30 20:21:19'),(1,323,'2024-12-30 20:21:19'),(1,324,'2024-12-30 20:21:19'),(1,325,'2024-12-30 20:21:19'),(1,326,'2024-12-30 20:21:19'),(1,327,'2024-12-30 20:21:19'),(1,328,'2024-12-30 20:21:19'),(1,329,'2024-12-30 20:21:19'),(1,330,'2024-12-30 20:21:19'),(1,331,'2024-12-30 20:21:19'),(1,332,'2024-12-30 20:21:19'),(1,333,'2024-12-30 20:21:19'),(1,334,'2024-12-30 20:21:19'),(1,335,'2024-12-30 20:21:19'),(1,336,'2024-12-30 20:21:19'),(1,337,'2024-12-30 20:21:19'),(1,338,'2024-12-30 20:21:19'),(1,339,'2024-12-30 20:21:19'),(1,340,'2024-12-30 20:21:19'),(1,341,'2024-12-30 20:21:19'),(1,342,'2024-12-30 20:21:19'),(1,343,'2024-12-30 20:21:19'),(1,344,'2024-12-30 20:21:19'),(1,345,'2024-12-30 20:21:19'),(1,346,'2024-12-30 20:21:19'),(1,347,'2024-12-30 20:21:19'),(1,348,'2024-12-30 20:21:19'),(1,349,'2024-12-30 20:21:19'),(1,350,'2024-12-30 20:21:19'),(1,351,'2024-12-30 20:21:19'),(1,352,'2024-12-30 20:21:19'),(1,353,'2024-12-30 20:21:19'),(1,354,'2024-12-30 20:21:19');
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `UserGuest`
--

LOCK TABLES `UserGuest` WRITE;
/*!40000 ALTER TABLE `UserGuest` DISABLE KEYS */;
INSERT INTO `UserGuest` VALUES (1,'user1@example.com','Alice Smith',1,'2024-12-30 20:21:18'),(2,'jane.smith@example.com','Jane Smith',0,NULL),(3,'john.doe@example.com','Carol Williams',0,NULL);
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
INSERT INTO `Video` VALUES (4,30,'','0:30'),(9,14.8333333333333,'','0:15'),(11,24.02,'','0:24'),(19,7.83333333333333,'','0:08'),(21,242.928,'Mariah Carey - All I Want for Christmas Is You (Make My Wish Come True Edition)','4:03'),(139,31.5315,'','0:32'),(151,13.314,'','0:13'),(153,14.125,'','0:14'),(155,20.1666666666667,'Untitled Project','0:20'),(156,20.1666666666667,'','0:20'),(159,14.12,'','0:14'),(164,185.706666666667,'','3:06'),(165,19.4166666666667,'','0:19'),(169,12.2789333333333,'','0:12'),(343,15.5572083333333,'','0:16'),(344,26.667,'','0:27'),(353,17.0503666666667,'','0:17');
/*!40000 ALTER TABLE `Video` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `adminuserlogview`
--

/*!50001 DROP VIEW IF EXISTS `adminuserlogview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`db_gallery`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `adminuserlogview` AS select `u`.`user_id` AS `UserID`,`u`.`user_name` AS `UserName`,`u`.`user_email` AS `UserEmail`,`u`.`request_status` AS `UserReq`,`ul`.`ip_address` AS `IPAddress`,`ul`.`user_device` AS `UserDevice`,`ul`.`last_url_request` AS `LastURLRequest`,`ul`.`last_logged_in` AS `LastLoggedIn`,`ul`.`ip_address` AS `LastIP`,`ul`.`logged_at` AS `LogTime` from (`userguest` `u` join `userlog` `ul` on((`u`.`user_id` = `ul`.`UserGuest`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `mediasearchview`
--

/*!50001 DROP VIEW IF EXISTS `mediasearchview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`db_gallery`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `mediasearchview` AS with `aiclasses` as (select `ai`.`media` AS `media`,`al`.`ClassName` AS `ClassName`,row_number() OVER (PARTITION BY `ai`.`media` ORDER BY `al`.`ClassName` desc )  AS `RowNum` from (`airecognition` `ai` left join `aiclass` `al` on((`ai`.`AiClass` = `al`.`class_id`)))) select `im`.`media_id` AS `media_id`,`im`.`FileType` AS `FileType`,`im`.`FileName` AS `FileName`,`im`.`CreateDate` AS `CreateDate`,(case when (`im`.`FileSize` < 1024) then concat(`im`.`FileSize`,' B') when (`im`.`FileSize` < (1024 * 1024)) then concat(round((`im`.`FileSize` / 1024),2),' KB') when (`im`.`FileSize` < ((1024 * 1024) * 1024)) then concat(round((`im`.`FileSize` / (1024 * 1024)),2),' MB') else concat(round((`im`.`FileSize` / ((1024 * 1024) * 1024)),2),' GB') end) AS `fSize`,`im`.`FileSize` AS `FileSize`,`im`.`FileExt` AS `FileExt`,`im`.`URL` AS `URL`,`ac`.`ClassName` AS `ClassName`,`c`.`Make` AS `Make`,`c`.`Model` AS `Model`,`p`.`Megapixels` AS `Megapixels`,`v`.`DisplayDuration` AS `DisplayDuration`,`v`.`Title` AS `Title`,`loc`.`City` AS `City`,`loc`.`GPSLatitude` AS `GPSLatitude`,`loc`.`GPSLongitude` AS `GPSLongitude` from (((((((`media` `im` left join `photo` `p` on((`im`.`media_id` = `p`.`media`))) left join `live` `l` on((`im`.`media_id` = `l`.`media`))) left join `video` `v` on((`im`.`media_id` = `v`.`media`))) left join `thumbnail` `tn` on((`im`.`media_id` = `tn`.`media`))) left join `cameratype` `c` on((`im`.`CameraType` = `c`.`camera_id`))) left join `location` `loc` on((`im`.`media_id` = `loc`.`media`))) left join `aiclasses` `ac` on(((`im`.`media_id` = `ac`.`media`) and (`ac`.`RowNum` = 1)))) */;
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

-- Dump completed on 2024-12-30 12:21:22
