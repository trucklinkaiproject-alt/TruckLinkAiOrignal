/**
 * scripts/backfill-broker-stats.js
 *
 * Phase 5 Data Readiness Script:
 * Backfills Broker performance metrics, item type distribution, and vehicle types
 * for the AI Broker Recommendation system.
 *
 * Features:
 *   - Supports --dry-run flag to inspect updates before writing.
 *   - Recomputes total_requests, accepted_requests, completed_requests, cancelled_requests.
 *   - Calculates exact rates: acceptance_rate, completion_rate, cancellation_rate.
 *   - Aggregates item_type_counts histogram ({ Furniture: 12, Plastic: 4, ... }).
 *   - Aggregates vehicle_types / vehicleTypes from Broker's DriverNetwork.
 *   - Computes broker_rating & review_count from Broker/{id}/Reviews.
 *
 * Usage:
 *   node scripts/backfill-broker-stats.js --dry-run
 *   node scripts/backfill-broker-stats.js
 *
 * Prerequisites:
 *   - Service account key file (set GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json)
 *     OR run with Firebase default credentials.
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

const db = admin.firestore();

// Known closed / accepted / completed status categories
const ACCEPTED_STATUSES = new Set([
  'accepted',
  'driver_offer_sent',
  'accepted_by_driver',
  'in_transit',
  'in_progress',
  'arrived_at_pickup',
  'heading_to_drop',
  'completed',
  'delivered'
]);

const COMPLETED_STATUSES = new Set([
  'completed',
  'delivered'
]);

const CANCELLED_STATUSES = new Set([
  'rejected',
  'cancelled',
  'rejected_by_driver'
]);

async function runBackfill() {
  const isDryRun = process.argv.includes('--dry-run');

  console.log('====================================================');
  console.log(' TruckLink AI - Broker Stats & ML Data Backfill');
  console.log(` Mode: ${isDryRun ? 'DRY RUN (No writes)' : 'LIVE EXECUTION'}`);
  console.log('====================================================\n');

  // 1. Fetch all Brokers
  const brokersSnap = await db.collection('Broker').get();
  console.log(`Found ${brokersSnap.size} Broker document(s) in Firestore.`);

  if (brokersSnap.empty) {
    console.log('No brokers found to backfill.');
    return;
  }

  // 2. Fetch all Orders across the system
  const ordersSnap = await db.collection('Orders').get();
  console.log(`Found ${ordersSnap.size} Order document(s) in Orders collection.\n`);

  // Map orders by brokerId
  const ordersByBroker = new Map();
  ordersSnap.forEach((doc) => {
    const data = doc.data() || {};
    const brokerId = data.brokerId || data.broker_id || '';
    if (brokerId) {
      if (!ordersByBroker.has(brokerId)) {
        ordersByBroker.set(brokerId, []);
      }
      ordersByBroker.get(brokerId).push({ id: doc.id, ...data });
    }
  });

  const updates = [];

  for (const brokerDoc of brokersSnap.docs) {
    const brokerId = brokerDoc.id;
    const existing = brokerDoc.data() || {};
    const brokerName = existing.name || existing.broker_name || brokerId;

    // Gather orders for this broker (from Orders collection, and check IncomingRequests subcollection)
    let brokerOrders = ordersByBroker.get(brokerId) || [];

    // Also inspect Broker/{id}/IncomingRequests to capture any orders not mirrored in Orders
    const incomingSnap = await db.collection('Broker').doc(brokerId).collection('IncomingRequests').get();
    const existingIds = new Set(brokerOrders.map((o) => o.id));
    incomingSnap.forEach((doc) => {
      if (!existingIds.has(doc.id)) {
        brokerOrders.push({ id: doc.id, ...doc.data() });
      }
    });

    // Metric counters
    let totalRequests = brokerOrders.length;
    let acceptedRequests = 0;
    let completedRequests = 0;
    let cancelledRequests = 0;
    const itemTypeCounts = {};

    for (const order of brokerOrders) {
      const status = (order.status || 'pending').toString().toLowerCase().trim();

      if (ACCEPTED_STATUSES.has(status)) {
        acceptedRequests++;
      }
      if (COMPLETED_STATUSES.has(status)) {
        completedRequests++;
      }
      if (CANCELLED_STATUSES.has(status)) {
        cancelledRequests++;
      }

      // Track cargo item type distribution
      const rawItemType = order.itemType || order.item_type || order.cargoType || 'Other';
      const itemType = rawItemType.toString().trim() || 'Other';
      itemTypeCounts[itemType] = (itemTypeCounts[itemType] || 0) + 1;
    }

    // Rate calculations (rounded to 1 decimal place)
    const acceptanceRate = totalRequests > 0
      ? Number(((acceptedRequests / totalRequests) * 100.0).toFixed(1))
      : 0.0;
    const cancellationRate = totalRequests > 0
      ? Number(((cancelledRequests / totalRequests) * 100.0).toFixed(1))
      : 0.0;
    const completionRate = acceptedRequests > 0
      ? Number(((completedRequests / acceptedRequests) * 100.0).toFixed(1))
      : 0.0;

    // Fetch and aggregate reviews from Broker/{id}/Reviews
    let totalRating = 0;
    let reviewCount = 0;
    const reviewsSnap = await db.collection('Broker').doc(brokerId).collection('Reviews').get();
    reviewsSnap.forEach((rDoc) => {
      const rData = rDoc.data() || {};
      const r = Number(rData.rating || rData.broker_rating || 0);
      if (r > 0) {
        totalRating += r;
        reviewCount++;
      }
    });

    const brokerRating = reviewCount > 0
      ? Number((totalRating / reviewCount).toFixed(2))
      : (Number(existing.rating || existing.overall_rating || existing.broker_rating) || 5.0);

    // Fetch and aggregate vehicle types from Broker/{id}/DriverNetwork
    const networkSnap = await db.collection('Broker').doc(brokerId).collection('DriverNetwork').get();
    const vehicleTypesSet = new Set();
    networkSnap.forEach((dDoc) => {
      const dData = dDoc.data() || {};
      const vType = (dData.vehicle_type || dData.vehicleType || '').toString().trim();
      if (vType) {
        vehicleTypesSet.add(vType);
      }
    });

    // Also preserve existing vehicle types if present
    const existingVehicleTypes = existing.vehicle_types || existing.vehicleTypes || [];
    if (Array.isArray(existingVehicleTypes)) {
      existingVehicleTypes.forEach((vt) => {
        if (vt && typeof vt === 'string' && vt.trim()) vehicleTypesSet.add(vt.trim());
      });
    }

    const vehicleTypesArray = Array.from(vehicleTypesSet);

    const updatePayload = {
      total_requests: totalRequests,
      accepted_requests: acceptedRequests,
      completed_requests: completedRequests,
      cancelled_requests: cancelledRequests,
      acceptance_rate: acceptanceRate,
      cancellation_rate: cancellationRate,
      completion_rate: completionRate,
      broker_rating: brokerRating,
      rating: brokerRating,
      overall_rating: brokerRating,
      total_reviews: reviewCount,
      review_count: reviewCount,
      item_type_counts: itemTypeCounts,
      vehicle_types: vehicleTypesArray,
      vehicleTypes: vehicleTypesArray,
      stats_last_backfilled_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    updates.push({
      brokerId,
      brokerName,
      payload: updatePayload,
    });

    console.log(`[Broker: ${brokerName} (${brokerId})]`);
    console.log(`  Requests: Total=${totalRequests}, Accepted=${acceptedRequests}, Completed=${completedRequests}, Cancelled=${cancelledRequests}`);
    console.log(`  Rates: Acceptance=${acceptanceRate}%, Completion=${completionRate}%, Cancellation=${cancellationRate}%`);
    console.log(`  Rating: ${brokerRating} (${reviewCount} reviews)`);
    console.log(`  Vehicles: [${vehicleTypesArray.join(', ')}]`);
    console.log(`  Item Distribution: ${JSON.stringify(itemTypeCounts)}\n`);
  }

  if (isDryRun) {
    console.log(`[DRY RUN COMPLETE] Evaluated ${updates.length} broker(s). No writes were performed.`);
    console.log('Run without --dry-run to commit these updates to Firestore.');
    return;
  }

  // Commit updates using Firestore batched writes (up to 500 per batch)
  console.log(`Committing updates for ${updates.length} broker(s) to Firestore...`);
  const batch = db.batch();
  for (const { brokerId, payload } of updates) {
    const ref = db.collection('Broker').doc(brokerId);
    batch.set(ref, payload, { merge: true });
  }

  await batch.commit();
  console.log(`[SUCCESS] Successfully backfilled ${updates.length} broker(s) in Firestore!`);
}

runBackfill().catch((err) => {
  console.error('[ERROR] Backfill script failed:', err);
  process.exit(1);
});
