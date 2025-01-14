import { Hono } from 'hono';
import { streamMedias } from '../db/module/media';
import { pool } from '../db';

const PAGE_SIZE = 9999; // up to 1000
const streamApi = new Hono();

streamApi.get('/', async (c) => {
  const { year, month, pageNumber } = c.req.query();
  const verifyPageNumber = !pageNumber ? 0 : parseInt(pageNumber);

  const offset = verifyPageNumber * PAGE_SIZE;
  const limit = PAGE_SIZE;

  pool.getConnection;

  const yearInt = parseInt(year);
  const queryStream = isNaN(yearInt) ? streamMedias(0, 0, offset, limit) : streamMedias(parseInt(month), yearInt, offset, limit);

  try {
    const stream = new ReadableStream({
      start(controller) {
        queryStream!.on('data', (row: any) => {
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

    return c.body(stream, { headers: { 'Content-Type': 'application/json' } });
  } catch (error) {
    console.error('Error streaming query results:', error);
  } finally {
    pool.releaseConnection;
  }
});

export default streamApi;
