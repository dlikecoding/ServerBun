import type { AuthenticatorTransportFuture } from '@simplewebauthn/server';
import type { UserType } from '../../routes/authHelper/_cookies';
import { sql } from '..';

const createAdminOrUsers = async (user_name: string, user_email: string) => {
  const result = await sql.begin(async (tx) => {
    const [isAdminExist] = await tx`SELECT reg_user_id FROM "RegisteredUser" LIMIT 1`;
    const userId = Bun.randomUUIDv7();

    await tx`INSERT INTO "RegisteredUser" (reg_user_id, user_name, user_email, role_type, status) 
              VALUES (${userId}, ${user_name}, ${user_email}, ${!isAdminExist ? 'admin' : 'user'}, ${!isAdminExist})`;
    return userId;
  });
  return result; // User ID
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
    const [result] = await sql`INSERT INTO "Passkeys" ( cred_id,  cred_public_key,  "RegisteredUser",  counter,  registered_device,  backup_eligible,  transports) 
    VALUES (${cred_id}, ${cred_public_key}, ${RegisteredUser}, ${counter}, ${registered_device}, ${backup_eligible}, ${JSON.stringify(transports)}::jsonb ) RETURNING *`;

    return result;
  } catch (error) {
    console.log(error);
    return null;
  }
};

const findRegUser = async (user_email: string): Promise<UserType> => {
  const [user] = await sql`SELECT reg_user_id, user_email, status, role_type FROM "RegisteredUser" WHERE user_email = ${user_email} LIMIT 1`;
  return user;
};

const userPassKeyByEmail = async (user_email: string) => {
  const [rows] =
    await sql`SELECT reg.reg_user_id, reg.user_email, reg.user_name, reg.role_type, reg.status, pks.cred_id, pks.cred_public_key, pks.counter, pks.transports FROM "RegisteredUser" reg 
                      JOIN "Passkeys" pks ON reg.reg_user_id = pks."RegisteredUser"
                      WHERE reg.user_email = ${user_email}`;
  return rows;
};

const countSuspendedUsers = async () => {
  const [result] = await sql`SELECT COUNT(reg_user_id) AS count_users FROM "RegisteredUser" WHERE status = false`;
  return result.count_users;
};

const fetchAllUsers = async () => {
  return await sql`SELECT * FROM "RegisteredUser" reg WHERE role_type = 'user'`;
};

const updateAccountStatus = async (userEmail: string) => {
  const [result] = await sql`UPDATE "RegisteredUser" SET status = NOT status WHERE user_email = ${userEmail} RETURNING reg_user_id`;
  return result;
};

export { createAdminOrUsers, findRegUser, userPassKeyByEmail, createPasskey, countSuspendedUsers, updateAccountStatus, fetchAllUsers };

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

// deleteRegisteredUser,
