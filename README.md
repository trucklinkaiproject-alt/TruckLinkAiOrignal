# TruckLink AI - Enterprise Logistics Platform

TruckLink AI is an end-to-end intelligent logistics and freight matching platform. It connects shippers with verified freight brokers and commercial truck drivers across a real-time, event-driven architecture.

---

## 📁 Repository Structure

```
├── TruckLinkAiOrignal/         # Flutter Mobile Application (Shipper, Broker, Driver)
│   ├── lib/Features/           # Feature-first Cubit/BLoC architecture
│   ├── functions/              # Cloud Functions (FCM push, driver network sync)
│   ├── firestore.rules         # Hardened least-privilege Firestore security rules
│   └── test/                   # Unit test suite (Lifecycle, Stats, Vehicle types)
│
├── admin_panel/                # React 19 + TypeScript + Vite Operations Dashboard
│   ├── src/                    # Lazy-loaded pages, multicast listeners, components
│   └── functions/              # Admin Cloud Functions (Custom claims, auth cleanup)
│
└── scripts/                    # Node.js Firebase Admin SDK management scripts
    ├── bootstrap-admin.js      # One-time superadmin bootstrap script
    └── backfill-broker-stats.js# Broker statistics & recommendation data backfill
```

---

## 🔐 Firebase Security Architecture

- **Shared Firebase Project**: `trucklink-ai-orignal`
- **Least-Privilege Rules**: Firestore rules (`TruckLinkAiOrignal/firestore.rules`) strictly enforce:
  - Role-based token claims (`request.auth.token.admin == true`).
  - Read/Write authorization restricted to participants on orders, offers, rides, and chats.
  - Immutability of append-only `AuditLogs`.
  - Input validation for review ratings and feedback length.

---

## 🛠️ Management & Backfill Scripts

The `scripts/` directory contains Node.js Admin SDK automation utilities:

### 1. Bootstrapping Superadmin
To grant superadmin custom claims to the initial admin user:
```bash
node scripts/bootstrap-admin.js <admin-uid>
```

### 2. Broker Recommendation Data Backfill
To compute rates, ratings, item histograms, and vehicle types across all brokers:
```bash
# Preview changes in dry-run mode
node scripts/backfill-broker-stats.js --dry-run

# Commit updates to Firestore
node scripts/backfill-broker-stats.js
```
*(Requires `serviceAccountKey.json` placed in `scripts/serviceAccountKey.json` or path set via `GOOGLE_APPLICATION_CREDENTIALS`).*

---

## 🚀 Quick Start & Verification

### Flutter App
```bash
cd TruckLinkAiOrignal
flutter pub get
flutter test
flutter analyze
```

### Admin Dashboard
```bash
cd admin_panel
npm install
npm run build
npm run dev
```
