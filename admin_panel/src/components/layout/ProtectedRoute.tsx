import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Truck } from 'lucide-react';

export const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { currentUser, isAdmin, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-white">
        <div className="relative flex items-center justify-center mb-4">
          <div className="w-16 h-16 rounded-full border-4 border-brand-500/20 border-t-brand-500 animate-spin" />
          <Truck className="w-7 h-7 text-sky-400 absolute" />
        </div>
        <p className="text-sm font-semibold text-slate-300">Authenticating TruckLink Admin...</p>
        <p className="text-xs text-slate-500 mt-1">Verifying credentials and security permissions</p>
      </div>
    );
  }

  if (!currentUser) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // If user is authenticated, check admin authorization
  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-white p-6 text-center">
        <div className="max-w-md w-full p-8 bg-slate-900/80 border border-rose-500/30 rounded-2xl shadow-2xl">
          <div className="w-14 h-14 bg-rose-500/15 text-rose-400 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-rose-500/30">
            <span className="text-2xl font-black">!</span>
          </div>
          <h2 className="text-xl font-bold text-white mb-2">Access Restricted</h2>
          <p className="text-sm text-slate-300 mb-6">
            Account <span className="font-mono text-sky-400">{currentUser.email}</span> is authenticated in Firebase Auth, but does not have active administrative privileges in the <span className="font-mono text-white">Admins</span> collection.
          </p>
          <div className="flex flex-col gap-3">
            <a
              href="/login"
              className="px-4 py-2.5 bg-brand-600 hover:bg-brand-500 text-white rounded-xl text-sm font-semibold transition-colors"
            >
              Back to Login
            </a>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};
