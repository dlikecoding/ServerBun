import { Hono } from 'hono';
import { validateSchema } from '../modules/validateSchema';
import { z } from 'zod';
import { insertErrorLog } from '../db/module/system';
import { sql } from '../db';
import { updateMediaCaption } from '../db/module/media';

const media = new Hono();

const specialChars = /[^a-zA-Z0-9.,!?;:"'$()%\- ]/;
const captionSchema = z.object({
  mediaId: z.coerce.number().min(1),
  caption: z.coerce
    .string()
    .trim()
    .refine((input) => !specialChars.test(input), {
      message: 'Caption must not contain invalid characters <>{}[]',
    }),
});

const infoSchema = z.object({
  id: z.coerce.number().min(1),
  filterType: z.enum(['Video', 'Photo', 'Live']),
});

media.get('/', validateSchema('query', infoSchema), async (c) => {
  try {
    const { id, filterType } = c.req.valid('query');

    const queryByType = {
      Photo: sql`
      SELECT * FROM multi_schema."Photo" WHERE media = ${id}`,
      Video: sql`
      SELECT * FROM multi_schema."Video" WHERE media = ${id}`,
      Live: sql`
      SELECT * FROM multi_schema."Live" WHERE media = ${id}`,
    };

    const selectType = queryByType[filterType as keyof typeof queryByType];
    const [media] = await sql`
    SELECT filter_type.*,
      md.file_type, md.file_name, md.create_date, md.file_size, md.upload_at, md.file_ext, 
      md.software, md.mime_type, md.caption, md.image_width, md.image_height, md.megapixels,
      ru.user_name, 
      cm.make, cm.model, cm.lens_model,
      lc.gps_latitude, lc.gps_longitude FROM (
        ${selectType}
        ) as filter_type
    JOIN "multi_schema"."Media" as md ON filter_type.media = md.media_id
    JOIN multi_schema."UploadBy" as upl ON upl.media = md.media_id
    JOIN multi_schema."RegisteredUser" as ru ON ru.reg_user_id = upl."RegisteredUser"
    LEFT JOIN multi_schema."CameraType" as cm ON cm.camera_id = md.camera_type
    LEFT JOIN multi_schema."Location" as lc ON lc.media = md.media_id;`;

    return c.json(media);
  } catch (error) {
    await insertErrorLog('routes/media.ts', 'get/', error);
    console.log('routes/media.ts', 'get/', error);
    return c.json({ error: 'Server error' }, 500);
  }
});

media.put('/caption', validateSchema('json', captionSchema), async (c) => {
  try {
    const { mediaId, caption } = c.req.valid('json');

    await updateMediaCaption(mediaId, caption);

    return c.json('Success', 202);
  } catch (error) {
    await insertErrorLog('routes/media.ts', 'put/caption', error);
    return c.json({ error: 'Server error' }, 500);
  }
});

export default media;
