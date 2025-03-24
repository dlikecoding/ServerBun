import type { FieldPacket, ResultSetHeader } from 'mysql2/promise';
import { poolPromise } from '..';
import type { AuthenticatorTransportFuture } from '@simplewebauthn/server';

const Sql = {
  INSERT_GUEST: `INSERT INTO UserGuest (user_name, user_email) VALUES (?, ?)`,
  INSERT_PASSKEY: `INSERT INTO Passkeys (cred_id, cred_public_key, UserGuest, counter, registered_device, backup_eligible, transports) VALUES (?, ?, ?, ?, ?, ?, ?)`,
  EXISTS: `SELECT user_id FROM UserGuest WHERE user_email = ?`,

  PASSKEYS: `SELECT * FROM Passkeys as pks WHERE pks.UserGuest = (SELECT user_id FROM UserGuest WHERE user_email = (?) LIMIT 1)`,

  USER_ACC_PASSKEY: `SELECT ug.user_email, ug.user_name, acc.role_type, acc.status, pks.cred_id, pks.cred_public_key, pks.counter, pks.transports FROM UserGuest ug 
                      JOIN Account acc ON acc.user_email = ug.user_email
                      JOIN Passkeys pks ON ug.user_id = pks.UserGuest
                      WHERE ug.user_email = (?)`,

  COUNT_WAITING: `SELECT COUNT(account_id) as waiting FROM Account WHERE status = "suspended"`,
  FETCH_ALL: `SELECT ug.user_id, ug.user_name, ug.user_email, ug.request_status, ug.request_at, acc.account_id, acc.role_type, acc.created_at, acc.status FROM UserGuest ug LEFT JOIN Account acc ON acc.user_email = ug.user_email WHERE acc.role_type IS NULL OR acc.role_type = 'user'`,

  // UPDATE_PASSKEY: `UPDATE Passkeys SET counter = ?, last_used = NOW() WHERE cred_id = ? AND UserGuest = ?`,
  // FIND_BY_EMAIL: `SELECT * FROM UserGuest as ug LEFT JOIN Passkeys as pks ON ug.user_id = pks.UserGuest WHERE user_email = (?)`,
  DELETE: `DELETE FROM UserGuest WHERE user_id = ?`,
};

const createUserGuest = async (user_name: string, user_email: string) => {
  try {
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INSERT_GUEST, [user_name, user_email]);
    return result[0].insertId;
  } catch (error) {
    console.log(error);
    return null;
  }
};

const createPasskey = async (
  cred_id: string,
  cred_public_key: Uint8Array,
  UserGuest: number,
  counter: number,
  registered_device: string,
  backup_eligible: boolean,
  transports: AuthenticatorTransportFuture[] | undefined
) => {
  try {
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INSERT_PASSKEY, [
      cred_id,
      cred_public_key,
      UserGuest,
      counter,
      registered_device,
      backup_eligible,
      transports,
    ]);
    return result[0].affectedRows > 0;
  } catch (error) {
    console.log(error);
    return null;
  }
};

const userGuestExists = async (user_email: string): Promise<boolean> => {
  const [rows] = await poolPromise.execute(Sql.EXISTS, [user_email]);
  return (rows as any).length > 0;
};

const userPassKeyByEmail = async (user_email: string) => {
  const [rows] = await poolPromise.execute(Sql.USER_ACC_PASSKEY, [user_email]);
  if ((rows as any).length === 0) return null;
  return (rows as any)[0];
};

const countWaiting = async () => {
  const [rows] = await poolPromise.execute(Sql.COUNT_WAITING);
  return (rows as any)[0];
};

const fetchAllUserGuests = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_ALL);
  return rows as any[];
};
// const userPKsByEmail = async (user_email: string) => {
//   const [rows] = await poolPromise.execute(Sql.PASSKEYS, [user_email]);
//   if ((rows as any).length === 0) return null;
//   return (rows as any)[0];
// };

// const updatePassKey = async (newCounter: number, cred_id: number, user_id: number) => {
//   const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.UPDATE_PASSKEY, [newCounter, cred_id, user_id]);
//   return result[0].affectedRows > 0;
// };

// const deleteUserGuest = async (user_id: number) => {
//   await poolPromise.execute(Sql.DELETE, [user_id]);
//   return { message: `UserGuest with ID ${user_id} deleted` };
// };

export {
  createUserGuest,
  userGuestExists,
  userPassKeyByEmail,
  createPasskey,
  countWaiting,
  // deleteUserGuest,
  fetchAllUserGuests,
};
