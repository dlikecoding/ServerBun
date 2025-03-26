import type { FieldPacket, ResultSetHeader } from 'mysql2/promise';
import { poolPromise } from '..';
import type { AuthenticatorTransportFuture } from '@simplewebauthn/server';
import type { UserType } from '../../routes/authHelper/_cookies';

const Sql = {
  COUNT_WAITING: `SELECT COUNT(reg_user_id) as waiting FROM RegisteredUser WHERE status = 0`,
  FIND_BY_EMAIL: `SELECT reg_user_id, user_email, status, role_type FROM RegisteredUser WHERE user_email = ?`,
  INSERT_USER: `INSERT INTO RegisteredUser (reg_user_id, user_name, user_email, role_type, status) VALUES (?, ?, ?, ?, ?)`,
  INSERT_PASSKEY: `INSERT INTO Passkeys (cred_id, cred_public_key, RegisteredUser, counter, registered_device, backup_eligible, transports) VALUES (?, ?, ?, ?, ?, ?, ?)`,

  PASSKEY: `SELECT * FROM Passkeys as pks WHERE pks.RegisteredUser = (SELECT reg_user_id FROM RegisteredUser WHERE user_email = (?) LIMIT 1)`,

  USER_ACC_PASSKEY: `SELECT reg.reg_user_id, reg.user_email, reg.user_name, reg.role_type, reg.status, pks.cred_id, pks.cred_public_key, pks.counter, pks.transports FROM RegisteredUser reg 
                      JOIN Passkeys pks ON reg.reg_user_id = pks.RegisteredUser
                      WHERE reg.user_email = (?)`,

  UPDATE_STATUS: `UPDATE RegisteredUser SET status = !status WHERE user_email = ?`,

  FETCH_ALL: `SELECT reg_user_id, user_name, user_email, role_type, created_at, status FROM RegisteredUser reg WHERE role_type IS NULL OR role_type = 'user'`,

  // UPDATE_PASSKEY: `UPDATE Passkeys SET counter = ?, last_used = NOW() WHERE cred_id = ? AND RegisteredUser = ?`,
  // FIND_BY_EMAIL: `SELECT * FROM RegisteredUser as ug LEFT JOIN Passkeys as pks ON reg.reg_user_id = pks.RegisteredUser WHERE user_email = (?)`,
  // DELETE: `DELETE FROM RegisteredUser WHERE reg_user_id = ?`,
};

const createAdminOrUsers = async (user_name: string, user_email: string) => {
  const [rows] = await poolPromise.execute(`SELECT reg_user_id FROM RegisteredUser LIMIT 1`);
  if ((rows as any).length > 0) return await createAccount(user_name, user_email);

  return await createAccount(user_name, user_email, 'admin', 1);
};

const createAccount = async (user_name: string, user_email: string, role_type: string = 'user', status: number = 0) => {
  const connection = await poolPromise.getConnection();
  const userId = Bun.randomUUIDv7();

  try {
    await connection.beginTransaction();
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INSERT_USER, [userId, user_name, user_email, role_type, status]);
    await connection.commit();

    return result[0].affectedRows > 0 ? userId : '';
  } catch (error) {
    if (connection) await connection.rollback();
  } finally {
    if (connection) connection.release();
  }
};

const createPasskey = async (
  cred_id: string,
  cred_public_key: Uint8Array,
  RegisteredUser: string,
  counter: number,
  registered_device: string,
  backup_eligible: boolean,
  transports: AuthenticatorTransportFuture[] | undefined
) => {
  try {
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INSERT_PASSKEY, [
      cred_id,
      cred_public_key,
      RegisteredUser,
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

const findRegUser = async (user_email: string): Promise<UserType> => {
  const [rows] = await poolPromise.execute(Sql.FIND_BY_EMAIL, [user_email]);
  return (rows as any)[0];
};

const userPassKeyByEmail = async (user_email: string) => {
  const [rows] = await poolPromise.execute(Sql.USER_ACC_PASSKEY, [user_email]);
  if ((rows as any).length === 0) return null;
  return (rows as any)[0];
};

const countSuspendedUsers = async () => {
  const [rows] = await poolPromise.execute(Sql.COUNT_WAITING);
  return (rows as any)[0];
};

const fetchAllRegisteredUsers = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_ALL);
  return rows as any[];
};

const updateAccountStatus = async (regUserId: string) => {
  const connection = await poolPromise.getConnection();
  try {
    await connection.beginTransaction();
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.UPDATE_STATUS, [regUserId]);
    await connection.commit();

    return result[0].affectedRows > 0;
  } catch (error) {
    if (connection) await connection.rollback();
  } finally {
    if (connection) connection.release();
  }
};
// const userPKsByEmail = async (user_email: string) => {
//   const [rows] = await poolPromise.execute(Sql.PASSKEYS, [user_email]);
//   if ((rows as any).length === 0) return null;
//   return (rows as any)[0];
// };

// const updatePassKey = async (newCounter: number, cred_id: number, reg_user_id: number) => {
//   const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.UPDATE_PASSKEY, [newCounter, cred_id, reg_user_id]);
//   return result[0].affectedRows > 0;
// };

// const deleteRegisteredUser = async (reg_user_id: number) => {
//   await poolPromise.execute(Sql.DELETE, [reg_user_id]);
//   return { message: `RegisteredUser with ID ${reg_user_id} deleted` };
// };

export {
  createAdminOrUsers,
  findRegUser,
  userPassKeyByEmail,
  createPasskey,
  countSuspendedUsers,
  // deleteRegisteredUser,
  updateAccountStatus,
  fetchAllRegisteredUsers,
};
