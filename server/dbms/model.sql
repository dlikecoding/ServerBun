CREATE SCHEMA IF NOT EXISTS multi_schema;

-- ENUM definitions
CREATE TYPE role_type_enum AS ENUM ('user', 'admin');
CREATE TYPE file_type_enum AS ENUM ('Photo', 'Video', 'Live', 'Unknown');
CREATE TYPE ai_model_enum AS ENUM ('classify', 'detect', 'segment');
CREATE TYPE aimode_enum AS ENUM ('Detect', 'Classify', 'Segment', 'Face');
CREATE TYPE registered_device_enum AS ENUM ('singleDevice', 'multiDevice');

BEGIN;


CREATE TABLE IF NOT EXISTS multi_schema."AiClass"
(
    class_id serial NOT NULL,
    class_name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    title_pretty character varying(100) DEFAULT GENERATED ALWAYS AS (INITCAP(REPLACE(class_name, '_', ' '))) STORED,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AiClass_pkey" PRIMARY KEY (class_id),
    CONSTRAINT "AiClass_class_name_key" UNIQUE (class_name)
);

CREATE TABLE IF NOT EXISTS multi_schema."AiRecognition"
(
    ai_recognition_id serial NOT NULL,
    media integer NOT NULL,
    ai_class integer NOT NULL,
    ai_mode aimode_enum NOT NULL,
    CONSTRAINT "AiRecognition_pkey" PRIMARY KEY (ai_recognition_id),
    CONSTRAINT "AiRecognition_media_ai_class_ai_mode_key" UNIQUE (media, ai_class, ai_mode)
);

CREATE TABLE IF NOT EXISTS multi_schema."Album"
(
    album_id smallserial NOT NULL,
    "RegisteredUser" uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    title character varying(50) COLLATE pg_catalog."default",
    modify_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Album_pkey" PRIMARY KEY (album_id),
    CONSTRAINT "Album_title_key" UNIQUE (title)
);

CREATE TABLE IF NOT EXISTS multi_schema."AlbumMedia"
(
    album smallint NOT NULL,
    media integer NOT NULL,
    CONSTRAINT "AlbumMedia_pkey" PRIMARY KEY (album, media)
);

CREATE TABLE IF NOT EXISTS multi_schema."CameraType"
(
    camera_id smallserial NOT NULL,
    make character varying(50) COLLATE pg_catalog."default",
    model character varying(100) COLLATE pg_catalog."default",
    lens_model character varying(200) COLLATE pg_catalog."default",
    CONSTRAINT "CameraType_pkey" PRIMARY KEY (camera_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."Classify"
(
    classify_id serial NOT NULL,
    ai_recognition integer NOT NULL,
    confidence numeric(18, 17),
    CONSTRAINT "Classify_pkey" PRIMARY KEY (classify_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."ErrorLog"
(
    error_log_id serial NOT NULL,
    file_error character varying(20) COLLATE pg_catalog."default" NOT NULL,
    stack_trace text COLLATE pg_catalog."default",
    func_occur character varying(25),
    server_system uuid,
    mark_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ErrorLog_pkey" PRIMARY KEY (error_log_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."Live"
(
    media integer NOT NULL,
    frame_count smallint,
    current_frame smallint,
    duration smallint,
    title character varying(45) COLLATE pg_catalog."default",
    CONSTRAINT "Live_pkey" PRIMARY KEY (media)
);

CREATE TABLE IF NOT EXISTS multi_schema."Location"
(
    media integer NOT NULL,
    city character varying(50) COLLATE pg_catalog."default",
    state character varying(50) COLLATE pg_catalog."default",
    country character varying(50) COLLATE pg_catalog."default",
    gps_latitude double precision,
    gps_longitude double precision,
    CONSTRAINT "Location_pkey" PRIMARY KEY (media)
);

CREATE TABLE IF NOT EXISTS multi_schema."Media"
(
    media_id serial NOT NULL,
    file_type file_type_enum NOT NULL,
    file_name text COLLATE pg_catalog."default",
    create_date timestamp without time zone,
    create_month smallint GENERATED ALWAYS AS (EXTRACT(month FROM create_date)) STORED,
    create_year smallint GENERATED ALWAYS AS (EXTRACT(year FROM create_date)) STORED,
    file_size bigint,
    hash_code character varying(65) COLLATE pg_catalog."default",
    hidden boolean DEFAULT false,
    favorite boolean DEFAULT false,
    deleted boolean DEFAULT false,
    deletion_date timestamp without time zone,
    upload_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    camera_type smallint,
    file_ext character varying(15),
    software character varying(256) COLLATE pg_catalog."default",
    source_file text COLLATE pg_catalog."default",
    mime_type character varying(15) COLLATE pg_catalog."default",
    thumb_path text COLLATE pg_catalog."default",
    thumb_width smallint,
    thumb_height smallint,
    video_duration character varying(15),
    CONSTRAINT "Media_pkey" PRIMARY KEY (media_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."Passkeys"
(
    cred_id character varying(50) COLLATE pg_catalog."default" NOT NULL,
    cred_public_key bytea NOT NULL,
    "RegisteredUser" uuid NOT NULL,
    counter smallint NOT NULL,
    registered_device registered_device_enum NOT NULL,
    backup_eligible boolean NOT NULL,
    backup_status boolean NOT NULL DEFAULT false,
    transports jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp without time zone,
    CONSTRAINT "Passkeys_pkey" PRIMARY KEY (cred_id, "RegisteredUser")
);

CREATE TABLE IF NOT EXISTS multi_schema."Photo"
(
    media integer NOT NULL,
    orientation character varying(45) COLLATE pg_catalog."default",
    image_width smallint,
    image_height smallint,
    megapixels double precision,
    CONSTRAINT "Photo_pkey" PRIMARY KEY (media)
);

CREATE TABLE IF NOT EXISTS multi_schema."RegisteredUser"
(
    reg_user_id uuid NOT NULL,
    user_email character varying(100) COLLATE pg_catalog."default" NOT NULL,
    user_name character varying(45) COLLATE pg_catalog."default" NOT NULL,
    role_type role_type_enum NOT NULL DEFAULT 'user'::role_type_enum,
    status boolean NOT NULL DEFAULT false,
    m2f_isenable boolean NOT NULL DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "ServerSystem" uuid NOT NULL,
    CONSTRAINT "RegisteredUser_pkey" PRIMARY KEY (reg_user_id),
    CONSTRAINT "RegisteredUser_user_email_key" UNIQUE (user_email)
);

CREATE TABLE IF NOT EXISTS multi_schema."ServerSystem"
(
    system_id uuid NOT NULL,
    process_medias boolean NOT NULL DEFAULT false,
    license_key character varying(512) COLLATE pg_catalog."default",
    CONSTRAINT "ServerSystem_pkey" PRIMARY KEY (system_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."UploadBy"
(
    "RegisteredUser" uuid NOT NULL,
    media integer NOT NULL,
    CONSTRAINT "UploadBy_pkey" PRIMARY KEY (media, "RegisteredUser")
);

CREATE TABLE IF NOT EXISTS multi_schema."UserLog"
(
    user_log_id serial NOT NULL,
    "RegisteredUser" uuid,
    user_device character varying(255) COLLATE pg_catalog."default",
    last_url_request character varying(200) COLLATE pg_catalog."default",
    last_logged_in timestamp without time zone,
    ip_address character varying(45) COLLATE pg_catalog."default" NOT NULL,
    logged_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UserLog_pkey" PRIMARY KEY (user_log_id)
);

CREATE TABLE IF NOT EXISTS multi_schema."Video"
(
    media integer NOT NULL,
    duration double precision,
    title character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT "Video_pkey" PRIMARY KEY (media)
);

CREATE TABLE IF NOT EXISTS multi_schema."Duplicate"
(
    media integer NOT NULL,
    hash_code character varying(65),
    PRIMARY KEY (media)
);

COMMENT ON TABLE multi_schema."Duplicate"
    IS 'Check for all of media had the same hash code';

ALTER TABLE IF EXISTS multi_schema."AiRecognition"
    ADD CONSTRAINT "AiRecognition_ai_class_fkey" FOREIGN KEY (ai_class)
    REFERENCES multi_schema."AiClass" (class_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."AiRecognition"
    ADD CONSTRAINT "AiRecognition_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."Album"
    ADD CONSTRAINT "Album_RegisteredUser_fkey" FOREIGN KEY ("RegisteredUser")
    REFERENCES multi_schema."RegisteredUser" (reg_user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."AlbumMedia"
    ADD CONSTRAINT "AlbumMedia_album_fkey" FOREIGN KEY (album)
    REFERENCES multi_schema."Album" (album_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."AlbumMedia"
    ADD CONSTRAINT "AlbumMedia_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."Classify"
    ADD CONSTRAINT "Classify_ai_recognition_fkey" FOREIGN KEY (ai_recognition)
    REFERENCES multi_schema."AiRecognition" (ai_recognition_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."ErrorLog"
    ADD CONSTRAINT "ErrorLog_server_system_fkey" FOREIGN KEY (server_system)
    REFERENCES multi_schema."ServerSystem" (system_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."Live"
    ADD CONSTRAINT "Live_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS "Live_pkey"
    ON multi_schema."Live"(media);


ALTER TABLE IF EXISTS multi_schema."Location"
    ADD CONSTRAINT "Location_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS "Location_pkey"
    ON multi_schema."Location"(media);


ALTER TABLE IF EXISTS multi_schema."Media"
    ADD CONSTRAINT "Media_camera_type_fkey" FOREIGN KEY (camera_type)
    REFERENCES multi_schema."CameraType" (camera_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."Passkeys"
    ADD CONSTRAINT "Passkeys_RegisteredUser_fkey" FOREIGN KEY ("RegisteredUser")
    REFERENCES multi_schema."RegisteredUser" (reg_user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."Photo"
    ADD CONSTRAINT "Photo_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS "Photo_pkey"
    ON multi_schema."Photo"(media);


ALTER TABLE IF EXISTS multi_schema."RegisteredUser"
    ADD CONSTRAINT "Server_RegisteredUser_fk" FOREIGN KEY ("ServerSystem")
    REFERENCES multi_schema."ServerSystem" (system_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS multi_schema."UploadBy"
    ADD CONSTRAINT "UploadBy_RegisteredUser_fkey" FOREIGN KEY ("RegisteredUser")
    REFERENCES multi_schema."RegisteredUser" (reg_user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."UploadBy"
    ADD CONSTRAINT "UploadBy_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS multi_schema."UserLog"
    ADD CONSTRAINT "UserLog_RegisteredUser_fkey" FOREIGN KEY ("RegisteredUser")
    REFERENCES multi_schema."RegisteredUser" (reg_user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS multi_schema."Video"
    ADD CONSTRAINT "Video_media_fkey" FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS "Video_pkey"
    ON multi_schema."Video"(media);


ALTER TABLE IF EXISTS multi_schema."Duplicate"
    ADD CONSTRAINT media_duplicate_fk FOREIGN KEY (media)
    REFERENCES multi_schema."Media" (media_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE
    NOT VALID;

END;