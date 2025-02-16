import { Hono } from 'hono';
import { fetchMedias } from '../db/module/media';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';

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
  device?: number | null;
  type?: string | null;
  sortKey?: string | null;
  sortOrder?: number | null;
  deleted?: number | null;
  hidden?: number | null;
  favorite?: number | null;
  duplicate?: number | null;
};

// Define schema
const querySchema = z.object({
  year: z
    .string()
    .regex(/^(\d{4}|0)$/, 'Invalid year format') // Matches 0 or 4 digits
    .optional(),
  month: z
    .string()
    .regex(/^(0|[1-9]|1[0-2])$/, 'Invalid month format')
    .optional(),
  pageNumber: z.string().regex(/^\d+$/, 'Page number must be a number').optional(),
  filterDevice: z.string().regex(/^\d+$/, 'Device must be a number').optional(),
  filterType: z.string().optional(),
  sortKey: z.string().optional(),
  sortOrder: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
  favorite: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
  hidden: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
  deleted: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
  duplicate: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
});

streamApi.get(
  '/',
  zValidator('query', querySchema, (result, c) => {
    if (!result.success) {
      return c.json({ error: 'Invalid input' }, 400);
    }
  }),
  async (c) => {
    try {
      const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder, favorite, hidden, deleted, duplicate } = c.req.valid('query');

      // Convert parameters to appropriate types
      const parsedPageNumber = Math.max(0, parseInt(pageNumber || '0', 10));
      const offset = parsedPageNumber * PAGE_SIZE;
      const limit = PAGE_SIZE;

      const queryStreamParams: StreamMediasParams = {
        year: year ? parseInt(year, 10) : 0,
        month: month ? parseInt(month, 10) : 0,
        offset,
        limit,
        device: filterDevice ? parseInt(filterDevice, 10) : null,
        type: filterType || null,
        sortKey: sortKey || null,
        sortOrder: sortOrder ? parseInt(sortOrder, 10) : null,
        favorite: favorite ? parseInt(favorite, 10) : null,
        deleted: deleted ? parseInt(deleted, 10) : null,
        hidden: hidden ? parseInt(hidden, 10) : null,
      };

      // Fetch media using validated parameters
      const fetchMedia: Media[] = await fetchMedias(queryStreamParams);

      return c.json(fetchMedia); //{ data: fetchMedia, meta: { page: parsedPageNumber, pageSize: PAGE_SIZE } }
    } catch (err) {
      console.error('Unexpected error:', err);
      return c.json({ error: 'Internal Server Error' }, 500);
    }
  }
);

export default streamApi;
