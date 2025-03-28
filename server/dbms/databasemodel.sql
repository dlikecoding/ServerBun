-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema Photos
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema Photos
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `Photos` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `Photos` ;

-- -----------------------------------------------------
-- Table `Photos`.`ServerSystem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`ServerSystem` (
  `uuid` VARCHAR(36) NOT NULL,
  `process_medias` TINYINT(1) NULL DEFAULT 0 COMMENT 'Have been processed thumbnails, hash, object detection for all of medias if 1, otherwise is 0',
  `license_key` VARCHAR(512) NULL DEFAULT NULL,
  PRIMARY KEY (`uuid`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`AIModel`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`AIModel` (
  `ai_model_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source_path` TEXT NOT NULL,
  `model` ENUM('classify', 'detect', 'segment') NOT NULL,
  `cmd` TEXT NOT NULL,
  `description` VARCHAR(100) NULL DEFAULT NULL,
  `server_system` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`ai_model_id`),
  INDEX `FK_AiMODEL_SERVERSYS_ID_idx` (`server_system` ASC) VISIBLE,
  CONSTRAINT `FK_AiMODEL_SERVERSYS_ID`
    FOREIGN KEY (`server_system`)
    REFERENCES `Photos`.`ServerSystem` (`uuid`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`RegisteredUser`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`RegisteredUser` (
  `reg_user_id` VARCHAR(36) NOT NULL DEFAULT 'UUID()',
  `user_email` VARCHAR(100) NOT NULL,
  `user_name` VARCHAR(45) NOT NULL,
  `role_type` ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  `status` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '“Suspended” = 0,  “Active” = 1',
  `m2f_isEnable` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'If enable, send an email with code to verify login',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`reg_user_id`),
  UNIQUE INDEX `user_email_UNIQUE` (`user_email` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`CameraType`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`CameraType` (
  `camera_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Make` VARCHAR(50) NULL DEFAULT NULL,
  `Model` VARCHAR(100) NULL DEFAULT NULL,
  `LensModel` VARCHAR(200) NULL DEFAULT NULL,
  PRIMARY KEY (`camera_id`),
  INDEX `CameraType_Idx` (`Make` ASC, `Model` ASC, `LensModel` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Media`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Media` (
  `media_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FileType` ENUM('Photo', 'Video', 'Live', 'Unknown') NOT NULL,
  `FileName` TEXT NULL DEFAULT NULL,
  `CreateDate` DATETIME NULL DEFAULT NULL,
  `FileSize` BIGINT UNSIGNED NULL DEFAULT NULL,
  `HashCode` VARCHAR(65) NULL DEFAULT NULL,
  `Hidden` TINYINT(1) UNSIGNED NULL DEFAULT 0,
  `Favorite` TINYINT(1) UNSIGNED NULL DEFAULT 0,
  `Deleted` TINYINT(1) UNSIGNED NULL DEFAULT 0,
  `DeletionDate` TIMESTAMP NULL DEFAULT NULL,
  `CameraType` INT UNSIGNED NULL,
  `UploadAt` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `FileExt` VARCHAR(50) NULL DEFAULT NULL,
  `Software` VARCHAR(256) NULL DEFAULT NULL,
  `SourceFile` TEXT NULL DEFAULT NULL,
  `MIMEType` VARCHAR(50) NULL DEFAULT NULL,
  `ThumbPath` TEXT NULL DEFAULT NULL,
  `ThumbWidth` SMALLINT NULL DEFAULT NULL,
  `ThumbHeight` SMALLINT NULL DEFAULT NULL,
  PRIMARY KEY (`media_id`),
  INDEX `FK_MEDIA_SOURCEFILE_ID_idx` (`CameraType` ASC) VISIBLE,
  CONSTRAINT `FK_MEDIA_CAMERATYPE_ID`
    FOREIGN KEY (`CameraType`)
    REFERENCES `Photos`.`CameraType` (`camera_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`AiClass`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`AiClass` (
  `class_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ClassName` VARCHAR(50) NOT NULL,
  `Created` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `Modified` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`class_id`),
  UNIQUE INDEX `ClassName_UNIQUE` (`ClassName` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`AiRecognition`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`AiRecognition` (
  `ai_recognition_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `media` INT UNSIGNED NOT NULL,
  `AiClass` INT UNSIGNED NOT NULL,
  `AiMode` ENUM('Detect', 'Classify', 'Segment', 'Face') NOT NULL,
  PRIMARY KEY (`ai_recognition_id`),
  UNIQUE INDEX `UNIQUE_MEDIA_CLASS_MODE` (`media` ASC, `AiClass` ASC, `AiMode` ASC) VISIBLE,
  INDEX `PKFK_AIRECOGNITION_AICLASS_ID_idx` (`AiClass` ASC) VISIBLE,
  CONSTRAINT `PKFK_AIMEDIALABEL_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `PKFK_AIRECOGNITION_AICLASS_ID`
    FOREIGN KEY (`AiClass`)
    REFERENCES `Photos`.`AiClass` (`class_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Album`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Album` (
  `album_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `RegisteredUser` VARCHAR(36) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `title` VARCHAR(50) NULL DEFAULT NULL,
  `modify_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`album_id`),
  UNIQUE INDEX `title_UNIQUE` (`title` ASC) VISIBLE,
  CONSTRAINT `FK_ALBUM_REGISTERED_USER_ID`
    FOREIGN KEY (`RegisteredUser`)
    REFERENCES `Photos`.`RegisteredUser` (`reg_user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`AlbumMedia`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`AlbumMedia` (
  `album` INT UNSIGNED NOT NULL,
  `media` INT UNSIGNED NOT NULL,
  INDEX `FK_ALBUMMEDIA_MEDIA_ID_idx` (`media` ASC) VISIBLE,
  PRIMARY KEY (`album`, `media`),
  CONSTRAINT `PKFK_ALBUMMEDIA_ALBUM_ID`
    FOREIGN KEY (`album`)
    REFERENCES `Photos`.`Album` (`album_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `PKFK_ALBUMMEDIA_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Classify`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Classify` (
  `classify_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ai_recognition` INT UNSIGNED NOT NULL,
  `confidence` DECIMAL(18,17) NOT NULL,
  PRIMARY KEY (`classify_id`),
  INDEX `PKFK_CLASSIFY_AiRECOG_ID_idx` (`ai_recognition` ASC) VISIBLE,
  CONSTRAINT `PKFK_CLASSIFY_AiRECOG_ID`
    FOREIGN KEY (`ai_recognition`)
    REFERENCES `Photos`.`AiRecognition` (`ai_recognition_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Detect`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Detect` (
  `detection_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ai_recognition` INT UNSIGNED NOT NULL,
  `confidence` DECIMAL(18,17) NOT NULL,
  `b_box` JSON NOT NULL,
  PRIMARY KEY (`detection_id`),
  INDEX `PKFK_DETECT_AiRECOG_ID_idx` (`ai_recognition` ASC) VISIBLE,
  CONSTRAINT `PKFK_DETECT_AiRECOG_ID`
    FOREIGN KEY (`ai_recognition`)
    REFERENCES `Photos`.`AiRecognition` (`ai_recognition_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`ErrorLog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`ErrorLog` (
  `error_log_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `error_msg` TEXT NOT NULL,
  `stack_trace` TEXT NULL DEFAULT NULL,
  `error_type` ENUM('frontend', 'backend', 'database') NULL DEFAULT NULL,
  `server_system` VARCHAR(36) NULL,
  `logged_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`error_log_id`),
  INDEX `FK_ERRORLOG_SYSTEM_ID_idx` (`server_system` ASC) VISIBLE,
  INDEX `ErrorLog_Logged_ErrorType_idx` (`logged_at` ASC, `error_type` ASC) VISIBLE,
  CONSTRAINT `FK_ERRORLOG_SYSTEM_ID`
    FOREIGN KEY (`server_system`)
    REFERENCES `Photos`.`ServerSystem` (`uuid`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`ImportMedias`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`ImportMedias` (
  `import_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FileName` TEXT NULL DEFAULT NULL,
  `FileType` VARCHAR(50) NULL DEFAULT NULL,
  `MIMEType` VARCHAR(50) NULL DEFAULT NULL,
  `Software` VARCHAR(255) NULL DEFAULT NULL,
  `Title` VARCHAR(255) NULL DEFAULT NULL,
  `FileSize` BIGINT UNSIGNED NULL DEFAULT NULL,
  `Make` VARCHAR(100) NULL DEFAULT NULL,
  `Model` VARCHAR(100) NULL DEFAULT NULL,
  `LensModel` VARCHAR(255) NULL DEFAULT NULL,
  `Orientation` VARCHAR(50) NULL DEFAULT NULL,
  `CreateDate` VARCHAR(20) NULL DEFAULT NULL,
  `DateCreated` VARCHAR(20) NULL DEFAULT NULL,
  `CreationDate` VARCHAR(20) NULL DEFAULT NULL,
  `DateTimeOriginal` VARCHAR(20) NULL DEFAULT NULL,
  `FileModifyDate` VARCHAR(20) NULL DEFAULT NULL,
  `MediaCreateDate` VARCHAR(20) NULL DEFAULT NULL,
  `MediaModifyDate` VARCHAR(20) NULL DEFAULT NULL,
  `Duration` DOUBLE NULL DEFAULT NULL,
  `GPSLatitude` DOUBLE NULL DEFAULT NULL,
  `GPSLongitude` DOUBLE NULL DEFAULT NULL,
  `ImageWidth` SMALLINT UNSIGNED NULL DEFAULT NULL,
  `ImageHeight` SMALLINT UNSIGNED NULL DEFAULT NULL,
  `SourceFile` TEXT NULL DEFAULT NULL,
  `Megapixels` DECIMAL(5,2) NULL DEFAULT NULL,
  `RegisteredUser` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`import_id`),
  INDEX `FK_IMPORTMEDIAS_REGISTERED_USER_ID_idx` (`RegisteredUser` ASC) VISIBLE,
  CONSTRAINT `FK_IMPORTMEDIAS_REGISTERED_USER_ID`
    FOREIGN KEY (`RegisteredUser`)
    REFERENCES `Photos`.`RegisteredUser` (`reg_user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Live`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Live` (
  `media` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FrameCount` INT NULL DEFAULT NULL,
  `CurrentFrame` SMALLINT NULL DEFAULT NULL,
  `Duration` INT NULL DEFAULT NULL,
  `Title` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_LIVE_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Location`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Location` (
  `media` INT UNSIGNED NOT NULL,
  `City` VARCHAR(50) NULL DEFAULT NULL,
  `State` VARCHAR(50) NULL DEFAULT NULL,
  `Country` VARCHAR(50) NULL DEFAULT NULL,
  `GPSLatitude` DOUBLE NULL DEFAULT NULL,
  `GPSLongitude` DOUBLE NULL DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_LOCATION_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Photo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Photo` (
  `media` INT UNSIGNED NOT NULL,
  `Orientation` VARCHAR(45) NULL DEFAULT NULL,
  `ImageWidth` SMALLINT NULL DEFAULT NULL,
  `ImageHeight` SMALLINT NULL DEFAULT NULL,
  `Megapixels` DOUBLE NULL DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_PHOTO_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Segment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Segment` (
  `segment_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ai_recognition` INT UNSIGNED NOT NULL,
  `confidence` DECIMAL(18,17) NOT NULL,
  `b_box` JSON NOT NULL,
  PRIMARY KEY (`segment_id`),
  INDEX `PKFK_SEGMENT_AiRECOG_ID_idx` (`ai_recognition` ASC) VISIBLE,
  CONSTRAINT `PKFK_SEGMENT_AiRECOG_ID`
    FOREIGN KEY (`ai_recognition`)
    REFERENCES `Photos`.`AiRecognition` (`ai_recognition_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`UploadBy`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`UploadBy` (
  `RegisteredUser` VARCHAR(36) NOT NULL,
  `media` INT UNSIGNED NOT NULL,
  `uploaded_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`media`, `RegisteredUser`),
  CONSTRAINT `PKFK_UPLOADBY_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `PKFK_UPLOADBY_REGISTERED_USER_ID`
    FOREIGN KEY (`RegisteredUser`)
    REFERENCES `Photos`.`RegisteredUser` (`reg_user_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`UserLog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`UserLog` (
  `user_log_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `RegisteredUser` VARCHAR(36) NULL,
  `user_device` VARCHAR(255) NULL DEFAULT NULL,
  `last_url_request` VARCHAR(200) NULL DEFAULT NULL,
  `last_logged_in` TIMESTAMP NULL,
  `ip_address` VARCHAR(45) NOT NULL,
  `logged_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_log_id`),
  INDEX `FK_REG_USER_USERLOG_ID0_idx` (`RegisteredUser` ASC) VISIBLE,
  CONSTRAINT `FK_REG_USER_USERLOG_ID0`
    FOREIGN KEY (`RegisteredUser`)
    REFERENCES `Photos`.`RegisteredUser` (`reg_user_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Video`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Video` (
  `media` INT UNSIGNED NOT NULL,
  `Duration` DOUBLE NULL DEFAULT NULL,
  `Title` VARCHAR(255) NULL DEFAULT NULL,
  `DisplayDuration` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`media`),
  CONSTRAINT `PKFK_VIDEO_MEDIA_ID`
    FOREIGN KEY (`media`)
    REFERENCES `Photos`.`Media` (`media_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`TempAiTags`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`TempAiTags` (
  `ai_tag_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id` INT UNSIGNED NULL,
  `class_name` VARCHAR(50) NOT NULL,
  `b_box` JSON NULL,
  `confidence` DECIMAL(18,17) NOT NULL,
  `media_id` INT UNSIGNED NOT NULL,
  `ai_model` VARCHAR(10) NULL,
  `System` CHAR(36) NULL,
  PRIMARY KEY (`ai_tag_id`),
  INDEX `FK_SYSTEMLOG_SERVER_ID_idx` (`System` ASC) VISIBLE,
  CONSTRAINT `FK_SYSTEMLOG_SERVER_ID0`
    FOREIGN KEY (`System`)
    REFERENCES `Photos`.`ServerSystem` (`uuid`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Face`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Face` (
  `face_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ai_recognition` INT UNSIGNED NOT NULL,
  `confidence` DECIMAL(18,17) NOT NULL,
  `b_box` JSON NOT NULL,
  PRIMARY KEY (`face_id`),
  INDEX `PKFK_FACE_AiRECOG_ID_idx` (`ai_recognition` ASC) VISIBLE,
  CONSTRAINT `PKFK_FACE_AiRECOG_ID0`
    FOREIGN KEY (`ai_recognition`)
    REFERENCES `Photos`.`AiRecognition` (`ai_recognition_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `Photos`.`Passkeys`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Photos`.`Passkeys` (
  `cred_id` VARCHAR(50) NOT NULL COMMENT 'base64url string',
  `cred_public_key` BLOB NOT NULL,
  `RegisteredUser` VARCHAR(36) NOT NULL,
  `counter` BIGINT NOT NULL,
  `registered_device` ENUM('singleDevice', 'multiDevice') NOT NULL,
  `backup_eligible` TINYINT NOT NULL,
  `backup_status` TINYINT NOT NULL DEFAULT 0,
  `transports` TEXT NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `last_used` TIMESTAMP NULL,
  INDEX `UNIQUE_INTERNAL_WEBAUTHN` (`RegisteredUser` ASC) VISIBLE,
  PRIMARY KEY (`cred_id`, `RegisteredUser`),
  CONSTRAINT `FK_REG_USER_PASSKEYS_ID0`
    FOREIGN KEY (`RegisteredUser`)
    REFERENCES `Photos`.`RegisteredUser` (`reg_user_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
