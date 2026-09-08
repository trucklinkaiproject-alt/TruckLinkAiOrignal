export interface UserProfile {
  id: string;
  name?: string;
  fullName?: string;
  email?: string;
  phone?: string;
  phoneNumber?: string;
  role?: string;
  address?: string;
  profileImage?: string;
  profilePicUrl?: string;
  status?: 'active' | 'blocked' | 'pending' | string;
  createdAt?: any;
  updatedAt?: any;
  fcmToken?: string;
  [key: string]: any;
}

export interface BrokerProfile {
  id: string;
  name?: string;
  fullName?: string;
  companyName?: string;
  email?: string;
  phone?: string;
  address?: string;
  profileImage?: string;
  rating?: number;
  totalRatings?: number;
  isVerified?: boolean;
  status?: 'active' | 'blocked' | 'pending' | string;
  createdAt?: any;
  updatedAt?: any;
  [key: string]: any;
}

export interface DriverProfile {
  id: string;
  uid?: string;
  name?: string;
  fullName?: string;
  email?: string;
  phone?: string;
  phoneNumber?: string;
  cnic?: string;
  licenseNumber?: string;
  vehicleType?: string;
  vehicleNumber?: string;
  vehicle_type?: string;
  vehicle_number?: string;
  vehicleAvailable?: boolean;
  vehicle_available?: boolean;
  isAvailable?: boolean;
  availabilityStatus?: string;
  availability_status?: string;
  truckDetailsCompleted?: boolean;
  truck_details_completed?: boolean;
  onboardingCompleted?: boolean;
  onboarding_completed?: boolean;
  brokerId?: string;
  broker_id?: string;
  brokerName?: string;
  broker_name?: string;
  created_by_broker_id?: string;
  rating?: number;
  driverRating?: number;
  driver_rating?: number;
  totalTrips?: number;
  total_trips?: number;
  completedTrips?: number;
  completed_trips?: number;
  cancelledTrips?: number;
  cancelled_trips?: number;
  status?: 'active' | 'blocked' | 'pending' | 'on-trip' | 'offline' | 'online' | string;
  driverLatitude?: number;
  driver_latitude?: number;
  driverLongitude?: number;
  driver_longitude?: number;
  currentLocation?: {
    latitude: number;
    longitude: number;
    address?: string;
    updatedAt?: any;
  };
  latitude?: number;
  longitude?: number;
  createdAt?: any;
  created_at?: any;
  updatedAt?: any;
  updated_at?: any;
  [key: string]: any;
}

export interface VehicleRecord {
  id: string;
  driverId: string;
  driverName: string;
  driverPhone: string;
  driverEmail?: string;
  vehicleType: string;
  vehicleNumber: string;
  brokerId?: string;
  brokerName?: string;
  status: string;
  availabilityStatus: string;
  isAvailable: boolean;
  rating?: number;
  completedTrips?: number;
  totalTrips?: number;
}

export interface UserRequest {
  id: string;
  userId?: string;
  userName?: string;
  userPhone?: string;
  pickupLocation?: string;
  pickupLat?: number;
  pickupLng?: number;
  dropoffLocation?: string;
  dropoffLat?: number;
  dropoffLng?: number;
  cargoType?: string;
  weight?: string | number;
  dimensions?: string;
  vehicleTypeRequired?: string;
  budget?: string | number;
  urgency?: string;
  status?: 'pending' | 'accepted' | 'in-transit' | 'completed' | 'cancelled' | string;
  preferredDate?: string;
  createdAt?: any;
  assignedBrokerId?: string;
  assignedDriverId?: string;
  [key: string]: any;
}

export interface OrderItem {
  id: string;
  orderId?: string;
  requestId?: string;
  userId?: string;
  userName?: string;
  brokerId?: string;
  brokerName?: string;
  driverId?: string;
  driverName?: string;
  driverPhone?: string;
  pickupLocation?: string;
  dropoffLocation?: string;
  pickupLat?: number;
  pickupLng?: number;
  dropoffLat?: number;
  dropoffLng?: number;
  currentLat?: number;
  currentLng?: number;
  cargoType?: string;
  weight?: string | number;
  price?: number;
  status?: 'pending' | 'accepted' | 'assigned' | 'picked_up' | 'in_transit' | 'delivered' | 'cancelled' | string;
  paymentStatus?: 'pending' | 'paid' | 'escrow' | 'refunded' | string;
  createdAt?: any;
  updatedAt?: any;
  estimatedDelivery?: any;
  [key: string]: any;
}

export interface ChatMessage {
  id: string;
  chatId?: string;
  senderId?: string;
  senderName?: string;
  senderRole?: string;
  receiverId?: string;
  text?: string;
  timestamp?: any;
  read?: boolean;
  [key: string]: any;
}

export interface ChatThread {
  id: string;
  participants?: string[];
  participantNames?: { [uid: string]: string };
  participantRoles?: { [uid: string]: string };
  lastMessage?: string;
  lastMessageTime?: any;
  unreadCount?: number;
  updatedAt?: any;
  [key: string]: any;
}

export interface AdminUser {
  uid: string;
  email: string;
  displayName?: string;
  role: 'superadmin' | 'admin' | 'moderator';
  status: 'active' | 'suspended';
  createdAt?: any;
  lastLoginAt?: any;
}

export interface AuditLog {
  id: string;
  adminId: string;
  adminEmail: string;
  action: string;
  targetCollection: string;
  targetId: string;
  timestamp: any;
  details?: Record<string, any>;
}

export interface ReviewRating {
  id: string;
  targetType: 'broker' | 'driver';
  targetId: string;
  reviewerId: string;
  reviewerName?: string;
  rating: number;
  comment?: string;
  createdAt?: any;
}

export interface SystemNotification {
  id: string;
  title: string;
  message: string;
  targetAudience: 'all' | 'users' | 'brokers' | 'drivers';
  sentBy: string;
  sentAt: any;
  status: 'sent' | 'scheduled';
}
