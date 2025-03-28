import type { FieldPacket, ResultSetHeader } from 'mysql2/promise';
import { poolPromise } from '..';

const Sql = {
  LOADED_SERVER: 'SELECT * FROM ServerSystem LIMIT 1',
  INITIALIZED: 'INSERT INTO ServerSystem (uuid) VALUES (?)',

  UPDATE_PROCESS_MEDIA: 'UPDATE ServerSystem SET process_medias = (?) LIMIT 1',
  PROCESS_MEDIA_STATUS: 'SELECT process_medias FROM ServerSystem LIMIT 1',
};

export const checkInitalized = async (): Promise<boolean> => {
  try {
    await poolPromise.execute(Sql.LOADED_SERVER);
    return true;
  } catch (error) {
    // console.error('Error checking the system:', error);
    return false;
  }
};

export const initalizeSys = async () => {
  try {
    const systemId = Bun.randomUUIDv7();
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INITIALIZED, [systemId]);
    return result[0].affectedRows > 0;
  } catch (error) {
    console.error('Error initializing the system:', error);
  }
};

export const updateProcessMediaStatus = async (status: number = 1) => {
  try {
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.UPDATE_PROCESS_MEDIA, [status]);
    return result[0].affectedRows > 0;
  } catch (error) {
    console.log(error);
  }
};

export const processMediaStatus = async () => {
  try {
    const [rows] = await poolPromise.execute(Sql.PROCESS_MEDIA_STATUS);
    return (rows as any)[0].process_medias;
  } catch (error) {
    console.log(error);
  }
};
