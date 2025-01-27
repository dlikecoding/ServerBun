import { Hono } from 'hono';
import { streamMedias } from '../db/module/media';
import { pool } from '../db';

const PAGE_SIZE = 250; // Max size per page

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

// Define type for query parameters
export type StreamMediasParams = {
  month: number;
  year: number;
  offset: number;
  limit: number;
  device?: number;
  type?: string;
  sortKey?: string;
  sortOrder?: number;
};

streamApi.get('/', async (c) => {
  const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder } = c.req.query();

  // Validate and convert parameters
  const parsedPageNumber = Math.max(0, parseInt(pageNumber, 10));
  const offset = parsedPageNumber * PAGE_SIZE;
  const limit = PAGE_SIZE;

  const yearInt = parseInt(year || '0', 10);
  const monthInt = parseInt(month || '0', 10);
  const deviceInt = filterDevice ? parseInt(filterDevice, 10) : undefined;
  const sortOrderInt = sortOrder ? parseInt(sortOrder, 10) : undefined;

  // if (isNaN(monthInt) || monthInt < 1 || monthInt > 12) {
  //   throw new Error("Invalid 'month' parameter. It must be between 1 and 12.");
  // }

  // Prepare query parameters
  const queryStreamParams: StreamMediasParams = isNaN(yearInt)
    ? { month: monthInt, year: yearInt, offset, limit }
    : { month: monthInt, year: yearInt, offset, limit, device: deviceInt, type: filterType, sortKey: sortKey, sortOrder: sortOrderInt };

  // Call the function with structured parameters
  const queryStream = streamMedias(queryStreamParams);

  try {
    // pool.getConnection;
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
    // } finally {
    //   pool.releaseConnection;
  }
});

export default streamApi;
