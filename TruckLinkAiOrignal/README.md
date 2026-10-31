# TruckLink AI - Flutter Mobile Application

TruckLink AI is an intelligent logistics and freight brokerage platform connecting **Shippers (Users)**, **Brokers**, and **Drivers (Transporters)**. The mobile application is built using Flutter (Cubit/BLoC pattern) and Firebase Firestore for real-time synchronization, location tracking, and lifecycle management.

---

## 🏗️ Architecture & Core Modules

The mobile codebase is organized into modular features under `lib/Features/`:

- **Auth Module (`lib/Features/Auth/`)**: Role-based authentication (Shipper, Broker, Driver) with Firebase Auth, email verification, password policy enforcement (min 8 chars), blocked account checks, and profile setup.
- **Shipper / User Module (`lib/Features/User Module/`)**: Load creation, automatic broker discovery, bidding/negotiation, real-time live map tracking, and builty generation.
- **Broker Module (`lib/Features/Broker Module/`)**: Incoming request negotiation, driver network management, driver offer dispatching, rating insights, and performance analytics.
- **Driver Module (`lib/Features/Driver Module/`)**: Offer reception, route tracking, foreground GPS tracking service, ride lifecycle status transitions (pickup, transit, drop-off).
- **Chat System (`lib/Features/Chat/`)**: Optimized real-time peer messaging between Shippers, Brokers, and Drivers with denormalized participant names and paginated message streams.
- **Common Services (`lib/Features/Common/`)**:
  - `OrderService`: Centralized Firestore `WriteBatch` manager maintaining atomic multi-collection state machine synchronization.
  - `BrokerStatsService`: Idempotent calculation of broker rates (acceptance, completion, cancellation) and item-type breakdown.
  - `ReviewService`: Synchronous two-way review and rating synchronization across Broker and Driver networks.
  - `DriverLocationService`: Battery-efficient foreground location tracking with configurable intervals and cached threshold checks.
  - `AppLogger`: Centralized logging with categorized tag formatting.

---

## 🔄 Order Lifecycle & State Machine

Every order moves through a strict, linear state machine synchronized atomically across multiple Firestore collections:

```
[ pending ] 
     │
     ▼ (Broker submits counter-fare)
[ fare_offered ] 
     │
     ├──► [ rejected ] (Shipper rejects fare)
     ▼ (Shipper accepts fare)
[ accepted ]
     │
     ▼ (Broker dispatches load to driver network)
[ driver_offer_sent ]
     │
     ├──► [ rejected_by_driver ] (Driver rejects offer -> resets to accepted)
     ▼ (Driver accepts offer)
[ accepted_by_driver ]
     │
     ▼ (Driver starts transit)
[ in_transit ]
     │
     ├──► [ arrived_at_pickup ]
     │
     ├──► [ heading_to_drop ]
     ▼
[ completed ]
```

*(Any order can transition to `cancelled` by the shipper or broker prior to driver transit).*

### Multi-Collection Data Mirroring

When an order transitions, `OrderService` atomically updates all mirrored documents in a single atomic batch:
1. `Orders/{orderId}` (Master document)
2. `User/{uid}/Requests/{orderId}` (Shipper's request history)
3. `Broker/{brokerId}/IncomingRequests/{orderId}` (Broker's active load queue)
4. `Driver/{driverId}/ReceivedOffers/{offerId}` (Driver offer document)
5. `Driver/{driverId}/ActiveRides/{rideId}` (Driver live tracking document)

---

## 📍 Foreground Location Tracking

Driver location tracking is managed by `DriverLocationService`:
- Runs an Android Foreground Service with a sticky persistent notification (`ForegroundNotificationConfig`).
- Heartbeat interval: **45 seconds** during active rides; idle updates every **4 minutes**.
- In-memory destination threshold detection (`_reachedPickup`, `_reachedDrop`) to eliminate redundant Firestore `get()` queries on each GPS fix.
- Resume-on-reboot support via `resumeIfActiveRide()` checking `Driver/{driverId}/ActiveRides`.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.10.0`
- **Dart SDK**: `^3.10.0`
- Android Studio / VS Code with Flutter extension
- Android SDK 34+ (compileSdkVersion: 34, minSdkVersion: 23)

### Installation
1. Clone the repository and navigate to the Flutter project:
   ```bash
   cd TruckLinkAiOrignal
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Firebase configuration:
   - Place your `google-services.json` in `android/app/`.
   - Place your `GoogleService-Info.plist` in `ios/Runner/` (if targeting iOS).

### Android Release Signing
Release builds use `key.properties` configured in `android/app/build.gradle.kts`:
Create `android/key.properties`:
```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=<YOUR_KEY_ALIAS>
storeFile=<PATH_TO_KEYSTORE_FILE>
```

---

## 🧪 Testing & Code Quality

### Static Code Analysis
Run Flutter's strict analyzer:
```bash
flutter analyze
```
*Current status: 0 errors, 0 warnings.*

### Automated Unit Tests
Run the comprehensive unit test suite:
```bash
flutter test
```
The test suite covers:
- `brokerStatsService_test.dart`: Rate calculations, divide-by-zero protection, decimal rounding.
- `orderService_test.dart`: Linear order state transitions, idempotent operations, invalid transition guards.
- `vehicleType_test.dart`: Strict matching, compound type parsing, whitespace normalization.
