import { Hono } from 'hono';
import { sql } from '../db';
import { validateSchema } from '../modules/validateSchema';
import { z } from 'zod';

const search = new Hono();

const spceialChars = /[^a-zA-Z0-9\s]/;
const querySchema = z.object({
  keyword: z
    .string()
    // .trim().min(0).max(20).optional(),
    .refine((input) => !spceialChars.test(input)),
});

search.get('/', validateSchema('query', querySchema), async (c) => {
  const { keyword } = c.req.valid('query');
  console.log('keyword', keyword);
  if (!keyword) {
    const searchCounts = sql`SELECT COUNT(media_id) FROM multi_schema."Media"`;

    const searchResults = sql`
    SELECT media_id, thumb_path, source_file, video_duration, file_type, favorite
    FROM multi_schema."Media" LIMIT 9`;
    const result = {
      count: await searchCounts,
      data: await searchResults,
    };
    return c.json(result, 200);
  }

  // This need to be fixed and improve
  const searchTerm = `%${keyword}%`;

  const searchCounts = sql`
  SELECT COUNT(media), album_id, title
    FROM multi_schema."Album" AS al
    JOIN multi_schema."AlbumMedia" AS am ON am.album = al.album_id
    WHERE title::text ILIKE ${searchTerm}
    GROUP BY album_id LIMIT 4`;

  const searchResults = sql`
  SELECT media_id, thumb_path, source_file, video_duration, file_type, favorite
    FROM multi_schema."Album" AS al
    JOIN multi_schema."AlbumMedia" AS am ON am.album = al.album_id
    JOIN multi_schema."Media" AS md ON md.media_id = am.media
    WHERE title::text ILIKE ${searchTerm}
    LIMIT 9`;

  const result = {
    count: await searchCounts,
    data: await searchResults,
  };

  return c.json(result, 200);
});

// search.post('/', async (c) => {
//   return c.json('YOU ARE SEARCHING', 200);
// });

export default search;

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
