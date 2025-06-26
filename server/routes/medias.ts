import { Hono } from 'hono';
import path from 'path';

import { z } from 'zod'; // To create a schema to validate post req

import { deleteAllInRecently, deleteMedias, fetchCameraType, getSourceFiles, groupMonthsByYear, updateMedias } from '../db/module/media';
import { validateSchema } from '../modules/validateSchema';
import { insertErrorLog } from '../db/module/system';

const medias = new Hono();

const updateSchema = z.object({
  mediaIds: z.array(z.coerce.number()),
  updateKey: z.enum(['favorite', 'deleted', 'hidden']), // If updateKey is not in Favorite, Deleted, Hidden ... return error
  updateValue: z.coerce.number().min(0).max(1),
});

const deleteSchema = z.object({
  mediaIds: z.array(z.coerce.number()),
});

medias.get('/', async (c) => {
  try {
    return c.json(await groupMonthsByYear(), 200);
  } catch (error) {
    console.error('medias.get: await groupMonthsByYear()', error);
    await insertErrorLog('routes/medias.ts', 'get/', error);
    return c.json({ error: 'Failed to fetch media of each month' }, 500);
  }
});

medias.get('/devices', async (c) => {
  try {
    return c.json(await fetchCameraType(), 200);
  } catch (error) {
    console.error('Error fetching devices:', error);
    await insertErrorLog('routes/medias.ts', 'devices', error);
    return c.json({ error: 'Failed to fetch media' }, 500);
  }
});

medias.put('/', validateSchema('json', updateSchema), async (c) => {
  try {
    const { mediaIds, updateKey, updateValue } = c.req.valid('json');
    const result = await updateMedias(mediaIds, updateKey, updateValue ? true : false);
    if (result) return c.json('Success', 202);
    return c.json({ error: 'Failed to update media' }, 403);
  } catch (error) {
    await insertErrorLog('routes/medias.ts', 'put/', error);
    return c.json({ error: 'Server error' }, 500);
  }
});

medias.delete('/', validateSchema('json', deleteSchema), async (c) => {
  const { mediaIds } = c.req.valid('json');

  try {
    const result = await deleteMedias(mediaIds);
    if (result) return c.json('Success', 202);
  } catch (error) {
    await insertErrorLog('routes/medias.ts', 'delete/', error);
    return c.json({ error: 'Failed to delete medias' }, 500);
  }
});

medias.get('/recently', async (c) => {
  try {
    const result = await deleteAllInRecently();
    if (result) return c.json('Success', 202);
  } catch (error) {
    await insertErrorLog('routes/medias.ts', 'delete/recently', error);
    return c.json({ error: 'Failed to delete all medias in Recently Delete' }, 500);
  }
});

// ////////////////////////////////////////////
// medias.get('/merge-all', async (c) => {
//   try {
//     const result = '';
//     return c.json('Success', 202);
//   } catch (error) {
//     await insertErrorLog('routes/medias.ts', 'get/merge-all', error);
//     return c.json({ error: 'Failed to merge all medias' }, 500);
//   }
// });

medias.post('/download', validateSchema('json', deleteSchema), async (c) => {
  try {
    const { mediaIds } = c.req.valid('json');
    if (!mediaIds || !mediaIds.length) {
      return new Response(JSON.stringify({ error: 'No mediaIds provided' }), { status: 400 });
    }

    const sourceFiles = await getSourceFiles(mediaIds);

    if (!sourceFiles || !sourceFiles.length) {
      return new Response(JSON.stringify({ error: 'No source files found for provided photos/video' }), { status: 404 });
    }

    const absPaths = sourceFiles.map((each: any) => path.join(Bun.env.MAIN_PATH, each.source_file));

    const zipProc = Bun.spawn({
      cmd: [
        'zip',
        '-j', // junk the path (flatten)
        '-q', // quiet output (faster with less logging)
        '-0', // store only (no compression) OR try `-1` for fast compression
        '-', // write to stdout
        ...absPaths,
      ],
      stdout: 'pipe',
      stderr: 'inherit',
    });

    // Check process exit code
    const exitCode = await zipProc.exited;
    if (exitCode !== 0) {
      await insertErrorLog('routes/medias.ts', 'post/download', 'Failed to create zip archive');
      return new Response(JSON.stringify({ error: 'Failed to create zip archive' }), {
        status: 500,
      });
    }

    return new Response(zipProc.stdout, {
      headers: {
        'Content-Type': 'application/zip',
        'Content-Disposition': 'attachment; filename="archive.zip"',
      },
    });
  } catch (err: any) {
    await insertErrorLog('routes/medias.ts', 'post/download', err);
    return new Response(JSON.stringify({ error: 'Internal server error', details: err.message }), {
      status: 500,
    });
  }
});

export default medias;
