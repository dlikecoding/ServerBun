import { Hono } from 'hono';
import { fetchMedias } from '../db/module/media';
import { z } from 'zod';
import { validateSchema } from '../modules/validate';

const PAGE_SIZE = 50; // Max size per page

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
  videoTitle: string;

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

  favorite?: number | null;
  hidden?: number | null;
  deleted?: number | null;
  duplicate?: number | null;

  albumId?: number | null;
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
  pageNumber: z.string().regex(/^\d+$/, 'Page number must be a number'),
  filterDevice: z.string().regex(/^\d+$/, 'Device must be a number').optional(),
  filterType: z.string().optional(),
  sortKey: z.string().optional(),
  sortOrder: z
    .string()
    .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
    .optional(),
  favorite: z
    .string()
    .regex(/^(0|1)$/, 'Boolean favorite must be either 0 or 1')
    .optional(),
  hidden: z
    .string()
    .regex(/^(0|1)$/, 'Boolean hidden value must be either 0 or 1')
    .optional(),
  deleted: z
    .string()
    .regex(/^(0|1)$/, 'Boolean delete value must be either 0 or 1')
    .optional(),
  duplicate: z
    .string()
    .regex(/^(0|1)$/, 'Boolean duplicate value must be either 0 or 1')
    .optional(),

  albumId: z
    .string()
    .regex(/^(?:[0-9]|[1-9][0-9]{1,2}|1000)$/, 'Invalid album format')
    .optional(),
});

streamApi.get('/', validateSchema('query', querySchema), async (c) => {
  try {
    const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder, favorite, hidden, deleted, duplicate, albumId } = c.req.valid('query');
    // console.log(year, month, 'pageNumber', pageNumber, filterDevice, filterType, sortKey, sortOrder, favorite, hidden, deleted, duplicate, albumId);
    // Convert parameters to appropriate types
    const parsedPageNumber = parseInt(pageNumber!);

    const offset = parsedPageNumber * PAGE_SIZE;
    const limit = PAGE_SIZE;

    const queryStreamParams: StreamMediasParams = {
      year: year ? parseInt(year) : 0,
      month: month ? parseInt(month) : 0,
      offset: offset,
      limit: limit,
      device: filterDevice ? parseInt(filterDevice) : null,
      type: filterType || null,
      sortKey: sortKey || null,
      sortOrder: sortOrder ? parseInt(sortOrder) : null,

      favorite: favorite ? parseInt(favorite) : null,
      hidden: hidden ? parseInt(hidden) : null,
      deleted: deleted ? parseInt(deleted) : null,
      duplicate: duplicate ? parseInt(duplicate) : null,

      albumId: albumId ? parseInt(albumId) : null,
    };

    // Fetch media using validated parameters
    const fetchMedia: Media[] = await fetchMedias(queryStreamParams);

    return c.json(fetchMedia); //{ data: fetchMedia, meta: { page: parsedPageNumber, pageSize: PAGE_SIZE } }
  } catch (err) {
    console.error('Unexpected error:', err);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
});

export default streamApi;
