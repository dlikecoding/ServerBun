import { sql } from '../../db';
import { insertErrorLog } from '../../db/module/system';
import { workerQueue } from '../workers';
import { BATCH_SIZE_UPDATE_CAPTION, sendTask } from './_sendTaskHelper';

type ResponseLoc = {
  media_id: number;

  name: string;
  admin1: string;
  admin2: string;
  cc: string;
};

type Location = {
  city: string;
  state: string;
  county: string;
  country: string;
};

export const findLocation = async (medias: any[]): Promise<any> => {
  const pythonFilePath = 'models/ai_model/get_location.py';

  const totalFile = medias.length;
  if (!totalFile) return;

  let count = 0;

  const childProc = Bun.spawn(['python3', pythonFilePath], {
    stdout: 'pipe',
    stdin: 'pipe',
  });

  const responseLocs: ResponseLoc[] = [];

  try {
    console.log(childProc.pid);
    const reader = childProc.stdout.getReader();

    for (const media of medias) {
      const resData: ResponseLoc = await sendTask({ id: media.media_id, latitude: media.gps_latitude, longitude: media.gps_longitude }, childProc, reader);
      console.log(`Getting Location: ${++count}/${totalFile}`);

      if (responseLocs.length >= BATCH_SIZE_UPDATE_CAPTION) {
        await workerUpdateLocation(responseLocs);
        responseLocs.length = 0;
      }
      responseLocs.push(resData);
    }

    if (responseLocs.length >= 0) await workerUpdateLocation(responseLocs);
  } catch (error) {
    await insertErrorLog('service/generate/location.ts', 'findLocation', error);
    console.log(error);
  } finally {
    childProc.kill(); // Done — terminate the child process
  }
};

const insertLocation = async (location: ResponseLoc) => {
  let locId = await sql.begin(async (tx) => {
    const [getExistLoc] = await tx`
          SELECT location_id FROM multi_schema."Location" 
          WHERE city = ${location.name} AND state = ${location.admin1} AND country = ${location.cc}`;
    if (getExistLoc) return getExistLoc.location_id;

    const insertLocation: Location = { city: location.name, state: location.admin1, county: location.admin2, country: location.cc };
    const [idInserted] = await tx`
          INSERT INTO "multi_schema"."Location" ${sql(insertLocation)} 
          ON CONFLICT (city, state) DO NOTHING RETURNING location_id`;
    if (idInserted) return idInserted.location_id;
  });

  // In race condition, it may not get the id. So have to select again
  if (!locId) {
    const [getExistLoc] = await sql`
          SELECT location_id FROM multi_schema."Location" 
          WHERE city = ${location.name} AND state = ${location.admin1} AND country = ${location.cc}`;
    if (getExistLoc) locId = getExistLoc.location_id;
  }

  const insertData = { location: locId, media: location.media_id };
  await sql`INSERT INTO "multi_schema"."LocationMedia" ${sql(insertData)} ON CONFLICT DO NOTHING`;
};

const workerUpdateLocation = async (responseLocs: ResponseLoc[]) => {
  const tasks = responseLocs.map((resLoc: ResponseLoc) => () => insertLocation(resLoc));
  await workerQueue(tasks);
};
