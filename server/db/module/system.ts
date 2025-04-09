import { sql } from '..';

export const checkInitialized = async (): Promise<boolean> => {
  try {
    const result = await sql`SELECT * FROM "ServerSystem" LIMIT 1`;
    return result.length;
  } catch (error) {
    // console.log(error);
    return false;
  }
};

export const initializeSystem = async () => {
  try {
    const systemId = Bun.randomUUIDv7();
    const [result] = await sql`INSERT INTO "ServerSystem" (system_id) VALUES (${systemId}) RETURNING system_id`;
    return result;
  } catch (error) {
    console.error('Error initializing the system:', error);
  }
};

export const updateProcessMediaStatus = async (status: number = 1) => {
  try {
    return await sql`UPDATE "ServerSystem" SET process_medias = ${status} LIMIT 1`;
  } catch (error) {
    console.log(error);
  }
};

export const processMediaStatus = async () => {
  try {
    const [result] = await sql`SELECT process_medias FROM "ServerSystem" LIMIT 1`;
    return result.process_medias;
  } catch (error) {
    console.log(error);
  }
};
