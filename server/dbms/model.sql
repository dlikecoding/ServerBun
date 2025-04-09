
-- ENUM definitions
CREATE TYPE role_type_enum AS ENUM ('user', 'admin');
CREATE TYPE file_type_enum AS ENUM ('Photo', 'Video', 'Live', 'Unknown');
CREATE TYPE ai_model_enum AS ENUM ('classify', 'detect', 'segment');
CREATE TYPE aimode_enum AS ENUM ('Detect', 'Classify', 'Segment', 'Face');
CREATE TYPE error_type_enum AS ENUM ('frontend', 'backend', 'database');
CREATE TYPE registered_device_enum AS ENUM ('singleDevice', 'multiDevice');

-- ServerSystem
DROP TABLE IF EXISTS "ServerSystem";
CREATE TABLE IF NOT EXISTS "ServerSystem" (
  system_id UUID PRIMARY KEY,
  process_medias BOOLEAN DEFAULT FALSE,
  license_key VARCHAR(512)
);


-- RegisteredUser
DROP TABLE IF EXISTS "RegisteredUser";
CREATE TABLE IF NOT EXISTS "RegisteredUser" (
  reg_user_id UUID PRIMARY KEY,
  user_email VARCHAR(100) UNIQUE NOT NULL,
  user_name VARCHAR(45) NOT NULL,
  role_type role_type_enum NOT NULL DEFAULT 'user',
  status BOOLEAN NOT NULL DEFAULT FALSE,
  m2f_isEnable BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Passkeys
DROP TABLE IF EXISTS "Passkeys";
CREATE TABLE IF NOT EXISTS "Passkeys" (
  cred_id VARCHAR(50) NOT NULL,
  cred_public_key BYTEA NOT NULL,
  "RegisteredUser" UUID NOT NULL REFERENCES "RegisteredUser"(reg_user_id) ON DELETE CASCADE,
  counter BIGINT NOT NULL,
  registered_device registered_device_enum NOT NULL,
  backup_eligible BOOLEAN NOT NULL,
  backup_status BOOLEAN NOT NULL DEFAULT FALSE,
  transports JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_used TIMESTAMP,
  PRIMARY KEY (cred_id, "RegisteredUser")
);

-- CameraType
DROP TABLE IF EXISTS "CameraType";
CREATE TABLE IF NOT EXISTS "CameraType" (
  camera_id SERIAL PRIMARY KEY,
  make VARCHAR(50),
  model VARCHAR(100),
  lens_model VARCHAR(200)
);

-- Media
DROP TABLE IF EXISTS "Media";
CREATE TABLE IF NOT EXISTS "Media" (
  media_id SERIAL PRIMARY KEY,
  file_type file_type_enum NOT NULL,
  file_name TEXT,
  create_date TIMESTAMP,
  file_size BIGINT,
  hash_code VARCHAR(65),
  hidden BOOLEAN DEFAULT FALSE,
  favorite BOOLEAN DEFAULT FALSE,
  deleted BOOLEAN DEFAULT FALSE,
  deletion_date TIMESTAMP,
  upload_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  camera_type INT REFERENCES "CameraType"(camera_id),
  file_ext VARCHAR(50),
  software VARCHAR(256),
  source_file TEXT,
  mime_type VARCHAR(50),
  thumb_path TEXT,
  thumb_width SMALLINT,
  thumb_height SMALLINT
);

-- AiClass
DROP TABLE IF EXISTS "AiClass";
CREATE TABLE IF NOT EXISTS "AiClass" (
  class_id SERIAL PRIMARY KEY,
  class_name VARCHAR(50) UNIQUE NOT NULL,
  created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AiRecognition
DROP TABLE IF EXISTS "AiRecognition";
CREATE TABLE IF NOT EXISTS "AiRecognition" (
  ai_recognition_id SERIAL PRIMARY KEY,
  media INT NOT NULL REFERENCES "Media"(media_id) ON DELETE CASCADE,
  ai_class INT NOT NULL REFERENCES "AiClass"(class_id),
  ai_mode aimode_enum NOT NULL,
  UNIQUE(media, ai_class, ai_mode)
);

-- Album
DROP TABLE IF EXISTS "Album";
CREATE TABLE IF NOT EXISTS "Album" (
  album_id SERIAL PRIMARY KEY,
  "RegisteredUser" UUID NOT NULL REFERENCES "RegisteredUser"(reg_user_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  title VARCHAR(50) UNIQUE,
  modify_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AlbumMedia
DROP TABLE IF EXISTS "AlbumMedia";
CREATE TABLE IF NOT EXISTS "AlbumMedia" (
  album INT NOT NULL REFERENCES "Album"(album_id) ON DELETE CASCADE,
  media INT NOT NULL REFERENCES "Media"(media_id) ON DELETE CASCADE,
  PRIMARY KEY(album, media)
);

-- Classify
DROP TABLE IF EXISTS "Classify";
CREATE TABLE IF NOT EXISTS "Classify" (
  classify_id SERIAL PRIMARY KEY,
  ai_recognition INT NOT NULL REFERENCES "AiRecognition"(ai_recognition_id) ON DELETE CASCADE,
  confidence NUMERIC(18, 17) NOT NULL
);

-- ErrorLog
DROP TABLE IF EXISTS "ErrorLog";
CREATE TABLE IF NOT EXISTS "ErrorLog" (
  error_log_id SERIAL PRIMARY KEY,
  error_msg TEXT NOT NULL,
  stack_trace TEXT,
  error_type error_type_enum,
  server_system UUID REFERENCES "ServerSystem"(system_id),
  logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Live
DROP TABLE IF EXISTS "Live";
CREATE TABLE IF NOT EXISTS "Live" (
  media INT PRIMARY KEY REFERENCES "Media"(media_id) ON DELETE CASCADE,
  frame_count INT,
  current_frame SMALLINT,
  duration INT,
  title VARCHAR(45)
);

-- Location
DROP TABLE IF EXISTS "Location";
CREATE TABLE IF NOT EXISTS "Location" (
  media INT PRIMARY KEY REFERENCES "Media"(media_id) ON DELETE CASCADE,
  city VARCHAR(50),
  state VARCHAR(50),
  country VARCHAR(50),
  gps_latitude DOUBLE PRECISION,
  gps_longitude DOUBLE PRECISION
);

-- Photo
DROP TABLE IF EXISTS "Photo";
CREATE TABLE IF NOT EXISTS "Photo" (
  media INT PRIMARY KEY REFERENCES "Media"(media_id) ON DELETE CASCADE,
  orientation VARCHAR(45),
  image_width SMALLINT,
  image_height SMALLINT,
  megapixels DOUBLE PRECISION
);

-- UploadBy
DROP TABLE IF EXISTS "UploadBy";
CREATE TABLE IF NOT EXISTS "UploadBy" (
  "RegisteredUser" UUID NOT NULL REFERENCES "RegisteredUser"(reg_user_id),
  media INT NOT NULL REFERENCES "Media"(media_id) ON DELETE CASCADE,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(media, "RegisteredUser")
);

-- UserLog
DROP TABLE IF EXISTS "UserLog";
CREATE TABLE IF NOT EXISTS "UserLog" (
  user_log_id SERIAL PRIMARY KEY,
  "RegisteredUser" UUID REFERENCES "RegisteredUser"(reg_user_id),
  user_device VARCHAR(255),
  last_url_request VARCHAR(200),
  last_logged_in TIMESTAMP,
  ip_address VARCHAR(45) NOT NULL,
  logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Video
DROP TABLE IF EXISTS "Video";
CREATE TABLE IF NOT EXISTS "Video" (
  media INT PRIMARY KEY REFERENCES "Media"(media_id) ON DELETE CASCADE,
  duration DOUBLE PRECISION,
  title VARCHAR(255),
  display_duration VARCHAR(45)
);






-- -- TempAiTags
-- CREATE TABLE IF NOT EXISTS "TempAiTags" (
--   ai_tag_id SERIAL PRIMARY KEY,
--   class_id INT,
--   class_name VARCHAR(50) NOT NULL,
--   b_box JSON,
--   confidence NUMERIC(18, 17) NOT NULL,
--   media_id INT NOT NULL REFERENCES "Media"(media_id),
--   ai_model VARCHAR(10),
--   "System" UUID REFERENCES "ServerSystem"(uuid)
-- );



-- -- Detect
-- CREATE TABLE IF NOT EXISTS "Detect" (
--   detection_id SERIAL PRIMARY KEY,
--   ai_recognition INT NOT NULL REFERENCES "AiRecognition"(ai_recognition_id) ON DELETE CASCADE,
--   confidence NUMERIC(18, 17) NOT NULL,
--   b_box JSON NOT NULL
-- );

-- -- Segment
-- CREATE TABLE IF NOT EXISTS "Segment" (
--   segment_id SERIAL PRIMARY KEY,
--   ai_recognition INT NOT NULL REFERENCES "AiRecognition"(ai_recognition_id) ON DELETE CASCADE,
--   confidence NUMERIC(18, 17) NOT NULL,
--   b_box JSON NOT NULL
-- );



-- -- AIModel
-- CREATE TABLE IF NOT EXISTS "AIModel" (
--   ai_model_id SERIAL PRIMARY KEY,
--   source_path TEXT NOT NULL,
--   model ai_model_enum NOT NULL,
--   cmd TEXT NOT NULL,
--   description VARCHAR(100),
--   server_system UUID NOT NULL REFERENCES "ServerSystem"(system_id)
-- );