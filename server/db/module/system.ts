import { sql } from '..';

export const checkInitialized = async (): Promise<boolean> => {
  try {
    const result = await sql`SELECT * FROM multi_schema."ServerSystem" LIMIT 1`;
    return result.length;
  } catch (error) {
    // console.log(error);
    return false;
  }
};

export const initializeSystem = async () => {
  try {
    const systemId = Bun.randomUUIDv7();
    const [result] = await sql`INSERT INTO multi_schema."ServerSystem" (system_id) VALUES (${systemId}) RETURNING system_id`;
    return result;
  } catch (error) {
    console.error('Error initializing the system:', error);
  }
};

export const updateProcessMediaStatus = async (status: boolean = true) => {
  try {
    return await sql`UPDATE multi_schema."ServerSystem" SET process_medias = ${status}`;
  } catch (error) {
    console.log('updateProcessMediaStatus', error);
  }
};

export const processMediaStatus = async () => {
  try {
    const [result] = await sql`SELECT process_medias FROM multi_schema."ServerSystem" LIMIT 1`;
    return result.process_medias;
  } catch (error) {
    console.log(error);
  }
};
