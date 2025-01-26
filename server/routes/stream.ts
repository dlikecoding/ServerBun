import { Hono } from 'hono';
import { streamMedias } from '../db/module/media';
import { pool } from '../db';

const streamApi = new Hono();

interface Media {
  media_id: number;
  FileType: 'Video' | 'Live' | 'Photo';
  FileName: string;
  FileSize: number;
  CreateDate: Date;
  ThumbPath: string;
  SourceFile: string;
  isFavorite: number;
  timeFormat: string;
  duration: string;
  Title: string;
  affectedRows?: any;
}

streamApi.get('/', async (c) => {
  const PAGE_SIZE = 250; // up to 1000
  console.log('SERVER CALLED');
  const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder } = c.req.query();

  const verifyPageNumber = !pageNumber ? 0 : parseInt(pageNumber);

  const offset = verifyPageNumber * PAGE_SIZE;
  const limit = PAGE_SIZE;

  const yearInt = parseInt(year);
  const filterDeviceInt = parseInt(filterDevice);
  const sortOrderInt = parseInt(sortOrder);

  const queryStream = isNaN(yearInt)
    ? streamMedias(0, 0, offset, limit)
    : streamMedias(parseInt(month), yearInt, offset, limit, isNaN(filterDeviceInt) ? undefined : filterDeviceInt, filterType, sortKey, isNaN(sortOrderInt) ? undefined : sortOrderInt);

  try {
    pool.getConnection;
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

    return c.body(stream, { headers: { 'Content-Type': 'application/json' } }); //, 'Cache-Control': 'public, max-age=3600, imutable'
  } catch (error) {
    console.error('Error streaming query results:', error);
  } finally {
    pool.releaseConnection;
  }
});

export default streamApi;
