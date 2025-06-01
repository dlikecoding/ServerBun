import { Hono } from 'hono';
import { validateSchema } from '../modules/validateSchema';
import { z } from 'zod';
import { insertErrorLog } from '../db/module/system';
import { sql } from '../db';
import { updateMediaCaption, updateSelectFrameLivePhoto } from '../db/module/media';

const media = new Hono();

const infoSchema = z.object({
  id: z.coerce.number().min(1),
});

media.get('/', validateSchema('query', infoSchema), async (c) => {
  try {
    const { id } = c.req.valid('query');

    const [media] = await sql`
    SELECT md.file_type, md.file_name, md.create_date, md.file_size, md.upload_at, md.file_ext, 
          md.software, md.mime_type, md.caption, md.image_width, md.image_height, md.megapixels, 
          md.lens_model, md.frame_rate, md.title, md.video_duration,
          ru.user_name, 
          cm.make, cm.model,
          lc.gps_latitude, lc.gps_longitude FROM "multi_schema"."Media" as md 
    LEFT JOIN multi_schema."UploadBy" as upl ON upl.media = md.media_id
    LEFT JOIN multi_schema."RegisteredUser" as ru ON ru.reg_user_id = upl."RegisteredUser"
    LEFT JOIN multi_schema."CameraType" as cm ON cm.camera_id = md.camera_type
    LEFT JOIN multi_schema."Location" as lc ON lc.media = md.media_id
    WHERE md.media_id = ${id}`;

    return c.json(media);
  } catch (error) {
    await insertErrorLog('routes/media.ts', 'get/', error);
    console.log('routes/media.ts', 'get/', error);
    return c.json({ error: 'Server error' }, 500);
  }
});

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

media.put('/caption', validateSchema('json', captionSchema), async (c) => {
  try {
    const { mediaId, caption } = c.req.valid('json');

    await updateMediaCaption({ media_id: mediaId, caption });

    return c.json('Success', 202);
  } catch (error) {
    await insertErrorLog('routes/media.ts', 'put/caption', error);
    return c.json({ error: 'Server error' }, 500);
  }
});

const frameSchema = z.object({
  mediaId: z.coerce.number().min(1),
  framePos: z.coerce.number().min(0).max(5),
});
media.put('/live-frame', validateSchema('json', frameSchema), async (c) => {
  try {
    const { mediaId, framePos } = c.req.valid('json');

    await updateSelectFrameLivePhoto(mediaId, framePos);

    return c.json('Success', 202);
  } catch (error) {
    await insertErrorLog('routes/media.ts', 'put/caption', error);
    return c.json({ error: 'Server error' }, 500);
  }
});
export default media;
