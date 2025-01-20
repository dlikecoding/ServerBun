import { Hono } from 'hono';
import { streamMedias } from '../db/module/media';
import { pool } from '../db';

const PAGE_SIZE = 6; // up to 1000
const streamApi = new Hono();

interface Media {
  media_id: number;
  FileType: 'Video' | 'Audio' | 'Image'; // Adjust if there are other file types
  FileName: string;
  CreateDate: Date; // Use `Date` type for timestamps
  ThumbPath: string;
  SourceFile: string;
  isFavorite: number; // Could also be a boolean if needed
  timeFormat: string;
  duration: string;
  Title: string;
  affectedRows?: any;
}

streamApi.get('/', async (c) => {
  const { year, month, pageNumber } = c.req.query();
  // console.log(year, month, pageNumber);
  const verifyPageNumber = !pageNumber ? 0 : parseInt(pageNumber);

  const offset = verifyPageNumber * PAGE_SIZE;
  const limit = PAGE_SIZE;

  pool.getConnection;

  const yearInt = parseInt(year);
  const queryStream = isNaN(yearInt) ? streamMedias(0, 0, offset, limit) : streamMedias(parseInt(month), yearInt, offset, limit);

  try {
    const stream = new ReadableStream({
      start(controller) {
        queryStream!.on('data', (row: Media) => {
          if (row.affectedRows === 0) return; //ignore ResultSetHeader in mysql
          controller.enqueue(JSON.stringify(row).concat('\n'));
        });

        queryStream!.on('end', () => {
          controller.close();
        });

        queryStream!.on('error', (err: any) => {
          // Need to handle error to return status 500
          console.error('Stream error');
          controller.error(err);
        });
      },
    });

    return c.body(stream, { headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=3600, imutable' } });
  } catch (error) {
    console.error('Error streaming query results:', error);
  } finally {
    pool.releaseConnection;
  }
});

export default streamApi;
