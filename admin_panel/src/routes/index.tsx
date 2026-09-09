import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from '../components/layout/ProtectedRoute';
import { AdminLayout } from '../components/layout/AdminLayout';
import { Login } from '../pages/Login';
import { Dashboard } from '../pages/Dashboard';
import { Users } from '../pages/Users';
import { Brokers } from '../pages/Brokers';
import { Drivers } from '../pages/Drivers';
import { Vehicles } from '../pages/Vehicles';
import { Requests } from '../pages/Requests';
import { Tracking } from '../pages/Tracking';
import { Ratings } from '../pages/Ratings';
import { Notifications } from '../pages/Notifications';
import { Messages } from '../pages/Messages';
import { Analytics } from '../pages/Analytics';
import { AuditLogs } from '../pages/AuditLogs';
import { Settings } from '../pages/Settings';

export const AppRouter: React.FC = () => {
  return (
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
  );
};
