import { Hono } from 'hono';
import { fetchAllMedia } from '../db/module/media';

const streamApi = new Hono();

// https://hono.dev/docs/helpers/streaming
streamApi.get('/', async (c) => {
  const limit = 9999;
  const offset = 0;

  try {
    const queryStream = fetchAllMedia(offset, limit);
    const stream = new ReadableStream({
      start(controller) {
        queryStream.on('data', (row: any) => {
          controller.enqueue(JSON.stringify(row).concat('\n'));
        });

        queryStream.on('end', () => {
          // console.log('Query streaming completed.');
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
