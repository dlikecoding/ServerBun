-- ====================================================================================
-- Trigger function to automaticly delete album when media is deleted in Media table
CREATE OR REPLACE FUNCTION multi_schema.auto_delete_album_if_empty()
RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "multi_schema"."AlbumMedia"
        WHERE "album" = OLD."album"
    ) THEN 
        DELETE FROM "multi_schema"."Album"
        WHERE "album_id" = OLD."album";
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER delete_empty_album_after_delete_media
AFTER DELETE ON multi_schema."AlbumMedia"
FOR EACH ROW
EXECUTE FUNCTION "multi_schema".auto_delete_album_if_empty();

-- =========================== END ===================================================
-- Trigger auto remove not duplicate exist in duplicate table
-- Deletes the last remaining row with a given hash_code if only one is left after a delete
CREATE OR REPLACE FUNCTION multi_schema.auto_delete_media_in_duplicate()
RETURNS trigger AS $$
DECLARE
    count_duplicate INTEGER;
BEGIN

    SELECT COUNT(*) INTO count_duplicate
    FROM multi_schema."Duplicate" 
    WHERE hash_code = OLD.hash_code;

    IF count_duplicate = 1 THEN
        DELETE FROM multi_schema."Duplicate" WHERE hash_code = OLD.hash_code;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auto_delete_media_in_duplicate
AFTER DELETE ON multi_schema."Duplicate"
FOR EACH ROW
EXECUTE FUNCTION multi_schema.auto_delete_media_in_duplicate();

