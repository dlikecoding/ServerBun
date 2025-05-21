import { Hono } from 'hono';
import { z } from 'zod';
import { validateSchema } from '../modules/validateSchema';
import { sql } from '../db';
import { insertErrorLog } from '../db/module/system';

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

  searchKey: z
    .string()
    .min(1)
    .max(100)
    .regex(/^[a-zA-Z0-9 -]+$/, 'Only letters, numbers, spaces, underscores, and hyphens are allowed')
    .optional(),

  favorite: z.coerce.number().min(0).max(1).optional(),
  hidden: z.coerce.number().min(0).max(1).optional(),
  deleted: z.coerce.number().min(0).max(1).optional(),
  duplicate: z.coerce.number().min(0).max(1).optional(),

  albumId: z.coerce.number().min(1).max(2000).optional(),
});

streamApi.get('/', validateSchema('query', querySchema), async (c) => {
  try {
    const { year, month, pageNumber, filterDevice, filterType, sortKey, sortOrder, searchKey, favorite, hidden, deleted, duplicate, albumId } = c.req.valid('query');

    const isYear = year && month ? sql`AND create_year = ${year} AND create_month = ${month} ` : sql``;
    const isDevice = filterDevice ? sql`AND camera_type = ${filterDevice} ` : sql``;
    const isType = filterType ? sql`AND file_type = ${filterType} ` : sql``;
    const isFavorite = favorite ? sql`AND favorite = TRUE ` : sql``;
    const isHidden = hidden ? sql`AND hidden = TRUE ` : sql`AND hidden = FALSE `;
    const isDeleted = deleted ? sql`AND deleted = TRUE ` : sql`AND deleted = FALSE `;

    const sortOrders = sortOrder ? sql` ASC ` : sql` DESC `;
    const orderBy = sortKey ? sql`ORDER BY ${sql(sortKey)} ${sortOrders}, media_id ASC ` : sql`ORDER BY create_date ${sortOrders}, media_id ASC`;

    const limitOffset = sql`LIMIT ${PAGE_SIZE} OFFSET ${pageNumber * PAGE_SIZE}`;

    const getMedias = sql`
      SELECT media_id, thumb_path, source_file, create_month, create_year, video_duration, duration,
              mime_type, file_type, favorite, file_size, upload_at, create_date, selected_frame
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
      result = await sql`
        SELECT md.* FROM "multi_schema"."Duplicate" AS dup
        JOIN (${getMedias}) as md ON md."media_id" = dup.media
        ORDER BY hash_code, media_id ASC
        ${limitOffset}`;
    } else if (searchKey) {
      result = await sql`
        SELECT md.* FROM (
            SELECT media_id FROM multi_schema."Media"
            WHERE caption_eng_tsv @@ (
              websearch_to_tsquery ('english', ${searchKey}::text) || websearch_to_tsquery ('simple', ${searchKey}::text))
        ) as search_medias
        JOIN (${getMedias}) as md ON md."media_id" = search_medias.media_id
        ${orderBy}
        ${limitOffset}`;
    } else {
      result = await sql`${getMedias}
      ${orderBy}
      ${limitOffset}`;
    }

    return c.json(result); //{ data: fetchMedia, meta: { page: parsedPageNumber, pageSize: PAGE_SIZE } }
  } catch (error) {
    console.error('Unexpected loading medias:', error);
    await insertErrorLog('routes/stream.ts', 'streamApis', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
});

export default streamApi;
