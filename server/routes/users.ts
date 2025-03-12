import { Hono } from 'hono';

const users = new Hono();

// users.get('/', async (c) => {
//   try {
//     // const data = connection.query('SELECT * FROM Account').stream();
//     // return c.json(data);
//   } catch (err) {
//     console.error(err);
//     return c.json({ error: 'Failed to fetch Account' }, 500);
//   }
// });

export default users;
