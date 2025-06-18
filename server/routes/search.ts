import { Hono } from 'hono';
import { sql } from '../db';
import { validateSchema } from '../modules/validateSchema';
import { z } from 'zod';
import { refreshView } from '../db/module/search';

const search = new Hono();

// const specialChars = /[^a-zA-Z0-9 ]/;
const querySchema = z.object({
  keywords: z
    .string()
    .trim()
    .max(50)
    .regex(/^[a-zA-Z0-9 -]*$/, 'Only letters, numbers, spaces, and hyphens are allowed')
    .optional(),
});

search.get('/refreshView', async (c) => {
  await refreshView();
  return c.json({ status: 'success' }, 200);
});

search.get('/', validateSchema('query', querySchema), async (c) => {
  const { keywords } = c.req.valid('query');

  if (!keywords) {
    const searchResults = sql`
      SELECT media_id, caption, favorite, thumb_path, COUNT(*) OVER() AS total_count
      FROM multi_schema."Media"
      WHERE hidden = FALSE AND deleted = FALSE
      LIMIT 9`;

    const result = { suggestCount: [], data: await searchResults };
    return c.json(result, 200);
  }

  const lastWord = keywords.split(' ').at(-1);
  const suggestCount = sql`
    SELECT sw.word, sw.ndoc FROM multi_schema.suggest_words AS sw
      WHERE similarity(sw.word, ${lastWord}::text) > 0.3
      ORDER BY similarity(sw.word, ${lastWord}::text) DESC
      LIMIT 5`;

  const searchResults = sql`
    SELECT media_id, caption, favorite, thumb_path, COUNT(*) OVER() AS total_count
      FROM multi_schema."Media"
      WHERE caption_eng_tsv @@ (websearch_to_tsquery ('english', ${keywords}::text) 
        || websearch_to_tsquery ('simple', ${keywords}::text))
        AND hidden = FALSE AND deleted = FALSE
      LIMIT 9`;

  const [wordCount, searchResult] = await Promise.all([suggestCount, searchResults]);
  const result = {
    suggestCount: wordCount,
    data: searchResult,
  };
  return c.json(result, 200);
});

export default search;
