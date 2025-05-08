import { Hono } from 'hono';
import { sql } from '../db';
import { validateSchema } from '../modules/validateSchema';
import { z } from 'zod';
import { refreshView } from '../db/module/search';

const search = new Hono();

const specialChars = /[^a-zA-Z0-9 ]/;
const querySchema = z.object({
  keywords: z
    .string()
    .trim()
    .max(25)
    .refine((input) => !specialChars.test(input), {
      message: 'Keywords contain invalid characters',
    })
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
      SELECT media_id, thumb_path, source_file, video_duration, file_type, favorite, COUNT(*) OVER() AS total_count
      FROM multi_schema."Media" LIMIT 9`;

    const result = { suggestCount: [], data: await searchResults };
    return c.json(result, 200);
  }

  const lastWord = keywords.split(' ').at(-1);
  const suggestCount = sql`
    SELECT sw.word, sw.ndoc FROM multi_schema.suggest_words AS sw
      WHERE multi_schema.similarity(sw.word, ${lastWord}::text) > 0.3
      ORDER BY multi_schema.similarity(sw.word, ${lastWord}::text) DESC
      LIMIT 5`;

  const searchResults = sql`
    SELECT media_id, caption, thumb_path, source_file, video_duration, file_type, favorite, COUNT(*) OVER() AS total_count
      FROM multi_schema."Media"
      WHERE caption_eng_tsv @@ (
        websearch_to_tsquery (${keywords}::text) 
        || websearch_to_tsquery ('simple', ${keywords}::text))
      LIMIT 9`;

  const [wordCount, searchResult] = await Promise.all([suggestCount, searchResults]);
  const result = {
    suggestCount: wordCount,
    data: searchResult,
  };
  return c.json(result, 200);
});

export default search;

// search.post('/', async (c) => {
//   return c.json('YOU ARE SEARCHING', 200);
// });

// // This function will continuously read from the stream
// async function readStream(reader: ReadableStreamDefaultReader<Uint8Array<ArrayBufferLike>>) {
//   let result;
//   while (!(result = await reader.read()).done) {
//     const text = new TextDecoder().decode(result.value);
//     console.log(JSON.parse(text)); // Process the output as it comes in
//   }
// }

// async function runCommand(python3: string, ai_generate: string, arrayAsString: string, yolo: string) {
//   const command = [python3, ai_generate, arrayAsString, yolo, '0.5', 'Classify'];

//   const process = Bun.spawn(command); // Spawn the process asynchronously

//   return process.stdout.getReader(); // Get the reader for the stream
// }
