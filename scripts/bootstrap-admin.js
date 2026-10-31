/**
 * scripts/bootstrap-admin.js
 *
 * One-time Admin SDK script to bootstrap the first Superadmin account.
 * Sets custom claim `admin: true`, `role: 'superadmin'`, and creates
 * the corresponding document in the Firestore `Admins` collection.
 *
 * Usage:
 *   node scripts/bootstrap-admin.js <email> [password] [displayName]
 *
 * Prerequisites:
 *   - Service account key file (set GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json)
 *     OR run in an environment with default Google Application Credentials.
 *   - npm install firebase-admin
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !admin.apps.length) {
  try {
    admin.initializeApp();
  } catch (err) {
    console.error('Error: GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.');
    console.error('Please download a service account key from Firebase Console -> Project Settings -> Service Accounts');
    console.error('Set it with:');
    console.error('  $env:GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json" (PowerShell)');
    console.error('  export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json" (Bash)');
    process.exit(1);
  }
} else if (!admin.apps.length) {
  admin.initializeApp();
}

const auth = admin.auth();
const db = admin.firestore();

async function bootstrapAdmin() {
  const args = process.argv.slice(2);
  const email = args[0] || 'admin@trucklink.ai';
  const password = args[1] || null;
  const displayName = args[2] || 'Super Admin';

  console.log(`[Bootstrap] Creating or updating superadmin for: ${email}`);

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
    console.log(`[Bootstrap] Existing Auth account found with UID: ${userRecord.uid}`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      if (!password) {
        console.error(`[Bootstrap] User ${email} does not exist and no password was provided to create it.`);
        console.error(`Usage: node scripts/bootstrap-admin.js <email> <password> [displayName]`);
        process.exit(1);
      }
      console.log(`[Bootstrap] Creating new Auth account for ${email}...`);
      userRecord = await auth.createUser({
        email,
        password,
        displayName,
        emailVerified: true,
      });
      console.log(`[Bootstrap] Auth user created with UID: ${userRecord.uid}`);
    } else {
      throw err;
    }
  }

  // 1. Set Custom User Claims for superadmin
  console.log(`[Bootstrap] Setting custom user claims: { admin: true, role: 'superadmin' }...`);
  await auth.setCustomUserClaims(userRecord.uid, {
    admin: true,
    role: 'superadmin',
  });

  // 2. Create or update Admins document in Firestore
  console.log(`[Bootstrap] Writing Admins document in Firestore for UID: ${userRecord.uid}...`);
  await db.collection('Admins').doc(userRecord.uid).set({
    uid: userRecord.uid,
    email: userRecord.email,
    displayName: userRecord.displayName || displayName,
    role: 'superadmin',
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // 3. Write AuditLog
  await db.collection('AuditLogs').add({
    adminId: userRecord.uid,
    adminEmail: userRecord.email,
    action: 'BOOTSTRAP_SUPERADMIN_CREATED',
    targetCollection: 'Admins',
    targetId: userRecord.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: {
      email: userRecord.email,
      role: 'superadmin',
    },
  });

  console.log(`[Bootstrap] SUCCESS! Superadmin created/configured successfully.`);
  console.log(`UID: ${userRecord.uid}`);
  console.log(`Email: ${userRecord.email}`);
  console.log(`Role: superadmin`);
  console.log(`You can now log in at the Admin Dashboard with this account.`);
}

bootstrapAdmin()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('[Bootstrap] Fatal error:', err);
    process.exit(1);
  });
