import {
  collection,
  collectionGroup,
  doc,
  getDocs,
  getDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  setDoc,
  writeBatch,
  onSnapshot,
  query,
  orderBy,
  limit,
  serverTimestamp,
  getCountFromServer,
  QueryConstraint
} from 'firebase/firestore';
import { db } from './firebase';
import {
  UserProfile,
  BrokerProfile,
  DriverProfile,
  OrderItem,
  UserRequest,
  ChatThread,
  AuditLog,
  ReviewRating,
  DriverOfferRecord,
  SystemNotification
} from '../types/models';

// In-memory stakeholder cache accessible across services
export let cachedUsers: Record<string, UserProfile> = {};
export let cachedBrokers: Record<string, BrokerProfile> = {};
export let cachedDrivers: Record<string, DriverProfile> = {};

export const formatPKR = (val: number | string | undefined | null): string => {
  if (val === undefined || val === null || val === '') return 'PKR —';
  const num = typeof val === 'number' ? val : parseFloat(String(val).replace(/[^0-9.-]+/g, ''));
  if (isNaN(num)) return `PKR ${val}`;
  return `PKR ${num.toLocaleString('en-PK')}`;
};

/**
 * Fast server-side document count query using getCountFromServer.
 * Avoids downloading full documents or payload bytes.
 */
export const getCollectionCount = async (collectionName: string): Promise<number> => {
  try {
    const coll = collection(db, collectionName);
    const snapshot = await getCountFromServer(coll);
    return snapshot.data().count;
  } catch (err) {
    console.warn(`[getCollectionCount] Failed to count ${collectionName}:`, err);
    return 0;
  }
};

// Generic audit logger
export const logAdminAction = async (
  adminId: string,
  adminEmail: string,
  action: string,
  targetCollection: string,
  targetId: string,
  details: Record<string, any> = {}
) => {
  try {
    const auditRef = collection(db, 'AuditLogs');
    await addDoc(auditRef, {
      adminId,
      adminEmail,
      action,
      targetCollection,
      targetId,
      timestamp: serverTimestamp(),
      details,
    });
  } catch (err) {
    console.warn('Failed to record audit log:', err);
  }
};

// ================= SHARED USER SUBSCRIPTION =================
let userSubscribers: ((users: UserProfile[]) => void)[] = [];
let userSnapshotUnsub: (() => void) | null = null;
let lastUsersCache: UserProfile[] | null = null;

export const subscribeUsers = (callback: (users: UserProfile[]) => void) => {
  userSubscribers.push(callback);
  if (lastUsersCache) {
    callback(lastUsersCache);
  }
  if (!userSnapshotUnsub) {
    const usersRef = collection(db, 'User');
    userSnapshotUnsub = onSnapshot(
      usersRef,
      (snapshot) => {
        const list: UserProfile[] = [];
        cachedUsers = {};
        snapshot.forEach((docSnap) => {
          const item = { id: docSnap.id, ...docSnap.data() } as UserProfile;
          list.push(item);
          cachedUsers[docSnap.id] = item;
        });
        lastUsersCache = list;
        userSubscribers.forEach((cb) => cb(list));
        if (allRequestsSubscribers.length > 0) emitAllRequests();
      },
      (err) => {
        console.warn('[subscribeUsers] Snapshot error:', err);
      }
    );
  }
  return () => {
    userSubscribers = userSubscribers.filter((cb) => cb !== callback);
    if (userSubscribers.length === 0 && allRequestsSubscribers.length === 0 && userSnapshotUnsub) {
      userSnapshotUnsub();
      userSnapshotUnsub = null;
    }
  };
};

export const updateUserStatus = async (
  userId: string,
  status: 'active' | 'blocked',
  adminId: string,
  adminEmail: string
) => {
  const userRef = doc(db, 'User', userId);
  await updateDoc(userRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction(adminId, adminEmail, `USER_STATUS_${status.toUpperCase()}`, 'User', userId);
};

const callDeleteUserProfile = async (uid: string, role: 'User' | 'Broker' | 'Driver'): Promise<boolean> => {
  try {
    const { getFunctions, httpsCallable } = await import('firebase/functions');
    const functions = getFunctions();
    const deleteFn = httpsCallable<{ uid: string; role: string }, { success: boolean }>(
      functions,
      'deleteUserProfile'
    );
    await deleteFn({ uid, role });
    return true;
  } catch (err) {
    console.warn(`[deleteUserProfile] Cloud Function call failed, falling back to direct delete:`, err);
    return false;
  }
};

export const deleteUserDoc = async (userId: string, adminId: string, adminEmail: string) => {
  const success = await callDeleteUserProfile(userId, 'User');
  if (!success) {
    const userRef = doc(db, 'User', userId);
    await deleteDoc(userRef);
    await logAdminAction(adminId, adminEmail, 'USER_DELETED', 'User', userId);
  }
};

// ================= SHARED BROKER SUBSCRIPTION =================
let brokerSubscribers: ((brokers: BrokerProfile[]) => void)[] = [];
let brokerSnapshotUnsub: (() => void) | null = null;
let lastBrokersCache: BrokerProfile[] | null = null;

export const subscribeBrokers = (callback: (brokers: BrokerProfile[]) => void) => {
  brokerSubscribers.push(callback);
  if (lastBrokersCache) {
    callback(lastBrokersCache);
  }
  if (!brokerSnapshotUnsub) {
    const brokersRef = collection(db, 'Broker');
    brokerSnapshotUnsub = onSnapshot(
      brokersRef,
      (snapshot) => {
        const list: BrokerProfile[] = [];
        cachedBrokers = {};
        snapshot.forEach((docSnap) => {
          const item = { id: docSnap.id, ...docSnap.data() } as BrokerProfile;
          list.push(item);
          cachedBrokers[docSnap.id] = item;
        });
        lastBrokersCache = list;
        brokerSubscribers.forEach((cb) => cb(list));
        if (allRequestsSubscribers.length > 0) emitAllRequests();
      },
      (err) => {
        console.warn('[subscribeBrokers] Snapshot error:', err);
      }
    );
  }
  return () => {
    brokerSubscribers = brokerSubscribers.filter((cb) => cb !== callback);
    if (brokerSubscribers.length === 0 && allRequestsSubscribers.length === 0 && brokerSnapshotUnsub) {
      brokerSnapshotUnsub();
      brokerSnapshotUnsub = null;
    }
  };
};

export const updateBrokerStatus = async (
  brokerId: string,
  status: 'active' | 'blocked',
  adminId: string,
  adminEmail: string
) => {
  const brokerRef = doc(db, 'Broker', brokerId);
  await updateDoc(brokerRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction(adminId, adminEmail, `BROKER_STATUS_${status.toUpperCase()}`, 'Broker', brokerId);
};

export const verifyBroker = async (brokerId: string, isVerified: boolean, adminId: string, adminEmail: string) => {
  const brokerRef = doc(db, 'Broker', brokerId);
  await updateDoc(brokerRef, { isVerified, updatedAt: serverTimestamp() });
  await logAdminAction(adminId, adminEmail, isVerified ? 'BROKER_VERIFIED' : 'BROKER_UNVERIFIED', 'Broker', brokerId);
};

export const deleteBrokerDoc = async (brokerId: string, adminId: string, adminEmail: string) => {
  const success = await callDeleteUserProfile(brokerId, 'Broker');
  if (!success) {
    const brokerRef = doc(db, 'Broker', brokerId);
    await deleteDoc(brokerRef);
    await logAdminAction(adminId, adminEmail, 'BROKER_DELETED', 'Broker', brokerId);
  }
};

// ================= DRIVER OPERATIONS =================
export const normalizeDriver = (docId: string, data: Record<string, any>): DriverProfile => {
  const vehicleNumber = (
    data.vehicle_number ||
    data.vehicleNumber ||
    data.truck_no ||
    data.truckNumber ||
    data.registrationNumber ||
    data.registration_number ||
    data.vehicle?.vehicle_number ||
    data.vehicle?.vehicleNumber ||
    ''
  ).toString().trim();

  const vehicleType = (
    data.vehicle_type ||
    data.vehicleType ||
    data.truck_type ||
    data.truckType ||
    data.vehicle?.vehicle_type ||
    data.vehicle?.vehicleType ||
    ''
  ).toString().trim();

  const name = data.name || data.fullName || data.driver_name || data.driverName || 'Driver';
  const phone = data.phone || data.phoneNumber || data.driver_phone || '';
  const email = data.email || '';
  const brokerId = data.broker_id || data.brokerId || data.created_by_broker_id || data.active_request_broker_id || data.activeRequestBrokerId || '';
  const brokerName = data.broker_name || data.brokerName || data.active_request_broker_name || data.activeRequestBrokerName || '';
  const rawAvail = (data.availability_status || data.availabilityStatus || data.status || 'online').toString().toLowerCase();
  const isAvailable = data.vehicle_available ?? data.vehicleAvailable ?? (rawAvail === 'online');
  const rating = data.driver_rating ?? data.driverRating ?? data.rating ?? 5.0;
  const status = data.status || rawAvail || 'active';

  return {
    id: docId,
    uid: data.uid || data.driver_id || docId,
    name,
    fullName: name,
    email,
    phone,
    phoneNumber: phone,
    vehicleNumber,
    vehicle_number: vehicleNumber,
    vehicleType,
    vehicle_type: vehicleType,
    vehicleAvailable: isAvailable,
    vehicle_available: isAvailable,
    isAvailable,
    availabilityStatus: rawAvail,
    availability_status: rawAvail,
    status,
    brokerId,
    broker_id: brokerId,
    brokerName,
    broker_name: brokerName,
    rating: Number(rating),
    driverRating: Number(rating),
    driver_rating: Number(rating),
    totalTrips: data.total_trips || data.totalTrips || 0,
    completedTrips: data.completed_trips || data.completedTrips || 0,
    cancelledTrips: data.cancelled_trips || data.cancelledTrips || 0,
    driverLatitude: (data.driver_latitude ?? data.driverLatitude ?? data.latitude) as number | undefined,
    driverLongitude: (data.driver_longitude ?? data.driverLongitude ?? data.longitude) as number | undefined,
    ...data,
  };
};

// ================= SHARED DRIVER SUBSCRIPTION =================
let driverSubscribers: ((drivers: DriverProfile[]) => void)[] = [];
let driverSnapshotUnsub: (() => void) | null = null;
let lastDriversCache: DriverProfile[] | null = null;

export const subscribeDrivers = (callback: (drivers: DriverProfile[]) => void) => {
  driverSubscribers.push(callback);
  if (lastDriversCache) {
    callback(lastDriversCache);
  }
  if (!driverSnapshotUnsub) {
    const driversRef = collection(db, 'Driver');
    driverSnapshotUnsub = onSnapshot(
      driversRef,
      (snapshot) => {
        const list: DriverProfile[] = [];
        cachedDrivers = {};
        snapshot.forEach((docSnap) => {
          const item = normalizeDriver(docSnap.id, docSnap.data());
          list.push(item);
          cachedDrivers[docSnap.id] = item;
        });
        lastDriversCache = list;
        driverSubscribers.forEach((cb) => cb(list));
        if (allRequestsSubscribers.length > 0) emitAllRequests();
      },
      (err) => {
        console.warn('[subscribeDrivers] Snapshot error:', err);
      }
    );
  }
  return () => {
    driverSubscribers = driverSubscribers.filter((cb) => cb !== callback);
    if (driverSubscribers.length === 0 && allRequestsSubscribers.length === 0 && driverSnapshotUnsub) {
      driverSnapshotUnsub();
      driverSnapshotUnsub = null;
    }
  };
};

export const updateDriverStatus = async (
  driverId: string,
  status: 'active' | 'blocked' | 'on-trip',
  adminId: string,
  adminEmail: string
) => {
  const driverRef = doc(db, 'Driver', driverId);
  await updateDoc(driverRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction(adminId, adminEmail, `DRIVER_STATUS_${status.toUpperCase()}`, 'Driver', driverId);
};

export const deleteDriverDoc = async (driverId: string, adminId: string, adminEmail: string) => {
  const success = await callDeleteUserProfile(driverId, 'Driver');
  if (!success) {
    const driverRef = doc(db, 'Driver', driverId);
    await deleteDoc(driverRef);
    await logAdminAction(adminId, adminEmail, 'DRIVER_DELETED', 'Driver', driverId);
  }
};

// ================= ORDERS OPERATIONS =================
export const subscribeOrders = (callback: (orders: OrderItem[]) => void) => {
  const ordersRef = collection(db, 'Orders');
  return onSnapshot(ordersRef, (snapshot) => {
    const list: OrderItem[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as OrderItem);
    });
    callback(list);
  });
};

export const updateOrderStatus = async (
  orderId: string,
  status: string,
  adminId: string,
  adminEmail: string
) => {
  const orderRef = doc(db, 'Orders', orderId);
  await updateDoc(orderRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction(adminId, adminEmail, `ORDER_STATUS_${status.toUpperCase()}`, 'Orders', orderId);
};

// ================= REQUESTS & LIFECYCLE (Real-time Collection Group & Cache) =================
export const normalizeRequest = (
  docId: string,
  data: Record<string, any>,
  usersMap: Record<string, UserProfile> = {},
  brokersMap: Record<string, BrokerProfile> = {},
  driversMap: Record<string, DriverProfile> = {}
): UserRequest => {
  const userUid = (data.userUid || data.user_uid || data.userId || data.shipperId || '').toString().trim();
  const brokerId = (data.brokerId || data.broker_id || '').toString().trim();
  const driverId = (
    data.assigned_driver_id ||
    data.assignedDriverId ||
    data.driver_id ||
    data.driverId ||
    data.driverUid ||
    ''
  ).toString().trim();

  const user = usersMap[userUid];
  const broker = brokersMap[brokerId];
  const driver = driversMap[driverId];

  const rawOrderNo = (data.orderNo || data.order_no || data.orderId || data.order_id || docId).toString();
  const numericMatch = rawOrderNo.match(/\d+/);
  const numericOrderNo = numericMatch ? parseInt(numericMatch[0], 10) : 999999;

  const itemType = data.itemType || data.item_type || data.cargoType || 'General Freight';
  const pickupComp = (data.pickupComp || data.pickup_comp || '').toString().trim();
  const pickupCity = (data.pickupCity || data.pickup_city || '').toString().trim();
  let pickupLocation = data.pickupLocation || '';
  if (!pickupLocation) {
    if (pickupComp && pickupCity) {
      pickupLocation = pickupComp.toLowerCase().includes(pickupCity.toLowerCase())
        ? pickupComp
        : `${pickupComp}, ${pickupCity}`;
    } else {
      pickupLocation = pickupComp || pickupCity || 'Pickup location not specified';
    }
  }

  const dropComp = (data.dropComp || data.drop_comp || '').toString().trim();
  const dropCity = (data.dropCity || data.drop_city || '').toString().trim();
  let dropoffLocation = data.dropoffLocation || '';
  if (!dropoffLocation) {
    if (dropComp && dropCity) {
      dropoffLocation = dropComp.toLowerCase().includes(dropCity.toLowerCase())
        ? dropComp
        : `${dropComp}, ${dropCity}`;
    } else {
      dropoffLocation = dropComp || dropCity || 'Drop-off location not specified';
    }
  }

  const pickupLat = Number(data.pickupLat ?? data.pickup_lat ?? data.pickupLatitude ?? 0);
  const pickupLng = Number(data.pickupLng ?? data.pickup_lng ?? data.pickupLongitude ?? 0);
  const dropLat = Number(data.dropLat ?? data.drop_lat ?? data.dropLatitude ?? 0);
  const dropLng = Number(data.dropLng ?? data.drop_lng ?? data.dropLongitude ?? 0);

  const statusRaw = (data.status || 'Pending').toString().trim();
  const statusLower = statusRaw.toLowerCase();

  // Fare resolution based on real business logic
  const rawAcceptedFare =
    data.accepted_fare ??
    data.acceptedFare ??
    data.customer_fare ??
    data.customerFare;
  const rawOfferedFare = data.brokerOffer ?? data.quoteAmount ?? data.quote_amount;
  const rawAssignedFare = data.assigned_fare ?? data.driver_fare ?? data.driverFare ?? data.broker_driver_fare;
  const rawGenericFare = data.fare ?? data.price ?? data.amount;

  let finalFare: number | null = null;
  let fareStatus: 'finalized' | 'offered' | 'pending' = 'pending';

  const isClosedDealStatus = [
    'accepted',
    'driver_offer_sent',
    'accepted_by_driver',
    'in_transit',
    'heading_to_drop',
    'completed'
  ].includes(statusLower);

  if (rawAcceptedFare !== undefined && rawAcceptedFare !== null && Number(rawAcceptedFare) > 0) {
    finalFare = Number(rawAcceptedFare);
    fareStatus = 'finalized';
  } else if (isClosedDealStatus && rawGenericFare !== undefined && rawGenericFare !== null && Number(rawGenericFare) > 0) {
    finalFare = Number(rawGenericFare);
    fareStatus = 'finalized';
  } else if (rawOfferedFare !== undefined && rawOfferedFare !== null && Number(rawOfferedFare) > 0) {
    finalFare = Number(rawOfferedFare);
    fareStatus = 'offered';
  } else if (rawGenericFare !== undefined && rawGenericFare !== null && Number(rawGenericFare) > 0) {
    finalFare = Number(rawGenericFare);
    fareStatus = 'offered';
  }

  const userName =
    user?.name ||
    user?.fullName ||
    data.userName ||
    data.user_name ||
    (userUid ? `Shipper (${userUid.substring(0, 6)})` : 'Shipper');
  const userPhone = user?.phone || user?.phoneNumber || data.userPhone || data.user_phone || '';
  const userEmail = user?.email || data.userEmail || '';

  const brokerName =
    broker?.name ||
    broker?.fullName ||
    broker?.companyName ||
    data.brokerName ||
    data.broker_name ||
    (brokerId ? `Broker (${brokerId.substring(0, 6)})` : 'Not Assigned');
  const brokerPhone = broker?.phone || data.brokerPhone || data.broker_phone || '';
  const brokerRating = Number(broker?.rating || data.brokerRating || 0);

  const driverName =
    driver?.name ||
    driver?.fullName ||
    data.assigned_driver_name ||
    data.driverName ||
    data.driver_name ||
    (driverId ? `Driver (${driverId.substring(0, 6)})` : 'Not Assigned');
  const driverPhone = driver?.phone || data.assigned_driver_phone || data.driverPhone || data.driver_phone || '';
  const driverVehicleType =
    driver?.vehicle_type ||
    driver?.vehicleType ||
    data.vehicle_type ||
    data.vehicleType ||
    '';
  const driverVehicleNumber =
    driver?.vehicle_number ||
    driver?.vehicleNumber ||
    data.vehicle_number ||
    data.vehicleNumber ||
    '';

  return {
    id: docId,
    orderId: data.orderId || data.order_id || docId,
    orderNo: rawOrderNo,
    numericOrderNo,
    userUid,
    userId: userUid,
    userName,
    userPhone,
    userEmail,
    itemType,
    cargoType: itemType,
    weight: data.weight || '—',
    quantity: data.quantity || '—',
    vehicleType: data.vehicleType || data.vehicle_type || '',
    additionalInfo: data.additionalInfo || data.additional_info || data.description || '',
    pickupLocation,
    pickupComp,
    pickupCity,
    pickupLat,
    pickupLng,
    dropoffLocation,
    dropComp,
    dropCity,
    dropLat,
    dropLng,
    brokerId,
    brokerName,
    brokerPhone,
    brokerRating,
    brokerOffer: rawOfferedFare ? Number(rawOfferedFare) : undefined,
    quoteAmount: rawOfferedFare ? Number(rawOfferedFare) : undefined,
    assigned_driver_id: driverId,
    driverId,
    assigned_driver_name: driverName,
    driverName,
    assigned_driver_phone: driverPhone,
    driverPhone,
    driverVehicleType,
    driverVehicleNumber,
    assigned_fare: rawAssignedFare ? Number(rawAssignedFare) : undefined,
    driver_fare: rawAssignedFare ? Number(rawAssignedFare) : undefined,
    customer_fare: rawAcceptedFare ? Number(rawAcceptedFare) : undefined,
    accepted_fare: rawAcceptedFare ? Number(rawAcceptedFare) : undefined,
    fare: rawGenericFare ? Number(rawGenericFare) : undefined,
    finalFare,
    fareStatus,
    status: statusRaw,
    date: data.date || '',
    createdAt: data.createdAt || data.created_at || data.date || null,
    quote_submitted_at: data.quote_submitted_at || null,
    accepted_at: data.accepted_at || null,
    rejected_at: data.rejected_at || null,
    ride_started_at: data.ride_started_at || null,
    cargo_picked_up_at: data.cargo_picked_up_at || null,
    arrived_at_drop_at: data.arrived_at_drop_at || null,
    completed_at: data.completed_at || null,
    updated_at: data.updated_at || data.updatedAt || null,
    ride_phase: data.ride_phase || data.ridePhase || '',
    rejection_reason: data.rejection_reason || data.reason || data.rejectionReason || '',
    rejection_actor: data.rejection_actor || data.rejected_by || data.cancelled_by || '',
    delivery_duration_seconds: data.delivery_duration_seconds || undefined,
    ...data,
  };
};

// ================= SHARED ALL REQUESTS SUBSCRIPTION =================
let allRequestsSubscribers: ((requests: UserRequest[]) => void)[] = [];
let reqGroupUnsub: (() => void) | null = null;
let ordersUnsub: (() => void) | null = null;
let rawRequestsMap: Map<string, { id: string; data: Record<string, any> }> = new Map();
let lastRequestsCache: UserRequest[] | null = null;
let activeUsersUnsubHook: (() => void) | null = null;
let activeBrokersUnsubHook: (() => void) | null = null;
let activeDriversUnsubHook: (() => void) | null = null;

const emitAllRequests = () => {
  const list: UserRequest[] = [];
  rawRequestsMap.forEach((entry) => {
    list.push(normalizeRequest(entry.id, entry.data, cachedUsers, cachedBrokers, cachedDrivers));
  });

  // Default sorting: Order No sequence ascending (1, 2, 3... 10)
  list.sort((a, b) => {
    if (a.numericOrderNo !== b.numericOrderNo) {
      return (a.numericOrderNo || 0) - (b.numericOrderNo || 0);
    }
    return (a.orderNo || '').localeCompare(b.orderNo || '');
  });

  lastRequestsCache = list;
  allRequestsSubscribers.forEach((cb) => cb(list));
};

export const subscribeAllRequests = (callback: (requests: UserRequest[]) => void) => {
  allRequestsSubscribers.push(callback);
  if (lastRequestsCache) {
    callback(lastRequestsCache);
  }

  // Ensure shared stakeholder listeners are active
  if (!activeUsersUnsubHook) activeUsersUnsubHook = subscribeUsers(() => {});
  if (!activeBrokersUnsubHook) activeBrokersUnsubHook = subscribeBrokers(() => {});
  if (!activeDriversUnsubHook) activeDriversUnsubHook = subscribeDrivers(() => {});

  if (!reqGroupUnsub) {
    const reqGroupRef = collectionGroup(db, 'Requests');
    reqGroupUnsub = onSnapshot(
      reqGroupRef,
      (snapshot) => {
        snapshot.forEach((docSnap) => {
          const existing = rawRequestsMap.get(docSnap.id);
          rawRequestsMap.set(docSnap.id, {
            id: docSnap.id,
            data: existing ? { ...existing.data, ...docSnap.data() } : docSnap.data(),
          });
        });
        emitAllRequests();
      },
      (err) => {
        console.warn('CollectionGroup listener error, falling back to manual load:', err);
      }
    );
  }

  if (!ordersUnsub) {
    ordersUnsub = onSnapshot(collection(db, 'Orders'), (snapshot) => {
      snapshot.forEach((docSnap) => {
        const existing = rawRequestsMap.get(docSnap.id);
        if (existing) {
          rawRequestsMap.set(docSnap.id, {
            id: docSnap.id,
            data: { ...existing.data, ...docSnap.data() },
          });
        }
      });
      emitAllRequests();
    });
  }

  return () => {
    allRequestsSubscribers = allRequestsSubscribers.filter((cb) => cb !== callback);

    if (allRequestsSubscribers.length === 0) {
      if (reqGroupUnsub) {
        reqGroupUnsub();
        reqGroupUnsub = null;
      }
      if (ordersUnsub) {
        ordersUnsub();
        ordersUnsub = null;
      }
      if (activeUsersUnsubHook) {
        activeUsersUnsubHook();
        activeUsersUnsubHook = null;
      }
      if (activeBrokersUnsubHook) {
        activeBrokersUnsubHook();
        activeBrokersUnsubHook = null;
      }
      if (activeDriversUnsubHook) {
        activeDriversUnsubHook();
        activeDriversUnsubHook = null;
      }
      rawRequestsMap.clear();
      lastRequestsCache = null;
    }
  };
};

export const fetchAllRequests = async (): Promise<UserRequest[]> => {
  const usersRef = collection(db, 'User');
  const brokersRef = collection(db, 'Broker');
  const driversRef = collection(db, 'Driver');

  const [userDocs, brokerDocs, driverDocs] = await Promise.all([
    getDocs(usersRef),
    getDocs(brokersRef),
    getDocs(driversRef),
  ]);

  const usersMap: Record<string, UserProfile> = {};
  userDocs.forEach((d) => {
    usersMap[d.id] = { id: d.id, ...d.data() } as UserProfile;
  });

  const brokersMap: Record<string, BrokerProfile> = {};
  brokerDocs.forEach((d) => {
    brokersMap[d.id] = { id: d.id, ...d.data() } as BrokerProfile;
  });

  const driversMap: Record<string, DriverProfile> = {};
  driverDocs.forEach((d) => {
    driversMap[d.id] = normalizeDriver(d.id, d.data());
  });

  const requestsMap = new Map<string, UserRequest>();

  for (const userDoc of userDocs.docs) {
    const requestsSubRef = collection(db, 'User', userDoc.id, 'Requests');
    const reqSnap = await getDocs(requestsSubRef);
    reqSnap.forEach((docSnap) => {
      const norm = normalizeRequest(docSnap.id, docSnap.data(), usersMap, brokersMap, driversMap);
      requestsMap.set(docSnap.id, norm);
    });
  }

  const list = Array.from(requestsMap.values());
  list.sort((a, b) => (a.numericOrderNo || 0) - (b.numericOrderNo || 0));
  return list;
};

// ================= DRIVER OFFERS SUBCOLLECTION =================
export const subscribeOrderDriverOffers = (
  orderId: string,
  callback: (offers: DriverOfferRecord[]) => void
) => {
  if (!orderId) {
    callback([]);
    return () => {};
  }
  const offersRef = collection(db, 'Orders', orderId, 'DriverOffers');
  const q = query(offersRef, orderBy('created_at', 'asc'));
  return onSnapshot(
    q,
    (snapshot) => {
      const list: DriverOfferRecord[] = [];
      snapshot.forEach((docSnap) => {
        const d = docSnap.data();
        list.push({
          id: docSnap.id,
          offer_id: d.offer_id || docSnap.id,
          order_id: d.order_id || orderId,
          order_no: d.order_no,
          broker_id: d.broker_id,
          broker_name: d.broker_name,
          driver_id: d.driver_id,
          driver_name: d.driver_name,
          driver_phone: d.driver_phone,
          vehicle_type: d.vehicle_type,
          vehicle_number: d.vehicle_number,
          fare: Number(d.fare) || 0,
          status: d.status || 'pending',
          created_at: d.created_at || d.createdAt || null,
          accepted_at: d.accepted_at || null,
          updated_at: d.updated_at || null,
          rejection_reason: d.rejection_reason || d.reason || '',
          reason: d.rejection_reason || d.reason || '',
          ...d,
        });
      });
      callback(list);
    },
    (err) => {
      console.warn(`Fallback querying driver offers for order ${orderId}:`, err);
      getDocs(offersRef)
        .then((snap) => {
          const list = snap.docs.map((docSnap) => {
            const d = docSnap.data();
            return {
              id: docSnap.id,
              offer_id: d.offer_id || docSnap.id,
              order_id: d.order_id || orderId,
              order_no: d.order_no,
              broker_id: d.broker_id,
              broker_name: d.broker_name,
              driver_id: d.driver_id,
              driver_name: d.driver_name,
              driver_phone: d.driver_phone,
              vehicle_type: d.vehicle_type,
              vehicle_number: d.vehicle_number,
              fare: Number(d.fare) || 0,
              status: d.status || 'pending',
              created_at: d.created_at || d.createdAt || null,
              accepted_at: d.accepted_at || null,
              updated_at: d.updated_at || null,
              rejection_reason: d.rejection_reason || d.reason || '',
              reason: d.rejection_reason || d.reason || '',
              ...d,
            } as DriverOfferRecord;
          });
          callback(list);
        })
        .catch(() => callback([]));
    }
  );
};

// ================= CHATS =================
export const subscribeChats = (callback: (chats: ChatThread[]) => void) => {
  const chatsRef = collection(db, 'chats');
  return onSnapshot(chatsRef, (snapshot) => {
    const list: ChatThread[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as ChatThread);
    });
    callback(list);
  });
};

export const fetchChatMessages = async (chatId: string) => {
  const messagesRef = collection(db, 'chats', chatId, 'messages');
  const q = query(messagesRef, orderBy('timestamp', 'asc'), limit(150));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
};

export const subscribeChatMessages = (chatId: string, callback: (messages: any[]) => void) => {
  const messagesRef = collection(db, 'chats', chatId, 'messages');
  const q = query(messagesRef, orderBy('timestamp', 'asc'), limit(150));
  return onSnapshot(q, (snapshot) => {
    const list = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    callback(list);
  }, (err) => {
    console.warn(`Error subscribing to messages for chat ${chatId}:`, err);
  });
};

// ================= AUDIT LOGS =================
export const subscribeAuditLogs = (callback: (logs: AuditLog[]) => void) => {
  const logsRef = collection(db, 'AuditLogs');
  const q = query(logsRef, orderBy('timestamp', 'desc'), limit(100));
  return onSnapshot(q, (snapshot) => {
    const list: AuditLog[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as AuditLog);
    });
    callback(list);
  });
};

// ================= RATINGS & REVIEWS =================
export const subscribeAllReviews = (callback: (reviews: ReviewRating[]) => void) => {
  const reviewsMap = new Map<string, ReviewRating>();

  const emit = () => {
    const list = Array.from(reviewsMap.values());
    list.sort((a, b) => {
      const timeA = a.created_at?.toMillis ? a.created_at.toMillis() : (a.createdAt?.toMillis ? a.createdAt.toMillis() : 0);
      const timeB = b.created_at?.toMillis ? b.created_at.toMillis() : (b.createdAt?.toMillis ? b.createdAt.toMillis() : 0);
      return timeB - timeA;
    });
    callback(list);
  };

  const processDoc = (id: string, data: any) => {
    const revieweeId = data.reviewee_id || data.targetId || '';
    const revieweeRole = (data.reviewee_role || data.targetType || 'broker').toLowerCase();
    const reviewerId = data.reviewer_id || data.reviewerId || '';
    const reviewerRole = (data.reviewer_role || 'user').toLowerCase();
    
    // Resolve reviewee display name if not present
    let revieweeName = data.reviewee_name || data.targetName || '';
    if (!revieweeName) {
      if (revieweeRole === 'broker' && cachedBrokers[revieweeId]) {
        revieweeName = cachedBrokers[revieweeId].companyName || cachedBrokers[revieweeId].name;
      } else if (revieweeRole === 'driver' && cachedDrivers[revieweeId]) {
        revieweeName = cachedDrivers[revieweeId].name;
      }
    }

    // Resolve reviewer display name if not present
    let reviewerName = data.reviewer_name || data.reviewerName || '';
    if (!reviewerName) {
      if (reviewerRole === 'user' && cachedUsers[reviewerId]) {
        reviewerName = cachedUsers[reviewerId].name;
      } else if (reviewerRole === 'broker' && cachedBrokers[reviewerId]) {
        reviewerName = cachedBrokers[reviewerId].companyName || cachedBrokers[reviewerId].name;
      }
    }

    const item: ReviewRating = {
      id,
      review_id: data.review_id || id,
      order_id: data.order_id || data.orderId || '',
      orderNo: data.orderNo || data.order_no || '',
      reviewer_id: reviewerId,
      reviewer_name: reviewerName || 'Verified Shipper',
      reviewer_role: reviewerRole,
      reviewee_id: revieweeId,
      reviewee_name: revieweeName || (revieweeRole === 'driver' ? 'Driver Partner' : 'Freight Broker'),
      reviewee_role: revieweeRole,
      targetType: revieweeRole === 'driver' ? 'driver' : 'broker',
      targetId: revieweeId,
      rating: Number(data.rating) || 0,
      comment: data.comment || data.reviewText || '',
      created_at: data.created_at || data.createdAt || null,
      createdAt: data.created_at || data.createdAt || null,
      ...data,
    };
    reviewsMap.set(id, item);
  };

  // 1. Listen to root Reviews collection
  const unsubRoot = onSnapshot(collection(db, 'Reviews'), (snapshot) => {
    snapshot.forEach((d) => processDoc(d.id, d.data()));
    emit();
  }, (err) => console.warn('Reviews root collection listener:', err));

  // 2. Listen to collectionGroup('Reviews') to capture any subcollection reviews
  const unsubGroup = onSnapshot(collectionGroup(db, 'Reviews'), (snapshot) => {
    snapshot.forEach((d) => processDoc(d.id, d.data()));
    emit();
  }, (err) => console.warn('Reviews collectionGroup listener:', err));

  return () => {
    unsubRoot();
    unsubGroup();
  };
};

export const deleteReviewDoc = async (
  review: ReviewRating,
  adminEmail: string
) => {
  const batch = writeBatch(db);

  // 1. Delete from root Reviews collection
  const rootRef = doc(db, 'Reviews', review.id);
  batch.delete(rootRef);

  // 2. Delete from subcollection if target is known
  if (review.reviewee_id) {
    if (review.reviewee_role === 'driver' || review.targetType === 'driver') {
      const driverRevRef = doc(db, 'Driver', review.reviewee_id, 'Reviews', review.id);
      batch.delete(driverRevRef);
    } else {
      const brokerRevRef = doc(db, 'Broker', review.reviewee_id, 'Reviews', review.id);
      batch.delete(brokerRevRef);
    }
  }

  await batch.commit();

  await logAdminAction('admin', adminEmail, 'REVIEW_DELETED', 'Reviews', review.id, {
    reviewer: review.reviewer_name,
    reviewee: review.reviewee_name,
    rating: review.rating,
  });
};

export const updateReviewDoc = async (
  review: ReviewRating,
  newRating: number,
  newComment: string,
  adminEmail: string
) => {
  const batch = writeBatch(db);
  const updatePayload = {
    rating: newRating,
    comment: newComment,
    updated_at: serverTimestamp(),
  };

  // 1. Update root Reviews collection
  const rootRef = doc(db, 'Reviews', review.id);
  batch.update(rootRef, updatePayload);

  // 2. Update subcollection
  if (review.reviewee_id) {
    if (review.reviewee_role === 'driver' || review.targetType === 'driver') {
      const driverRevRef = doc(db, 'Driver', review.reviewee_id, 'Reviews', review.id);
      batch.update(driverRevRef, updatePayload);
    } else {
      const brokerRevRef = doc(db, 'Broker', review.reviewee_id, 'Reviews', review.id);
      batch.update(brokerRevRef, updatePayload);
    }
  }

  await batch.commit();

  await logAdminAction('admin', adminEmail, 'REVIEW_MODERATED', 'Reviews', review.id, {
    oldRating: review.rating,
    newRating,
    newComment,
  });
};

// ================= SYSTEM NOTIFICATIONS & FCM PUSH =================
/**
 * sendBroadcastNotification
 * Delegates to the server-side Cloud Function to avoid broad client write rights.
 * The Cloud Function handles batched writes and audit logging.
 */
export const sendBroadcastNotification = async (
  title: string,
  message: string,
  targetAudience: 'all' | 'users' | 'brokers' | 'drivers',
  _adminId: string,
  _adminEmail: string
): Promise<string> => {
  // Delegate entirely to the server-side Cloud Function.
  // The function handles batched Firestore writes, FCM fan-out, and audit logging.
  const { getFunctions, httpsCallable } = await import('firebase/functions');
  const functions = getFunctions();
  const broadcastFn = httpsCallable<
    { title: string; message: string; targetAudience: string },
    { success: boolean; notificationId: string; totalSent: number }
  >(functions, 'sendBroadcastNotification');

  const result = await broadcastFn({ title, message, targetAudience });
  return result.data.notificationId;
};

export const subscribeNotifications = (callback: (notifs: SystemNotification[]) => void) => {
  const notificationsRef = collection(db, 'SystemNotifications');
  const q = query(notificationsRef, orderBy('sentAt', 'desc'), limit(50));
  return onSnapshot(q, (snapshot) => {
    const list: SystemNotification[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as SystemNotification);
    });
    callback(list);
  });
};
