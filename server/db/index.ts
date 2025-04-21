import { SQL } from 'bun';

export const sql = new SQL({
  url: Bun.env.DB_URL, // Required

  // Connection pool settings
  maxLifetime: 0, // Connection lifetime in seconds (0 = forever)
  connectionTimeout: 30, // Timeout when establishing new connections
  max: 10, // Maximum connections in pool
  idleTimeout: 60, // Close idle connections after seconds

  // tls: true, // SSL/TLS options

  // Callbacks
  // onconnect: (client) => {
  //   console.log('Connected to database', client);
  // },
  // onclose: (client) => {
  //   console.log('Connection closed', client);
  // },
});

// await using sqlUnix = new SQL({
//   path: Bun.env.DB_UNIX,

//   username: Bun.env.DB_USER,
//   // port: Bun.env.DB_PORT,
//   password: Bun.env.DB_PASS,
//   database: Bun.env.DB_NAME,
// });

// // Create table
// await sql`
//   CREATE TABLE IF NOT EXISTS articles (
//     id SERIAL PRIMARY KEY,
//     title TEXT,
//     content TEXT
//   )
// `.simple();

// // Search function
// async function searchArticles(searchTerm: string) {
//   const results = await sql`
//     SELECT *
//     FROM articles
//     WHERE
//       to_tsvector('english', title) @@ to_tsquery('english', ${searchTerm})
//       OR
//       to_tsvector('english', content) @@ to_tsquery('english', ${searchTerm})
//   `;
//   return results;
// }

// // Usage
// const searchResults = await searchArticles('database');
// console.log(searchResults);
