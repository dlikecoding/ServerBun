import { poolPromise } from '..';

// SQL Queries
const Sql = {
  INSERT: `INSERT INTO UserGuest (user_email, user_name, request_status, request_at) VALUES (?, ?, ?, ?)`,
  EXISTS: `SELECT user_id FROM UserGuest WHERE user_email = ?`,
  FIND_BY_ID: `SELECT * FROM UserGuest WHERE user_id = ?`,
  FIND_BY_EMAIL: `SELECT * FROM UserGuest WHERE user_email = ?`,
  UPDATE_REQUEST_STATUS: `UPDATE UserGuest SET request_status = ?, request_at = ? WHERE user_id = ?`,
  DELETE: `DELETE FROM UserGuest WHERE user_id = ?`,
  FETCH_ALL: `SELECT user_id, user_email, user_name, request_status, request_at FROM UserGuest`,
};

// UserGuest Management Functions
const createUserGuest = async (user_email: string, user_name: string, request_status: number | null = null) => {
  const request_at = request_status !== null ? new Date() : null;

  try {
    const isExist = await findUserGuestByEmail(user_email);
    if (isExist) {
      console.log(`User already exist ${isExist.user_id}`);
      return null;
    }

    await poolPromise.execute(Sql.INSERT, [user_email, user_name, request_status, request_at]);
    return { user_email, user_name, request_status, request_at };
  } catch (error) {
    return null;
  }
};

const userGuestExists = async (user_email: string): Promise<boolean> => {
  const [rows] = await poolPromise.execute(Sql.EXISTS, [user_email]);
  return (rows as any).length > 0;
};

const findUserGuestById = async (user_id: number) => {
  const [rows] = await poolPromise.execute(Sql.FIND_BY_ID, [user_id]);
  if ((rows as any).length === 0) {
    return null;
  }
  return (rows as any)[0];
};

const findUserGuestByEmail = async (user_email: string) => {
  const [rows] = await poolPromise.execute(Sql.FIND_BY_EMAIL, [user_email]);
  if ((rows as any).length === 0) {
    return null;
  }
  return (rows as any)[0];
};

const updateRequestStatus = async (user_id: number, request_status: number) => {
  const request_at = new Date();
  await poolPromise.execute(Sql.UPDATE_REQUEST_STATUS, [request_status, request_at, user_id]);
  return { user_id, request_status, request_at };
};

const deleteUserGuest = async (user_id: number) => {
  await poolPromise.execute(Sql.DELETE, [user_id]);
  return { message: `UserGuest with ID ${user_id} deleted` };
};

const fetchAllUserGuests = async () => {
  const [rows] = await poolPromise.execute(Sql.FETCH_ALL);
  return rows as any[];
};

// Export All Functions
export { createUserGuest, userGuestExists, findUserGuestById, findUserGuestByEmail, updateRequestStatus, deleteUserGuest, fetchAllUserGuests };
