
CREATE OR REPLACE 
VIEW "PhotoView" AS
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