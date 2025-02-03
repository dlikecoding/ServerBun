import mysql, { type PoolOptions } from 'mysql2/promise';

const access: PoolOptions = {
  host: Bun.env.DB_HOST,
  user: Bun.env.DB_USER,
  password: Bun.env.DB_PASS,
  database: Bun.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
  maxIdle: 5, // max idle connections, the default value is the same as `connectionLimit`
  idleTimeout: 60000, // idle connections timeout, in milliseconds, the default value 60000
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
};

export const poolPromise = mysql.createPool(access);

// export const poolPromise = pool.promise();
// export const connectionPromise = await poolPromise.getConnection();
