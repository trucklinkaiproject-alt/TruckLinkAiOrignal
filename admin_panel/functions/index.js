/**
 * TruckLink AI – Admin Cloud Functions (v2)
 *
 * Hardened:
 * - Node 20 runtime (see package.json engines.node)
 * - firebase-functions v2 onCall API
 * - Caller verified via custom claim, NOT just Admins collection presence
 * - deleteAuthUser restricted to superadmin, cannot self-delete, writes audit log
 * - setAdminClaim also writes email + displayName to Admins doc
 * - sendBroadcastNotification moved server-side (batched writes, admin-only)
 * - Audit logs use real caller UID
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

// ─── Helper: verify caller is admin via custom claim ────────────────────────
async function requireAdmin(authContext) {
  if (!authContext) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  // Verify claim from token — not from Firestore doc (prevents TOCTOU)
  if (!authContext.token || authContext.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Caller does not have admin privileges.');
  }
  return authContext.uid;
}

async function requireSuperAdmin(authContext) {
  const callerUid = await requireAdmin(authContext);
  if (authContext.token.role !== 'superadmin') {
    throw new HttpsError('permission-denied', 'Only superadmin can perform this action.');
  }
  return callerUid;
}

// ─── Helper: write audit log ─────────────────────────────────────────────────
async function writeAuditLog(callerUid, callerEmail, action, targetCollection, targetId, details = {}) {
  try {
    await db.collection('AuditLogs').add({
      adminId: callerUid,
      adminEmail: callerEmail || '',
      action,
      targetCollection,
      targetId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details,
    });
  } catch (err) {
    console.error('[AuditLog] Failed to write audit log:', err);
  }
}

/**
 * setAdminClaim
 * Assigns Firebase Auth custom claims and creates/updates the Admins doc.
 * Restricted to superadmin callers.
 */
exports.setAdminClaim = onCall({ enforceAppCheck: false }, async (request) => {
  const callerUid = await requireSuperAdmin(request.auth);
  const callerEmail = request.auth.token.email || '';

  const { targetUid, role, email, displayName } = request.data;

  if (!targetUid || typeof targetUid !== 'string' || targetUid.trim() === '') {
    throw new HttpsError('invalid-argument', 'targetUid is required and must be a non-empty string.');
  }
  if (!['admin', 'moderator', 'superadmin'].includes(role || 'admin')) {
    throw new HttpsError('invalid-argument', 'role must be one of: admin, moderator, superadmin.');
  }

  const assignedRole = role || 'admin';

  // Set custom claims on the target user
  await auth.setCustomUserClaims(targetUid, {
    admin: true,
    role: assignedRole,
  });

  // Create or update the Admins doc
  await db.collection('Admins').doc(targetUid).set({
    uid: targetUid,
    email: email || '',
    displayName: displayName || 'Admin User',
    role: assignedRole,
    status: 'active',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await writeAuditLog(callerUid, callerEmail, 'SET_ADMIN_CLAIM', 'Admins', targetUid, {
    role: assignedRole,
    email,
  });

  return { success: true, message: `Admin privileges (${assignedRole}) granted to ${targetUid}` };
});

/**
 * deleteAuthUser
 * Securely deletes a Firebase Auth user account.
 * Restricted to superadmin. Cannot delete self.
 * Writes audit log.
 * Also deletes the Admins doc if one exists.
 */
exports.deleteAuthUser = onCall({ enforceAppCheck: false }, async (request) => {
  const callerUid = await requireSuperAdmin(request.auth);
  const callerEmail = request.auth.token.email || '';

  const { uid } = request.data;

  if (!uid || typeof uid !== 'string' || uid.trim() === '') {
    throw new HttpsError('invalid-argument', 'Target uid is required and must be a non-empty string.');
  }

  if (uid === callerUid) {
    throw new HttpsError('failed-precondition', 'You cannot delete your own account.');
  }

  // Delete Auth account
  await auth.deleteUser(uid);

  // Clean up Admins doc if it exists
  const adminDocRef = db.collection('Admins').doc(uid);
  const adminSnap = await adminDocRef.get();
  if (adminSnap.exists) {
    await adminDocRef.delete();
  }

  await writeAuditLog(callerUid, callerEmail, 'AUTH_USER_DELETED', 'Auth', uid, {
    note: 'Auth account and Admins doc deleted',
  });

  return { success: true, message: `Auth account ${uid} deleted successfully.` };
});

/**
 * deleteUserProfile
 * Server-side deletion of a User/Broker/Driver profile including subcollections.
 * Restricted to admin callers.
 */
exports.deleteUserProfile = onCall({ enforceAppCheck: false }, async (request) => {
  const callerUid = await requireAdmin(request.auth);
  const callerEmail = request.auth.token.email || '';

  const { uid, role } = request.data;

  if (!uid || !role) {
    throw new HttpsError('invalid-argument', 'uid and role are required.');
  }
  if (!['User', 'Broker', 'Driver'].includes(role)) {
    throw new HttpsError('invalid-argument', 'role must be one of: User, Broker, Driver.');
  }

  // Define subcollections per role
  const subcollectionsByRole = {
    User: ['Requests', 'Notifications', 'fcmTokens'],
    Broker: ['IncomingRequests', 'DriverNetwork', 'Reviews', 'Notifications', 'fcmTokens'],
    Driver: ['ReceivedOffers', 'DriverTrips', 'Reviews', 'Notifications', 'fcmTokens'],
  };

  const subcollections = subcollectionsByRole[role] || [];
  const batch = db.batch();

  // Delete subcollection docs (Firestore does not auto-delete subcollections)
  for (const sub of subcollections) {
    const subRef = db.collection(role).doc(uid).collection(sub);
    const subSnap = await subRef.limit(500).get();
    subSnap.docs.forEach((d) => batch.delete(d.ref));
  }

  // Delete root doc
  const rootRef = db.collection(role).doc(uid);
  batch.delete(rootRef);

  await batch.commit();

  // Delete Auth account
  try {
    await auth.deleteUser(uid);
  } catch (authErr) {
    console.warn(`[deleteUserProfile] Auth delete failed for ${uid}:`, authErr.message);
  }

  await writeAuditLog(callerUid, callerEmail, `${role.toUpperCase()}_PROFILE_DELETED`, role, uid, {
    subcollectionsDeleted: subcollections,
  });

  return { success: true, message: `${role} profile ${uid} and subcollections deleted.` };
});

/**
 * sendBroadcastNotification
 * Server-side fan-out broadcast to all users/brokers/drivers.
 * Restricted to admin callers. Uses batched writes.
 */
exports.sendBroadcastNotification = onCall({ enforceAppCheck: false }, async (request) => {
  const callerUid = await requireAdmin(request.auth);
  const callerEmail = request.auth.token.email || '';

  const { title, message, targetAudience } = request.data;

  if (!title || !message) {
    throw new HttpsError('invalid-argument', 'title and message are required.');
  }
  if (!['all', 'users', 'brokers', 'drivers'].includes(targetAudience)) {
    throw new HttpsError('invalid-argument', 'targetAudience must be one of: all, users, brokers, drivers.');
  }

  // Record broadcast in SystemNotifications
  const notifDocRef = await db.collection('SystemNotifications').add({
    title,
    message,
    targetAudience,
    sentBy: callerEmail,
    sentByUid: callerUid,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'sent',
  });

  const rolesToTarget = [];
  if (targetAudience === 'all') rolesToTarget.push('User', 'Broker', 'Driver');
  else if (targetAudience === 'users') rolesToTarget.push('User');
  else if (targetAudience === 'brokers') rolesToTarget.push('Broker');
  else if (targetAudience === 'drivers') rolesToTarget.push('Driver');

  let totalSent = 0;

  for (const role of rolesToTarget) {
    const snap = await db.collection(role).get();
    const docs = snap.docs;

    // Write in batches of 500
    for (let i = 0; i < docs.length; i += 500) {
      const batch = db.batch();
      const chunk = docs.slice(i, i + 500);
      chunk.forEach((recDoc) => {
        const notifId = `broadcast_${notifDocRef.id}_${recDoc.id}`;
        const notifRef = db.collection(role).doc(recDoc.id).collection('Notifications').doc(notifId);
        batch.set(notifRef, {
          id: notifId,
          title,
          body: message,
          subtitle: message,
          type: 'admin_broadcast',
          order_id: '',
          order_no: '',
          chat_id: '',
          sender_id: callerUid,
          sender_name: 'TruckLink AI Admin',
          recipient_id: recDoc.id,
          recipient_role: role,
          is_read: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        totalSent++;
      });
      await batch.commit();
    }
  }

  await writeAuditLog(callerUid, callerEmail, 'BROADCAST_NOTIFICATION_SENT', 'SystemNotifications', notifDocRef.id, {
    title,
    targetAudience,
    totalSent,
  });

  return { success: true, notificationId: notifDocRef.id, totalSent };
});
