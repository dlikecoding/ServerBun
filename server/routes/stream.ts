import { Hono } from 'hono';
import { pool } from '../db';

const streamApi = new Hono();

// https://hono.dev/docs/helpers/streaming
streamApi.get('/', async (c) => {
  const sql = 'SELECT * FROM Media ORDER BY media_id ASC LIMIT ?, ?';
  const values = [0, 99999];

  try {
    // pool.getConnection;
    const queryStream = pool.query(sql, values).stream();
    const stream = new ReadableStream({
      start(controller) {
        queryStream.on('data', (row: any) => {
          controller.enqueue(JSON.stringify(row).concat('\n'));
        });

        queryStream.on('end', () => {
          console.log('Query streaming completed.');
          controller.close();
        });

        queryStream.on('error', (err: any) => {
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
    // pool.releaseConnection;
  }
});

export default streamApi;
