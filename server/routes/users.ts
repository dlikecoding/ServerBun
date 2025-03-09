import { generateAuthenticationOptions, generateRegistrationOptions, verifyAuthenticationResponse, verifyRegistrationResponse } from '@simplewebauthn/server';
import { Hono } from 'hono';
import { createPasskey, createUserGuest, userPassKeyByEmail, updatePassKey, userGuestExists, userPKsByEmail } from '../db/module/guest';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';

const users = new Hono();

const WEBSITE_TITLE = 'Photos Gallery X';
const CLIENT_URL = 'http://localhost:7979'; // DEVELOPMENT
// const CLIENT_URL = 'http://localhost:8080';
const RP_ID = 'localhost';

const userSchema = z.object({
  username: z
    .string()
    .regex(/^[a-zA-Z0-9\s]*$/, 'The string should not contain special characters')
    .optional(),
  email: z.string().email('Invalid email address'),
});

users.get(
  '/init-register',
  zValidator('query', userSchema, (result, c) => {
    if (!result.success) {
      return c.json({ error: result.error.errors[0]?.message }, 400);
    }
  }),
  async (c) => {
    try {
      const { username, email } = c.req.valid('query');

      if (!email) return c.json({ error: 'Email is required' }, 400);

      if (await userGuestExists(email)) return c.json({ error: 'User already exists' }, 400);

      const options = await generateRegistrationOptions({
        rpName: WEBSITE_TITLE, // Human-readable title for your website
        rpID: RP_ID, // A unique identifier for your website. 'simplewebauthn.dev'
        userName: email, //
        userDisplayName: username,
        authenticatorSelection: {
          // "Discoverable credentials" used to be called "resident keys". The
          // old name persists in the options passed to `navigator.credentials.create()`.
          residentKey: 'required',
          userVerification: 'preferred',
        },
      });

      setCookie(
        c,
        'regInfo',
        JSON.stringify({
          username: username,
          email: email,
          challenge: options.challenge,
        }),
        {
          httpOnly: true,
          maxAge: 6000,
          secure: true,
        }
      );

      return c.json(options, 200);
    } catch (err) {
      console.error(err);
      return c.json({ error: 'Failed to fetch Account' }, 500);
    }
  }
);

users.post('/verify-register', async (c) => {
  const regInfo = getCookie(c, 'regInfo');

  if (!regInfo) return c.json({ error: 'Registration info not found' }, 400);

  const jsonRegInfo = JSON.parse(regInfo);

  const reqJson = await c.req.json();

  const verification = await verifyRegistrationResponse({
    response: reqJson,
    expectedChallenge: jsonRegInfo.challenge,
    expectedOrigin: CLIENT_URL,
    expectedRPID: RP_ID,

    requireUserVerification: true,
  });

  if (!(verification.verified && verification.registrationInfo)) {
    return c.json({ verified: false, error: 'Verification failed' }, 400);
  }
  // If no user exist, create admin account.

  // Otherwise, create regular user.
  const lastInsertId = await createUserGuest(jsonRegInfo.username, jsonRegInfo.email);
  if (!lastInsertId) return c.json({ error: 'User creation failed' }, 400);

  const createPK = await createPasskey(
    verification.registrationInfo.credential.id,
    verification.registrationInfo.credential.publicKey,
    lastInsertId,
    verification.registrationInfo.aaguid,
    verification.registrationInfo.credential.counter,
    verification.registrationInfo.credentialDeviceType,
    verification.registrationInfo.credentialBackedUp,
    verification.registrationInfo.credential.transports
  );

  if (!createPK) return c.json({ error: 'Passkey creation failed' }, 400);
  deleteCookie(c, 'regInfo');
  return c.json({ verified: verification.verified }, 200);
});

users.get(
  '/init-auth',
  zValidator('query', userSchema, (result, c) => {
    if (!result.success) {
      return c.json({ error: result.error.errors[0]?.message }, 400);
    }
  }),
  async (c) => {
    const { email } = c.req.valid('query');
    if (!email) return c.json({ error: 'Email is required' }, 400);

    const userPasskeys = await userPKsByEmail(email);
    if (!userPasskeys) return c.json({ error: 'No user for this email' }, 400);

    const options: PublicKeyCredentialRequestOptionsJSON = await generateAuthenticationOptions({
      rpID: RP_ID,
      allowCredentials: [
        {
          id: userPasskeys.cred_id,
          transports: JSON.parse(userPasskeys.transports),
        },
      ],
      userVerification: 'required',
    });

    setCookie(
      c,
      'authInfo',
      JSON.stringify({
        email: email,
        challenge: options.challenge,
      }),
      {
        httpOnly: true,
        maxAge: 6000,
        secure: true,
      }
    );

    return c.json(options, 200);
  }
);

users.post('/verify-auth', async (c) => {
  const authInfo = getCookie(c, 'authInfo');
  if (!authInfo) return c.json({ error: 'Authentication info not found' }, 400);

  const jsonRegInfo = JSON.parse(authInfo);

  const userPasskeys = await userPassKeyByEmail(jsonRegInfo.email);
  const reqJsonBody = await c.req.json();

  if (!userPasskeys) return c.json({ error: 'Invalid user' }, 400);

  let verification;
  try {
    verification = await verifyAuthenticationResponse({
      response: reqJsonBody,
      expectedChallenge: jsonRegInfo.challenge,
      expectedOrigin: CLIENT_URL,
      expectedRPID: RP_ID,
      credential: {
        id: userPasskeys.cred_id,
        publicKey: userPasskeys.cred_public_key,
        counter: userPasskeys.counter,
        transports: JSON.parse(userPasskeys.transports),
      },
      requireUserVerification: true,
    });
  } catch (error) {
    console.error(error);
    return c.json({ error: 'Error verify user' }, 400);
  }

  if (!verification.verified) return c.json({ verified: false, error: 'Verification failed' }, 400);

  const updatePKstatus = await updatePassKey(verification.authenticationInfo.newCounter, userPasskeys.cred_id, userPasskeys.UserGuest);
  if (!updatePKstatus) console.log('Update Passkeys status failed!');
  deleteCookie(c, 'authInfo');

  return c.json({ verified: verification.verified });
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

// users.get('/', async (c) => {
//   try {
//     // const data = connection.query('SELECT * FROM Account').stream();
//     // return c.json(data);
//   } catch (err) {
//     console.error(err);
//     return c.json({ error: 'Failed to fetch Account' }, 500);
//   }
// });
