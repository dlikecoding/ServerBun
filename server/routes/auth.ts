import { generateAuthenticationOptions, generateRegistrationOptions, verifyAuthenticationResponse, verifyRegistrationResponse } from '@simplewebauthn/server';
import { Hono } from 'hono';
import { createPasskey, createUserGuest, userPassKeyByEmail, updatePassKey, userGuestExists, userPKsByEmail } from '../db/module/guest';

import { zValidator } from '@hono/zod-validator';
import { clearCookie, createAuthSession, getSecureCookie, setSecureCookie, userAuthSchema } from './authHelper/cookies';
import { accountExists } from '../db/module/account';

const auth = new Hono();
const WEBSITE_TITLE = 'Photos Gallery X';

const userValidate = zValidator('query', userAuthSchema, (result, c) => {
  if (!result.success) return c.json({ error: result.error.errors[0]?.message }, 400);
});

auth.get('/init-register', userValidate, async (c) => {
  try {
    const { username, email } = c.req.valid('query');
    if (!email) return c.json({ error: 'Email is required' }, 400);

    if (await userGuestExists(email)) return c.json({ error: 'User already exists' }, 400);

    const options = await generateRegistrationOptions({
      rpName: WEBSITE_TITLE,
      rpID: Bun.env.DOMAIN_NAME,
      userName: email,
      userDisplayName: username,
      authenticatorSelection: {
        residentKey: 'required',
        userVerification: 'preferred',
      },
    });

    await setSecureCookie(c, 'regInfo', { username, email, challenge: options.challenge });

    return c.json(options, 200);
  } catch (err) {
    console.error(err);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

auth.post('/verify-register', async (c) => {
  const regInfo = await getSecureCookie(c, 'regInfo');
  if (!regInfo) return c.json({ error: 'Registration info not found' }, 400);

  const reqJson = await c.req.json();

  const verification = await verifyRegistrationResponse({
    response: reqJson,
    expectedChallenge: regInfo.challenge,
    expectedOrigin: Bun.env.ORIGIN_URL,
    expectedRPID: Bun.env.DOMAIN_NAME,

    requireUserVerification: true,
  });

  if (!(verification.verified && verification.registrationInfo)) {
    return c.json({ verified: false, error: 'Verification failed' }, 400);
  }

  const lastInsertId = await createUserGuest(regInfo.username, regInfo.email);
  if (!lastInsertId) return c.json({ error: 'User creation failed' }, 400);

  const createPK = await createPasskey(
    verification.registrationInfo.credential.id,
    verification.registrationInfo.credential.publicKey,
    lastInsertId,
    verification.registrationInfo.credential.counter,
    verification.registrationInfo.credentialDeviceType,
    verification.registrationInfo.credentialBackedUp,
    verification.registrationInfo.credential.transports
  );

  if (!createPK) return c.json({ error: 'Passkey creation failed' }, 400);
  clearCookie(c, 'regInfo');
  return c.json({ verified: verification.verified }, 200);
});

auth.get('/init-auth', userValidate, async (c) => {
  const { email } = c.req.valid('query');
  if (!email) return c.json({ error: 'Email is required' }, 400);

  const userPasskeys = await userPKsByEmail(email);
  if (!userPasskeys) return c.json({ error: 'No user for this email' }, 400);

  // Reject user have no account to login
  const accountCreated = await accountExists(email);
  if (!accountCreated) return c.json({ error: `You don't have an account yet. Please wait for admin` }, 400);

  const options: PublicKeyCredentialRequestOptionsJSON = await generateAuthenticationOptions({
    rpID: Bun.env.DOMAIN_NAME,
    allowCredentials: [
      {
        id: userPasskeys.cred_id,
        transports: JSON.parse(userPasskeys.transports),
      },
    ],
    userVerification: 'required',
  });

  await setSecureCookie(c, 'authInfo', { email, challenge: options.challenge });

  return c.json(options, 200);
});

auth.post('/verify-auth', async (c) => {
  const authInfo = await getSecureCookie(c, 'authInfo');
  if (!authInfo) return c.json({ error: 'Authentication info not found' }, 400);

  const userPasskeys = await userPassKeyByEmail(authInfo.email);
  const reqJsonBody = await c.req.json();

  if (!userPasskeys) return c.json({ error: 'Invalid credentials' }, 401);

  let verification;
  try {
    verification = await verifyAuthenticationResponse({
      response: reqJsonBody,
      expectedChallenge: authInfo.challenge,
      expectedOrigin: Bun.env.ORIGIN_URL,
      expectedRPID: Bun.env.DOMAIN_NAME,
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
    return c.text('Unauthorized access', 401);
  }

  if (!verification.verified) return c.json({ verified: false, error: 'Verification failed' }, 400);

  const updatePKstatus = await updatePassKey(verification.authenticationInfo.newCounter, userPasskeys.cred_id, userPasskeys.UserGuest);
  if (!updatePKstatus) console.log('Update Passkeys status failed!');
  clearCookie(c, 'authInfo');

  await createAuthSession(c, { email: authInfo.email, isAuth: true });

  return c.json({ verified: verification.verified });
});

export default auth;
