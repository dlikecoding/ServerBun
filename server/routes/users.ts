import { Hono } from 'hono';

const users = new Hono();

// const WEBSITE_TITLE = 'Photos Gallery X';

// const userValidate = zValidator('query', userAuthSchema, (result, c) => {
//   if (!result.success) return c.json({ error: result.error.errors[0]?.message }, 400);
// });

// users.get('/init-register', userValidate, async (c) => {
//   try {
//     const { username, email } = c.req.valid('query');

//     if (!email) return c.json({ error: 'Email is required' }, 400);

//     if (await userGuestExists(email)) return c.json({ error: 'User already exists' }, 400);

//     const options = await generateRegistrationOptions({
//       rpName: WEBSITE_TITLE, // Human-readable title for your website
//       rpID: Bun.env.DOMAIN_NAME, // A unique identifier for your website. 'simplewebauthn.dev'
//       userName: email, //
//       userDisplayName: username,
//       authenticatorSelection: {
//         // "Discoverable credentials" used to be called "resident keys". The
//         // old name persists in the options passed to `navigator.credentials.create()`.
//         residentKey: 'required',
//         userVerification: 'preferred',
//       },
//     });

//     setSecureCookie(c, 'regInfo', { username, email, challenge: options.challenge });

//     return c.json(options, 200);
//   } catch (err) {
//     console.error(err);
//     return c.json({ error: 'Failed to fetch Account' }, 500);
//   }
// });

// users.post('/verify-register', async (c) => {
//   const regInfo = getSecureCookie(c, 'regInfo');
//   if (!regInfo) return c.json({ error: 'Registration info not found' }, 400);

//   const reqJson = await c.req.json();

//   const verification = await verifyRegistrationResponse({
//     response: reqJson,
//     expectedChallenge: regInfo.challenge,
//     expectedOrigin: Bun.env.ORIGIN_URL,
//     expectedRPID: Bun.env.DOMAIN_NAME,

//     requireUserVerification: true,
//   });

//   if (!(verification.verified && verification.registrationInfo)) {
//     return c.json({ verified: false, error: 'Verification failed' }, 400);
//   }
//   // If no user exist, create admin account.

//   // Otherwise, create regular user.
//   const lastInsertId = await createUserGuest(regInfo.username, regInfo.email);
//   if (!lastInsertId) return c.json({ error: 'User creation failed' }, 400);

//   const createPK = await createPasskey(
//     verification.registrationInfo.credential.id,
//     verification.registrationInfo.credential.publicKey,
//     lastInsertId,
//     verification.registrationInfo.aaguid,
//     verification.registrationInfo.credential.counter,
//     verification.registrationInfo.credentialDeviceType,
//     verification.registrationInfo.credentialBackedUp,
//     verification.registrationInfo.credential.transports
//   );

//   if (!createPK) return c.json({ error: 'Passkey creation failed' }, 400);
//   clearCookie(c, 'regInfo');
//   return c.json({ verified: verification.verified }, 200);
// });

// users.get(
//   '/init-auth',
//   zValidator('query', userAuthSchema, (result, c) => {
//     if (!result.success) {
//       return c.json({ error: result.error.errors[0]?.message }, 400);
//     }
//   }),
//   async (c) => {
//     const { email } = c.req.valid('query');
//     if (!email) return c.json({ error: 'Email is required' }, 400);

//     const userPasskeys = await userPKsByEmail(email);
//     if (!userPasskeys) return c.json({ error: 'No user for this email' }, 400);

//     const options: PublicKeyCredentialRequestOptionsJSON = await generateAuthenticationOptions({
//       rpID: Bun.env.DOMAIN_NAME,
//       allowCredentials: [
//         {
//           id: userPasskeys.cred_id,
//           transports: JSON.parse(userPasskeys.transports),
//         },
//       ],
//       userVerification: 'required',
//     });

//     setSecureCookie(c, 'authInfo', { email, challenge: options.challenge });

//     return c.json(options, 200);
//   }
// );

// users.post('/verify-auth', async (c) => {
//   const authInfo = getSecureCookie(c, 'authInfo');
//   if (!authInfo) return c.json({ error: 'Authentication info not found' }, 400);

//   const userPasskeys = await userPassKeyByEmail(authInfo.email);
//   const reqJsonBody = await c.req.json();

//   if (!userPasskeys) return c.json({ error: 'Invalid user' }, 400);

//   let verification;
//   try {
//     verification = await verifyAuthenticationResponse({
//       response: reqJsonBody,
//       expectedChallenge: authInfo.challenge,
//       expectedOrigin: Bun.env.ORIGIN_URL,
//       expectedRPID: Bun.env.DOMAIN_NAME,
//       credential: {
//         id: userPasskeys.cred_id,
//         publicKey: userPasskeys.cred_public_key,
//         counter: userPasskeys.counter,
//         transports: JSON.parse(userPasskeys.transports),
//       },
//       requireUserVerification: true,
//     });
//   } catch (error) {
//     console.error(error);
//     return c.json({ error: 'Error verify user' }, 400);
//   }

//   if (!verification.verified) return c.json({ verified: false, error: 'Verification failed' }, 400);

//   const updatePKstatus = await updatePassKey(verification.authenticationInfo.newCounter, userPasskeys.cred_id, userPasskeys.UserGuest);
//   if (!updatePKstatus) console.log('Update Passkeys status failed!');
//   clearCookie(c, 'authInfo');

//   return c.json({ verified: verification.verified });
// });

// // // Add a user
// // users.post('/', async (ctx) => {
// //   try {
// //     const { name, email } = await ctx.req.json();

// //     if (!name || !email) {
// //       return ctx.json({ error: 'Missing fields' }, 400);
// //     }

// //     connection.query('INSERT INTO users (name, email) VALUES (?, ?)', [name, email]);
// //     return ctx.json({ message: 'User added successfully' }, 201);
// //   } catch (err) {
// //     console.error(err);
// //     return ctx.json({ error: 'Failed to add user' }, 500);
// //   }
// // });

export default users;

// users.get('/', async (c) => {
//   try {
//     // const data = connection.query('SELECT * FROM Account').stream();
//     // return c.json(data);
//   } catch (err) {
//     console.error(err);
//     return c.json({ error: 'Failed to fetch Account' }, 500);
//   }
// });
