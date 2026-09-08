const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to assign custom claims to admin users.
 * Triggered by superadmin.
 */
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Check that caller is authenticated and is a superadmin
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Only authenticated administrators can assign admin privileges.'
    );
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('Admins').doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'superadmin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only superadmin accounts can assign admin privileges.'
    );
  }

  const { targetUid, role } = data;
  if (!targetUid) {
    throw new functions.https.HttpsError('invalid-argument', 'targetUid is required.');
  }

  await admin.auth().setCustomUserClaims(targetUid, {
    admin: true,
    role: role || 'admin',
  });

  await admin.firestore().collection('Admins').doc(targetUid).set({
    role: role || 'admin',
    status: 'active',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await admin.firestore().collection('AuditLogs').add({
    adminId: callerUid,
    adminEmail: context.auth.token.email || 'superadmin',
    action: 'SET_ADMIN_CLAIM',
    targetCollection: 'Admins',
    targetId: targetUid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: { role: role || 'admin' },
  });

  return { success: true, message: `Admin privileges granted to ${targetUid}` };
});

/**
 * Cloud Function to securely delete an Auth user account.
 */
exports.deleteAuthUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required.'
    );
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('Admins').doc(callerUid).get();
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Caller is not an authorized administrator.'
    );
  }

  const { uid } = data;
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'Target uid is required.');
  }

  await admin.auth().deleteUser(uid);

  return { success: true, message: `Auth account ${uid} deleted successfully.` };
});
