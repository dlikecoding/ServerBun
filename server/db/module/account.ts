import type { FieldPacket, ResultSetHeader } from 'mysql2/promise';
import { poolPromise } from '..';

// SQL Queries
const Sql = {
  EXISTS: `SELECT account_id FROM Account WHERE user_email = ?`,
  FIND_BY_EMAIL: `SELECT * FROM Account WHERE user_email = ?`,

  CREATE_ADMIN: `CALL CreateAdmin(?)`,
  INSERT: `INSERT INTO Account (user_email, role_type) VALUES (?, ?)`,

  // UPDATE_EMAIL: `UPDATE Account SET user_email = ? WHERE account_id = ?`,
  // UPDATE_STATUS: `UPDATE Account SET status = ? WHERE account_id = ?`,
  DELETE: `DELETE FROM Account WHERE account_id = ?`,
  FETCH_ALL: `SELECT account_id, user_email, status, role_type, created_at FROM Account`,
  ENABLE_M2FA: `UPDATE Account SET m2f_isEnable = 1, public_key = ? WHERE account_id = ?`,
};

const accountExists = async (user_email: string): Promise<boolean> => {
  const [rows] = await poolPromise.execute(Sql.EXISTS, [user_email]);
  return (rows as any).length > 0;
};

const createAdminAcc = async (user_email: string) => {
  const [rows] = await poolPromise.execute(`SELECT account_id FROM Account LIMIT 1`);
  if ((rows as any).length > 0) return (rows as any)[0];

  return await createAccount(user_email, 'admin');
};

const createAccount = async (user_email: string, role_type: string = 'user') => {
  const connection = await poolPromise.getConnection();
  try {
    await connection.beginTransaction();
    const result: [ResultSetHeader, FieldPacket[]] = await poolPromise.execute(Sql.INSERT, [user_email, role_type]);
    await connection.commit();

    return result[0].affectedRows > 0;
  } catch (error) {
    if (connection) await connection.rollback();
  } finally {
    if (connection) connection.release();
  }
};

const findAccountByEmail = async (user_email: string) => {
  const [rows] = await poolPromise.execute(Sql.FIND_BY_EMAIL, [user_email]);
  if ((rows as any).length === 0) {
    throw new Error('Account not found');
  }
  return (rows as any)[0];
};

// Export All Functions
export {
  accountExists,
  findAccountByEmail,
  createAdminAcc,

  // createAccount,
  // updateAccountEmail,
  // updateAccountPassword,
  // updateAccountStatus,
  // deleteAccount,
  // fetchAllAccounts,
  // authenticateAccount,
  // enableM2FA,
};

// // userService.js
// export const getUserById = async (id: any) => {
//   const [user] = await poolPromise.execute('SELECT * FROM Account WHERE email = ?', [id]);
//   return (user as any)[0];
// };

// // Utility Functions
// const hashPassword = async (password: string): Promise<string> => {
//   return await Bun.password.hash(password, {
//  algorithm: 'bcrypt',
//  cost: 4, // number between 4-31
//   });
// };

// const verifyPassword = async (password: string, hash: string): Promise<boolean> => {
//   return await Bun.password.verify(password, hash);
// };

// const generatePublicKey = async (): Promise<string> => {
//   return await Bun.password.hash(Date.now().toString());
// };

// // User Management Functions
// const createAccount = async (user_email: string, password: string) => {
//   const hashedPassword = await hashPassword(password);

//   const [result] = await poolPromise.execute(Sql.INSERT, [user_email, hashedPassword]);
//   const insertedId = (result as any).insertId;

//   return {
//  account_id: insertedId,
//  user_email,
//  status: 'active',
//  role_type: 'user',
//  m2f_isEnable: 0,
//   };
// };

// const updateAccountEmail = async (account_id: number, newEmail: string) => {
//   await poolPromise.execute(Sql.UPDATE_EMAIL, [newEmail, account_id]);
//   return { account_id, newEmail };
// };

// const updateAccountPassword = async (account_id: number, newPassword: string) => {
//   const hashedPassword = await hashPassword(newPassword);
//   await poolPromise.execute(Sql.UPDATE_PASSWORD, [hashedPassword, account_id]);
//   return { account_id };
// };

// const updateAccountStatus = async (account_id: number, status: 'active' | 'suspended' | 'deleted') => {
//   await poolPromise.execute(Sql.UPDATE_STATUS, [status, account_id]);
//   return { account_id, status };
// };

// const deleteAccount = async (account_id: number) => {
//   await poolPromise.execute(Sql.DELETE, [account_id]);
//   return { message: `Account with ID ${account_id} deleted` };
// };

// const fetchAllAccounts = async () => {
//   const [rows] = await poolPromise.execute(Sql.FETCH_ALL);
//   return rows as any[];
// };

// const authenticateAccount = async (user_email: string, password: string) => {
//   const account = await findAccountByEmail(user_email);

//   if (account.status !== 'active') {
//  throw new Error('Account is not active');
//   }

//   const isPasswordValid = await verifyPassword(password, account.password);
//   if (!isPasswordValid) {
//  throw new Error('Invalid email or password');
//   }

//   return {
//  account_id: account.account_id,
//  user_email: account.user_email,
//  role_type: account.role_type,
//   };
// };

// const enableM2FA = async (account_id: number) => {
//   const publicKey = generatePublicKey();
//   await poolPromise.execute(Sql.ENABLE_M2FA, [publicKey, account_id]);
//   return { account_id, m2f_isEnable: 1, publicKey };
// };
