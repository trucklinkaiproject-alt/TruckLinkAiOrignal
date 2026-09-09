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
  orderId?: string;
  order_id?: string;
  orderNo?: string;
  order_no?: string;
  numericOrderNo?: number;
  
  // User (Shipper)
  userUid?: string;
  user_uid?: string;
  userId?: string;
  userName?: string;
  userPhone?: string;
  userEmail?: string;
  
  // Cargo Details
  itemType?: string;
  item_type?: string;
  cargoType?: string;
  weight?: string | number;
  quantity?: string | number;
  vehicleType?: string;
  vehicle_type?: string;
  vehicleTypeRequired?: string;
  additionalInfo?: string;
  additional_info?: string;
  description?: string;
  
  // Locations (Pickup & Drop-off)
  pickupCity?: string;
  pickup_city?: string;
  pickupComp?: string;
  pickup_comp?: string;
  pickupLocation?: string;
  pickupLat?: number;
  pickupLng?: number;
  pickup_lat?: number;
  pickup_lng?: number;
  pickupLatitude?: number;
  pickupLongitude?: number;
  
  dropCity?: string;
  drop_city?: string;
  dropComp?: string;
  drop_comp?: string;
  dropoffLocation?: string;
  dropLat?: number;
  dropLng?: number;
  drop_lat?: number;
  drop_lng?: number;
  dropLatitude?: number;
  dropLongitude?: number;
  
  // Broker Assignment & Quotation
  brokerId?: string;
  broker_id?: string;
  brokerName?: string;
  broker_name?: string;
  brokerPhone?: string;
  broker_phone?: string;
  brokerRating?: number;
  brokerOffer?: number;
  quoteAmount?: number;
  quote_amount?: number;
  
  // Driver Assignment & Vehicle
  assigned_driver_id?: string;
  assignedDriverId?: string;
  driverId?: string;
  driver_id?: string;
  driverUid?: string;
  assigned_driver_name?: string;
  driverName?: string;
  assigned_driver_phone?: string;
  driverPhone?: string;
  assigned_fare?: number;
  driver_fare?: number;
  driverFare?: number;
  driverVehicleType?: string;
  driverVehicleNumber?: string;
  
  // Fare & Financials
  customer_fare?: number;
  customerFare?: number;
  accepted_fare?: number;
  acceptedFare?: number;
  fare?: number;
  amount?: number;
  budget?: string | number;
  finalFare?: number | null;
  fareStatus?: 'finalized' | 'offered' | 'pending';
  
  // Lifecycle & Status
  status?: string;
  ride_phase?: string;
  date?: string;
  createdAt?: any;
  created_at?: any;
  quote_submitted_at?: any;
  accepted_at?: any;
  rejected_at?: any;
  ride_started_at?: any;
  cargo_picked_up_at?: any;
  arrived_at_drop_at?: any;
  completed_at?: any;
  updated_at?: any;
  updatedAt?: any;
  rejection_actor?: string;
  rejection_reason?: string;
  delivery_duration_seconds?: number;
  driverOffers?: DriverOfferRecord[];
  
  [key: string]: any;
}

export interface DriverOfferRecord {
  id: string;
  offer_id?: string;
  order_id?: string;
  order_no?: string;
  broker_id?: string;
  broker_name?: string;
  driver_id?: string;
  driver_name?: string;
  driver_phone?: string;
  vehicle_type?: string;
  vehicle_number?: string;
  fare?: number;
  status?: string;
  created_at?: any;
  accepted_at?: any;
  updated_at?: any;
  rejection_reason?: string;
  reason?: string;
  [key: string]: any;
}

export interface OrderItem {
  id: string;
  orderId?: string;
  orderNo?: string;
  order_no?: string;
  requestId?: string;
  userId?: string;
  userUid?: string;
  userName?: string;
  brokerId?: string;
  brokerName?: string;
  driverId?: string;
  driverName?: string;
  driverPhone?: string;
  vehicleType?: string;
  vehicleNumber?: string;
  pickupLocation?: string;
  dropoffLocation?: string;
  pickupCity?: string;
  dropCity?: string;
  pickupLat?: number;
  pickupLng?: number;
  dropoffLat?: number;
  dropoffLng?: number;
  currentLat?: number;
  currentLng?: number;
  cargoType?: string;
  itemType?: string;
  weight?: string | number;
  quantity?: string | number;
  price?: number;
  fare?: number;
  customer_fare?: number;
  accepted_fare?: number;
  driver_fare?: number;
  status?: string;
  paymentStatus?: 'pending' | 'paid' | 'escrow' | 'refunded' | string;
  date?: string;
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
  review_id?: string;
  order_id?: string;
  orderNo?: string;
  reviewer_id?: string;
  reviewer_name?: string;
  reviewer_role?: 'user' | 'broker' | 'driver' | string;
  reviewee_id?: string;
  reviewee_name?: string;
  reviewee_role?: 'broker' | 'driver' | 'user' | string;
  targetType?: 'broker' | 'driver';
  targetId?: string;
  rating: number;
  comment?: string;
  created_at?: any;
  createdAt?: any;
  [key: string]: any;
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
