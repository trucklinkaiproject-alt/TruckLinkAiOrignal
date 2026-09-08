import {
  collection,
  doc,
  getDocs,
  getDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  onSnapshot,
  query,
  orderBy,
  limit,
  serverTimestamp,
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
  SystemNotification
} from '../types/models';

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

// ================= USER OPERATIONS =================
export const subscribeUsers = (callback: (users: UserProfile[]) => void) => {
  const usersRef = collection(db, 'User');
  return onSnapshot(usersRef, (snapshot) => {
    const list: UserProfile[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as UserProfile);
    });
    callback(list);
  });
};

export const updateUserStatus = async (
  userId: string,
  status: 'active' | 'blocked',
  adminEmail: string
) => {
  const userRef = doc(db, 'User', userId);
  await updateDoc(userRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction('admin', adminEmail, `USER_STATUS_${status.toUpperCase()}`, 'User', userId);
};

export const deleteUserDoc = async (userId: string, adminEmail: string) => {
  const userRef = doc(db, 'User', userId);
  await deleteDoc(userRef);
  await logAdminAction('admin', adminEmail, 'USER_DELETED', 'User', userId);
};

// ================= BROKER OPERATIONS =================
export const subscribeBrokers = (callback: (brokers: BrokerProfile[]) => void) => {
  const brokersRef = collection(db, 'Broker');
  return onSnapshot(brokersRef, (snapshot) => {
    const list: BrokerProfile[] = [];
    snapshot.forEach((docSnap) => {
      list.push({ id: docSnap.id, ...docSnap.data() } as BrokerProfile);
    });
    callback(list);
  });
};

export const updateBrokerStatus = async (
  brokerId: string,
  status: 'active' | 'blocked',
  adminEmail: string
) => {
  const brokerRef = doc(db, 'Broker', brokerId);
  await updateDoc(brokerRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction('admin', adminEmail, `BROKER_STATUS_${status.toUpperCase()}`, 'Broker', brokerId);
};

export const verifyBroker = async (brokerId: string, isVerified: boolean, adminEmail: string) => {
  const brokerRef = doc(db, 'Broker', brokerId);
  await updateDoc(brokerRef, { isVerified, updatedAt: serverTimestamp() });
  await logAdminAction('admin', adminEmail, isVerified ? 'BROKER_VERIFIED' : 'BROKER_UNVERIFIED', 'Broker', brokerId);
};

export const deleteBrokerDoc = async (brokerId: string, adminEmail: string) => {
  const brokerRef = doc(db, 'Broker', brokerId);
  await deleteDoc(brokerRef);
  await logAdminAction('admin', adminEmail, 'BROKER_DELETED', 'Broker', brokerId);
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

export const subscribeDrivers = (callback: (drivers: DriverProfile[]) => void) => {
  const driversRef = collection(db, 'Driver');
  return onSnapshot(driversRef, (snapshot) => {
    const list: DriverProfile[] = [];
    snapshot.forEach((docSnap) => {
      list.push(normalizeDriver(docSnap.id, docSnap.data()));
    });
    callback(list);
  });
};

export const updateDriverStatus = async (
  driverId: string,
  status: 'active' | 'blocked' | 'on-trip',
  adminEmail: string
) => {
  const driverRef = doc(db, 'Driver', driverId);
  await updateDoc(driverRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction('admin', adminEmail, `DRIVER_STATUS_${status.toUpperCase()}`, 'Driver', driverId);
};

export const deleteDriverDoc = async (driverId: string, adminEmail: string) => {
  const driverRef = doc(db, 'Driver', driverId);
  await deleteDoc(driverRef);
  await logAdminAction('admin', adminEmail, 'DRIVER_DELETED', 'Driver', driverId);
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
  adminEmail: string
) => {
  const orderRef = doc(db, 'Orders', orderId);
  await updateDoc(orderRef, { status, updatedAt: serverTimestamp() });
  await logAdminAction('admin', adminEmail, `ORDER_STATUS_${status.toUpperCase()}`, 'Orders', orderId);
};

// ================= REQUESTS (Collection group or user subcollections) =================
export const fetchAllRequests = async (): Promise<UserRequest[]> => {
  const usersRef = collection(db, 'User');
  const userDocs = await getDocs(usersRef);
  const requests: UserRequest[] = [];

  for (const userDoc of userDocs.docs) {
    const requestsSubRef = collection(db, 'User', userDoc.id, 'Requests');
    const reqSnap = await getDocs(requestsSubRef);
    reqSnap.forEach((docSnap) => {
      requests.push({
        id: docSnap.id,
        userId: userDoc.id,
        userName: userDoc.data().name || userDoc.data().fullName || 'Shipper',
        userPhone: userDoc.data().phone || userDoc.data().phoneNumber || '',
        ...docSnap.data()
      } as UserRequest);
    });
  }
  return requests;
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
  const q = query(messagesRef, orderBy('timestamp', 'asc'), limit(100));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
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

// ================= SYSTEM NOTIFICATIONS =================
export const sendBroadcastNotification = async (
  title: string,
  message: string,
  targetAudience: 'all' | 'users' | 'brokers' | 'drivers',
  adminEmail: string
) => {
  const notificationsRef = collection(db, 'SystemNotifications');
  const docRef = await addDoc(notificationsRef, {
    title,
    message,
    targetAudience,
    sentBy: adminEmail,
    sentAt: serverTimestamp(),
    status: 'sent'
  });
  await logAdminAction('admin', adminEmail, 'BROADCAST_NOTIFICATION_SENT', 'SystemNotifications', docRef.id, {
    title,
    targetAudience
  });
  return docRef.id;
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
