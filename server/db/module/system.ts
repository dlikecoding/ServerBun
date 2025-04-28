import { sql } from '..';

export const checkInitialized = async (): Promise<boolean> => {
  try {
    const result = await sql`
      SELECT * FROM multi_schema."ServerSystem" LIMIT 1`;
    return result.length;
  } catch (error) {
    return false;
  }
};

export const initializeSystem = async () => {
  try {
    const system = { system_id: Bun.randomUUIDv7() };
    const [result] = await sql`
      INSERT INTO multi_schema."ServerSystem" ${sql(system)} RETURNING system_id`;
    return result;
  } catch (error) {
    console.error('Error initializing the system:', error);
    await insertErrorLog('system.ts', 'initializeSystem', error);
  }
};

export const updateProcessMediaStatus = async (status: boolean = true) => {
  try {
    return await sql`
      UPDATE multi_schema."ServerSystem" SET process_medias = ${status}`;
  } catch (error) {
    await insertErrorLog('system.ts', 'updateProcessMediaStatus', error);
    console.log('updateProcessMediaStatus', error);
  }
};

export const processMediaStatus = async () => {
  try {
    const [result] = await sql`
      SELECT process_medias FROM multi_schema."ServerSystem" LIMIT 1`;
    return result.process_medias;
  } catch (error) {
    console.log('processMediaStatus', error);
    await insertErrorLog('system.ts', 'processMediaStatus', error);
  }
};

export const insertErrorLog = async (fileName: string, funcName: string, errMegs: any) => {
  try {
    const error = { file_error: fileName, func_occur: funcName, stack_trace: errMegs };
    await sql`
      INSERT INTO multi_schema."ErrorLog" ${sql(error)}`;
  } catch (error) {
    console.log(error);
  }
};
