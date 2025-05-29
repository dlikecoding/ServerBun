import { generateAuthenticationOptions, generateRegistrationOptions, verifyAuthenticationResponse, verifyRegistrationResponse } from '@simplewebauthn/server';
import { Hono } from 'hono';
import { createPasskey, userPassKeyByEmail, findRegUser, countSuspendedUsers, createAdminOrUsers } from '../db/module/regUser';

import { clearCookie, createAuthSession, getSecureCookie, setSecureCookie, userAuthSchema, type UserType } from './authHelper/_cookies';
import { validateSchema } from '../modules/validateSchema';
import { insertErrorLog } from '../db/module/system';
import { logUserInDB } from '../middleware/validateAuth';

const auth = new Hono();
const WEBSITE_TITLE = 'Photos Gallery X';
const LIMIT_NUMBER_REGISTER = 2; // Limit number of user can register for an account

auth.get('/init-register', logUserInDB(false), validateSchema('query', userAuthSchema), async (c) => {
  try {
    const result = await countSuspendedUsers();
    // if registered user waiting status is >= N, STOP allow new user register.
    if (result.waiting >= LIMIT_NUMBER_REGISTER) return c.json({ error: 'User creation have reached limited.' }, 400);

    const { username, email } = c.req.valid('query');
    if (!email) return c.json({ error: 'Email is required' }, 400);

    if (await findRegUser(email)) return c.json({ error: 'User already exists' }, 400);

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

    const registerInfor = { username, email, challenge: options.challenge };
    await setSecureCookie(c, 'regInfo', registerInfor);

    return c.json(options, 200);
  } catch (error) {
    console.error(error);
    await insertErrorLog('auth.ts', 'init-register', error);
    return c.json({ error: 'Failed to fetch Account' }, 500);
  }
});

auth.post('/verify-register', async (c) => {
  try {
    const regInfo = await getSecureCookie(c, 'regInfo');
    if (!regInfo) return c.json({ error: 'Registration info not found' }, 403);

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

    // if no account exist, create admin account, otherwise, create user with suppended status
    const lastInsertId = await createAdminOrUsers(regInfo.username, regInfo.email);
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
  } catch (error) {
    await insertErrorLog('auth.ts', 'verify-register', error);
    return c.json({ error: 'Error with verification' }, 500);
  }
});

auth.get('/init-auth', logUserInDB(true), validateSchema('query', userAuthSchema), async (c) => {
  try {
    const { email } = c.req.valid('query');
    if (!email) return c.json({ error: 'Email is required' }, 400);

    const userAccount: UserType = await findRegUser(email);
    if (!userAccount) return c.json({ error: 'No user for this email' }, 400);

    // Reject user have susppended status to login
    if (!userAccount.status) return c.json({ error: `You don't have permission to log in at the moment. Please wait for admin approval` }, 400);

    const userPasskeys = await userPassKeyByEmail(email); // Passkeys
    if (!userPasskeys) return c.json({ error: 'No passkey created for this email' }, 400);

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
  } catch (error) {
    await insertErrorLog('auth.ts', 'init-auth', error);
    return c.json({ error: 'Failed to auth ' }, 500);
  }
});

auth.post('/verify-auth', async (c) => {
  try {
    const authInfo = await getSecureCookie(c, 'authInfo');
    if (!authInfo) return c.json({ error: 'Authentication info not found' }, 400);

    const userPasskeys = await userPassKeyByEmail(authInfo.email);
    if (!userPasskeys) return c.json({ error: 'Invalid user credentials' }, 401);

    const reqJsonBody = await c.req.json();

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
      return c.json({ error: 'Unauthorized access' }, 401);
    }

    const userLoggedIn: UserType = {
      userId: userPasskeys.reg_user_id,
      userEmail: userPasskeys.user_email,
      userName: userPasskeys.user_name,
      roleType: userPasskeys.role_type,
      status: userPasskeys.status,
    };

    if (!verification.verified) return c.json({ verified: false, error: 'Verification failed' }, 400);
    clearCookie(c, 'authInfo');

    await createAuthSession(c, userLoggedIn);

    return c.json({ verified: verification.verified });
  } catch (error) {
    await insertErrorLog('auth.ts', 'verify-auth', error);
    return c.json({ error: 'Failed to auth' }, 500);
  }
});

export default auth;
