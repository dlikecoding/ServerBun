import { Hono } from 'hono';
import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';
import { sql } from '../db';

const PAGE_SIZE = 250; // Max size per page

const streamApi = new Hono();

const querySchema = z.object({
  year: z.coerce.number().min(1800).max(9999).optional(),
  month: z.coerce.number().min(1).max(12).optional(),

  pageNumber: z.coerce.number().min(0).max(1000).default(0).optional(),

  filterDevice: z.coerce.number().min(1).max(1000).optional(),
  filterType: z.enum(['Video', 'Photo', 'Live']).optional(),

  sortKey: z.enum(['file_size', 'create_date', 'upload_at']).optional(),
  sortOrder: z.coerce.number().min(0).max(1).default(0).optional(),

  favorite: z.coerce.number().min(0).max(1).optional(),
  hidden: z.coerce.number().min(0).max(1).optional(),
  deleted: z.coerce.number().min(0).max(1).optional(),
  duplicate: z.coerce.number().min(0).max(1).optional(),

  albumId: z.coerce.number().min(1).max(2000).optional(),
});

streamApi.get('/', validateSchema('query', querySchema), async (c) => {
  try {
    const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder, favorite, hidden, deleted, duplicate, albumId } = c.req.valid('query');

    const isYear = year && month ? sql`AND create_year = ${year} AND create_month = ${month} ` : sql``;
    const isDevice = filterDevice ? sql`AND camera_type = ${filterDevice} ` : sql``;
    const isType = filterType ? sql`AND file_type = ${filterType} ` : sql``;
    const isFavorite = favorite ? sql`AND favorite = TRUE ` : sql``;
    const isHidden = hidden ? sql`AND hidden = TRUE ` : sql`AND hidden = FALSE `;
    const isDeleted = deleted ? sql`AND deleted = TRUE ` : sql`AND deleted = FALSE `;

    const sortOrders = sortOrder ? sql` ASC ` : sql` DESC `;
    const orderBy = sortKey ? sql`ORDER BY ${sql(sortKey)} ${sortOrders} ` : sql`ORDER BY create_date ${sortOrders} `;

    const limitOffset = sql`LIMIT ${PAGE_SIZE} OFFSET ${pageNumber * PAGE_SIZE}`;

    const getMedias = sql`
      SELECT media_id, thumb_path, source_file, create_month, create_year, 
              mime_type, file_type, favorite, file_size, upload_at, create_date
      FROM multi_schema."Media"
      WHERE 1=1 ${isYear} ${isDevice} ${isType}
      ${isFavorite} ${isHidden} ${isDeleted}`;

    let result;
    if (albumId) {
      result = await sql`
        SELECT md.* FROM (
            SELECT am.media FROM "multi_schema"."AlbumMedia" AS am WHERE am.album = ${albumId}
        ) as media_in_album
        JOIN (${getMedias}) as md ON md."media_id" = media_in_album.media
        ${orderBy}
        ${limitOffset}`;
    } else if (duplicate) {
      // TODO do something to find duplicate
    } else {
      result = await sql`${getMedias}
      ${orderBy}
      ${limitOffset}
    `;
    }

    return c.json(result); //{ data: fetchMedia, meta: { page: parsedPageNumber, pageSize: PAGE_SIZE } }
  } catch (err) {
    console.error('Unexpected error:', err);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
});

export default streamApi;

// // Define schema
// const querySchema = z.object({
//   year: z
//     .string()
//     .regex(/^(\d{4}|0)$/, 'Invalid year format') // Matches 0 or 4 digits
//     .optional(),
//   month: z
//     .string()
//     .regex(/^(0|[1-9]|1[0-2])$/, 'Invalid month format')
//     .optional(),
//   pageNumber: z.string().regex(/^\d+$/, 'Page number must be a number'),
//   filterDevice: z.string().regex(/^\d+$/, 'Device must be a number').optional(),
//   filterType: z.string().optional(),
//   sortKey: z.string().optional(),
//   sortOrder: z
//     .string()
//     .regex(/^(0|1)$/, 'Sort order must be either 0 or 1')
//     .optional(),
//   favorite: z
//     .string()
//     .regex(/^(0|1)$/, 'Boolean favorite must be either 0 or 1')
//     .optional(),
//   hidden: z
//     .string()
//     .regex(/^(0|1)$/, 'Boolean hidden value must be either 0 or 1')
//     .optional(),
//   deleted: z
//     .string()
//     .regex(/^(0|1)$/, 'Boolean delete value must be either 0 or 1')
//     .optional(),
//   duplicate: z
//     .string()
//     .regex(/^(0|1)$/, 'Boolean duplicate value must be either 0 or 1')
//     .optional(),

//   albumId: z
//     .string()
//     .regex(/^(?:[0-9]|[1-9][0-9]{1,2}|1000)$/, 'Invalid album format')
//     .optional(),
// });

// // Define type for query parameters
// export type StreamMediasParams = {
//   month?: number;
//   year?: number;

//   offset: number;
//   limit: number;

//   device?: number | null;
//   type?: string | null;

//   sortKey?: string | null;
//   sortOrder?: number | null;

//   favorite?: number | null;
//   hidden?: number | null;
//   deleted?: number | null;
//   duplicate?: number | null;

//   albumId?: number | null;
// };
