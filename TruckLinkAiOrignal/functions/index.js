const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function Trigger: Automatically sends real-time FCM Push Notifications
 * whenever a persistent notification document is created in Firestore.
 * Supports:
 * - User/{uid}/Notifications/{notificationId}
 * - Broker/{uid}/Notifications/{notificationId}
 * - Driver/{uid}/Notifications/{notificationId}
 */
exports.sendPushNotificationOnFirestoreCreate = onDocumentCreated(
  "{role}/{uid}/Notifications/{notificationId}",
  async (event) => {
    const { role, uid, notificationId } = event.params;
    const snapshot = event.data;

    if (!snapshot) {
      console.log(`[Push Notification] No data associated with event for ${role}/${uid}/${notificationId}`);
      return;
    }

    const notifData = snapshot.data();
    if (!notifData) {
      console.log(`[Push Notification] Document data is empty for ${notificationId}`);
      return;
    }

    // Role validation
    const validRoles = ["User", "Broker", "Driver"];
    if (!validRoles.includes(role)) {
      console.log(`[Push Notification] Skipping unknown role path: ${role}`);
      return;
    }

    try {
      // 1. Fetch all active FCM device tokens for recipient
      const tokensSnap = await admin
        .firestore()
        .collection(role)
        .doc(uid)
        .collection("fcmTokens")
        .get();

      if (tokensSnap.empty) {
        console.log(`[Push Notification] No registered FCM tokens found for ${role}: ${uid}`);
        return;
      }

      const tokenDocs = tokensSnap.docs;
      const fcmTokens = tokenDocs.map((doc) => doc.data().token).filter(Boolean);

      if (fcmTokens.length === 0) {
        console.log(`[Push Notification] No valid token strings for ${role}: ${uid}`);
        return;
      }

      console.log(`[Push Notification] Sending FCM message to ${fcmTokens.length} device(s) for ${role}: ${uid}`);

      // 2. Prepare payload
      const title = notifData.title || "TruckLink AI";
      const body = notifData.body || notifData.subtitle || "";
      const type = notifData.type || "general";
      const orderId = notifData.order_id || notifData.orderId || "";
      const orderNo = notifData.order_no || notifData.orderNo || "";
      const chatId = notifData.chat_id || notifData.chatId || "";
      const senderId = notifData.sender_id || notifData.senderId || "";
      const senderName = notifData.sender_name || notifData.senderName || "";

      const messagePayload = {
        tokens: fcmTokens,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: String(type),
          notificationId: String(notificationId),
          recipientId: String(uid),
          recipientRole: String(role),
          orderId: String(orderId),
          orderNo: String(orderNo),
          chatId: String(chatId),
          senderId: String(senderId),
          senderName: String(senderName),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "trucklink_notifications",
            icon: "@mipmap/ic_launcher",
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // 3. Dispatch Multicast Message via Firebase Admin SDK
      const response = await admin.messaging().sendEachForMulticast(messagePayload);
      console.log(`[Push Notification] Result: ${response.successCount} succeeded, ${response.failureCount} failed.`);

      // 4. Prune dead or invalid tokens automatically
      if (response.failureCount > 0) {
        const cleanupPromises = [];

        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errorCode = resp.error.code;
            console.log(`[Push Notification] Token delivery failed: ${errorCode} for token index ${idx}`);

            if (
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/registration-token-not-registered"
            ) {
              const docToDelete = tokenDocs[idx];
              if (docToDelete) {
                console.log(`[Push Notification] Deleting invalid token document: ${docToDelete.id}`);
                cleanupPromises.push(docToDelete.ref.delete());
              }
            }
          }
        });

        if (cleanupPromises.length > 0) {
          await Promise.all(cleanupPromises);
          console.log(`[Push Notification] Pruned ${cleanupPromises.length} stale token document(s).`);
        }
      }
    } catch (err) {
      console.error(`[Push Notification] Error sending FCM message for ${notificationId}:`, err);
    }
  }
);

/**
 * Cloud Function Trigger: Syncs Driver updates (location, rating, status, vehicle)
 * to Broker/{brokerId}/DriverNetwork/{driverId} subcollection mirror (Phase 2.11).
 */
exports.syncDriverToDriverNetwork = onDocumentUpdated(
  "Driver/{driverId}",
  async (event) => {
    const { driverId } = event.params;
    const beforeData = event.data.before ? event.data.before.data() : null;
    const afterData = event.data.after ? event.data.after.data() : null;

    if (!afterData) return;

    const brokerId = afterData.broker_id || afterData.brokerId;
    if (!brokerId) return;

    // Check if relevant fields changed
    const relevantKeys = [
      'name', 'driver_name', 'email', 'phone', 'vehicle_number', 'vehicle_type',
      'driver_rating', 'rating', 'total_trips', 'completed_trips', 'cancelled_trips',
      'availability_status', 'is_online', 'isOnline', 'driver_latitude',
      'driver_longitude', 'last_location_update', 'location'
    ];

    let hasChange = false;
    if (!beforeData) {
      hasChange = true;
    } else {
      for (const k of relevantKeys) {
        if (JSON.stringify(beforeData[k]) !== JSON.stringify(afterData[k])) {
          hasChange = true;
          break;
        }
      }
    }

    if (!hasChange) return;

    try {
      const networkRef = admin
        .firestore()
        .collection("Broker")
        .doc(brokerId)
        .collection("DriverNetwork")
        .doc(driverId);

      const networkSnap = await networkRef.get();
      if (!networkSnap.exists) {
        // Driver is not in this broker's network
        return;
      }

      const syncPayload = {
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      relevantKeys.forEach((k) => {
        if (afterData[k] !== undefined) {
          syncPayload[k] = afterData[k];
        }
      });

      await networkRef.set(syncPayload, { merge: true });
      console.log(`[DriverNetwork Sync] Successfully synced driver ${driverId} to broker ${brokerId}`);
    } catch (err) {
      console.error(`[DriverNetwork Sync] Error syncing driver ${driverId} to broker ${brokerId}:`, err);
    }
  }
);

/**
 * Cloud Function Trigger: Automatically maintains vehicle_types array on the Broker doc
 * whenever drivers join, leave, or update within Broker/{brokerId}/DriverNetwork (Phase 2.12).
 */
exports.syncBrokerVehicleTypes = onDocumentWritten(
  "Broker/{brokerId}/DriverNetwork/{driverId}",
  async (event) => {
    const { brokerId } = event.params;

    try {
      const networkSnap = await admin
        .firestore()
        .collection("Broker")
        .doc(brokerId)
        .collection("DriverNetwork")
        .get();

      const uniqueTypes = new Set();

      networkSnap.forEach((doc) => {
        const data = doc.data();
        const vType = (data.vehicle_type || data.vehicleType || "").toString().trim();
        if (vType) {
          uniqueTypes.add(vType);
        }
      });

      const vehicleTypesList = Array.from(uniqueTypes);

      await admin
        .firestore()
        .collection("Broker")
        .doc(brokerId)
        .set(
          {
            vehicle_types: vehicleTypesList,
            vehicleTypes: vehicleTypesList,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      console.log(`[Broker Vehicle Types] Updated vehicle_types for broker ${brokerId}:`, vehicleTypesList);
    } catch (err) {
      console.error(`[Broker Vehicle Types] Error updating vehicle_types for broker ${brokerId}:`, err);
    }
  }
);

