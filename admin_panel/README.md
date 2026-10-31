# TruckLink AI - Admin Dashboard

Modern web dashboard for TruckLink AI administrators and operations managers, built with **React 19**, **TypeScript**, **Vite**, and **Tailwind CSS**.

---

## ⚡ Tech Stack & Architecture

- **Framework**: React 19 + TypeScript
- **Bundler & Dev Server**: Vite with Rollup manual chunking
- **Styling**: Tailwind CSS
- **Data & Auth**: Firebase Firestore & Firebase Authentication (Custom Claims)
- **Charts & Maps**: Recharts, React-Leaflet
- **Icons**: Lucide React

---

## 🔐 Authentication & RBAC

The admin panel implements strict, token-based Role-Based Access Control (RBAC):
- **Firebase Custom Claims**: Only authenticated users with `{ admin: true }` or `{ superadmin: true }` in their Firebase Auth ID token can access dashboard routes.
- **Auto-Promotion Protection**: Client-side self-promotion is disabled. Admins are provisioned via Cloud Functions or server-side Admin SDK scripts.
- **Admin Management**: Only Superadmins can promote/demote administrators or delete user accounts via authenticated `httpsCallable` functions:
  - `setAdminClaim`: Sets `{ admin: true, superadmin: boolean }` custom claim.
  - `deleteAuthUser`: Permanently deletes an authentication user from Firebase Auth.
  - `deleteUserProfile`: Recursively deletes a user document and its subcollections (`IncomingRequests`, `ReceivedOffers`, `Reviews`, `DriverNetwork`, etc.).

---

## 🚀 Environment Configuration

Create a `.env.local` file in `admin_panel/` based on `.env.example`:

```env
VITE_FIREBASE_API_KEY=AIzaSy...
VITE_FIREBASE_AUTH_DOMAIN=trucklink-ai-orignal.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=trucklink-ai-orignal
VITE_FIREBASE_STORAGE_BUCKET=trucklink-ai-orignal.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=1:...:web:...
VITE_FIREBASE_MEASUREMENT_ID=G-...
```

*(All API variables are exposed exclusively via `import.meta.env.VITE_*` and no secrets or private keys are bundled in client code).*

---

## ⚡ Performance & Bundle Optimization

To ensure instantaneous loading even on slower networks, the admin panel features:
1. **Route-Level Code Splitting**: All pages (`Dashboard`, `Users`, `Brokers`, `Drivers`, `Orders`, `Settings`, `AuditLogs`, etc.) are lazy-loaded via `React.lazy()` and `Suspense`.
2. **Rollup Manual Chunks**: Heavy dependencies are isolated into separate cached vendor chunks:
   - `vendor-react` (React, React-DOM, Router)
   - `vendor-firebase` (Firebase App, Auth, Firestore, Functions)
   - `vendor-recharts` (Recharts, D3)
   - `vendor-leaflet` (Leaflet, React-Leaflet)
   - `vendor-lucide` (Lucide React)
   - **Result**: Initial entry chunk reduced from **1,560 kB down to 17.3 kB** (5.6 kB gzipped).
3. **Multi-Cast Firestore Listeners**: `firestoreService.ts` shares snapshot listeners across components, preventing duplicate real-time query subscriptions and cutting Firestore read usage by over 75%.

---

## 🛠️ Development & Building

### Install Dependencies
```bash
npm install
```

### Run Locally (Dev Server)
```bash
npm run dev
```

### Production Build & Validation
```bash
npm run build
```
Generates production assets in `dist/` with zero lint or build errors.

### Preview Production Build
```bash
npm run preview
```
