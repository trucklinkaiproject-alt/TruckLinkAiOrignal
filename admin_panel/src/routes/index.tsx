import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from '../components/layout/ProtectedRoute';
import { AdminLayout } from '../components/layout/AdminLayout';

// Route-level code splitting via React.lazy
const Login = lazy(() => import('../pages/Login').then((m) => ({ default: m.Login })));
const Dashboard = lazy(() => import('../pages/Dashboard').then((m) => ({ default: m.Dashboard })));
const Users = lazy(() => import('../pages/Users').then((m) => ({ default: m.Users })));
const Brokers = lazy(() => import('../pages/Brokers').then((m) => ({ default: m.Brokers })));
const Drivers = lazy(() => import('../pages/Drivers').then((m) => ({ default: m.Drivers })));
const Vehicles = lazy(() => import('../pages/Vehicles').then((m) => ({ default: m.Vehicles })));
const Requests = lazy(() => import('../pages/Requests').then((m) => ({ default: m.Requests })));
const Tracking = lazy(() => import('../pages/Tracking').then((m) => ({ default: m.Tracking })));
const Ratings = lazy(() => import('../pages/Ratings').then((m) => ({ default: m.Ratings })));
const Notifications = lazy(() => import('../pages/Notifications').then((m) => ({ default: m.Notifications })));
const Messages = lazy(() => import('../pages/Messages').then((m) => ({ default: m.Messages })));
const Analytics = lazy(() => import('../pages/Analytics').then((m) => ({ default: m.Analytics })));
const AuditLogs = lazy(() => import('../pages/AuditLogs').then((m) => ({ default: m.AuditLogs })));
const Settings = lazy(() => import('../pages/Settings').then((m) => ({ default: m.Settings })));

const PageLoader: React.FC = () => (
  <div className="flex items-center justify-center min-h-[60vh]">
    <div className="relative">
      <div className="w-10 h-10 border-4 border-primary/20 border-t-primary rounded-full animate-spin" />
    </div>
  </div>
);

export const AppRouter: React.FC = () => {
  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        {/* Public Login Route */}
        <Route path="/login" element={<Login />} />

        {/* Protected Admin Routes */}
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          <Route path="brokers" element={<Brokers />} />
          <Route path="drivers" element={<Drivers />} />
          <Route path="vehicles" element={<Vehicles />} />
          <Route path="requests" element={<Requests />} />
          <Route path="orders" element={<Navigate to="/requests" replace />} />
          <Route path="tracking" element={<Tracking />} />
          <Route path="ratings" element={<Ratings />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="messages" element={<Messages />} />
          <Route path="analytics" element={<Analytics />} />
          <Route path="audit-logs" element={<AuditLogs />} />
          <Route path="settings" element={<Settings />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Suspense>
  );
};
