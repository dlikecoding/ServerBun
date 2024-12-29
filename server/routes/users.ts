import { Hono } from 'hono';

const users = new Hono();

users.get('/', async (c) => {
  try {
    // const data = connection.query('SELECT * FROM Account').stream();
    // return c.json(data);
  } catch (err) {
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

// // Add a user
// users.post('/', async (ctx) => {
//   try {
//     const { name, email } = await ctx.req.json();

//     if (!name || !email) {
//       return ctx.json({ error: 'Missing fields' }, 400);
//     }

//     connection.query('INSERT INTO users (name, email) VALUES (?, ?)', [name, email]);
//     return ctx.json({ message: 'User added successfully' }, 201);
//   } catch (err) {
//     console.error(err);
//     return ctx.json({ error: 'Failed to add user' }, 500);
//   }
// });

export default users;
