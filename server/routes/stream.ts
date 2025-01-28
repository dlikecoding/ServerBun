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

  pool.getConnection(async (err, connection) => {
    if (err) {
      console.error('Error getting connection:', err);
      // Return a proper error response
      return c.status(500);
    }
    const { year, month, offset, limit, device = undefined, type = undefined, sortKey = undefined, sortOrder = undefined } = queryStreamParams;
    try {
      // Start streaming the query results
      const queryStream = connection.query(`CALL StreamSearchMedias(?, ?, ?, ?, ?, ?, ?, ?)`, [month, year, offset, limit, device, type, sortKey, sortOrder]).stream();

      // Create a readable stream
      const stream = new ReadableStream({
        start(controller) {
          queryStream.on('data', (row: Media) => {
            if (row.affectedRows === 0) return; // Ignore ResultSetHeader in MySQL
            controller.enqueue(JSON.stringify(row).concat('\n'));
          });

          queryStream.on('end', () => {
            controller.close();
            connection.release();
          });

          queryStream.on('error', (err: any) => {
            console.error('Stream error:', err);
            controller.error(err);
          });

          queryStream.on('close', () => {
            console.log('Stream closed');
          });
        },
      });

      // Return the stream as the response
      return c.body(stream, {
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600, immutable',
        },
      });
    } catch (error) {
      console.error('Unhandled error:', error);
      // Ensure connection is released even in case of error
      connection.release();
      return c.status(500);
    }
  });
});

export default streamApi;
