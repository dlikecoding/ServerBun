-- Create index for caption_eng_tsv to speed up search
CREATE INDEX IF NOT EXISTS idx_media_caption ON multi_schema."Media" USING GIN (caption_eng_tsv);

CREATE MATERIALIZED VIEW IF NOT EXISTS multi_schema.suggest_words AS
SELECT word, ndoc FROM ts_stat(
  'SELECT caption_simple_tsv FROM multi_schema."Media"'
);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_suggestwords_word ON multi_schema.suggest_words USING GIN (word gin_trgm_ops);
