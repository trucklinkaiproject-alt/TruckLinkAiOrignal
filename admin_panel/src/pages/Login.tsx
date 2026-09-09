import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Truck, Lock, Mail, ArrowRight, ShieldCheck, AlertCircle } from 'lucide-react';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('admin@trucklink.ai');
  const [password, setPassword] = useState('Admin@123456');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login, currentUser, isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as any)?.from?.pathname || '/dashboard';

  // If already logged in and admin, redirect
  React.useEffect(() => {
    if (currentUser && isAdmin) {
      navigate(from, { replace: true });
    }
  }, [currentUser, isAdmin, navigate, from]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please provide both administrative email and security password.');
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      await login(email.trim(), password);
      navigate('/dashboard', { replace: true });
    } catch (err: any) {
      console.error('Authentication error:', err);
      if (
        err.code === 'auth/invalid-credential' ||
        err.code === 'auth/user-not-found' ||
        err.code === 'auth/wrong-password'
      ) {
        setError('Invalid administrative credentials. Please verify your email and password.');
      } else if (err.code === 'auth/too-many-requests') {
        setError('Too many failed attempts. Account temporarily locked for security. Please try again later.');
      } else {
        setError(err.message || 'Authentication error occurred.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-center items-center p-4 relative overflow-hidden">
      {/* Background glowing effects */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-brand-600/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-purple-600/15 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-md w-full relative z-10">
        {/* Header Branding */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-tr from-brand-600 to-sky-400 p-0.5 shadow-2xl shadow-sky-500/20 mb-4">
            <div className="w-full h-full bg-slate-950 rounded-[14px] flex items-center justify-center">
              <Truck className="w-8 h-8 text-sky-400" />
            </div>
          </div>
          <div className="flex items-center justify-center gap-2 mb-1">
            <h1 className="text-2xl font-black tracking-tight text-white">TruckLink</h1>
            <span className="px-2 py-0.5 bg-gradient-to-r from-brand-500 to-cyan-400 text-slate-950 font-black text-xs rounded uppercase tracking-wider">
              AI
            </span>
          </div>
          <p className="text-sm text-slate-400">Super Admin Command Center</p>
        </div>

        {/* Login Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-7 sm:p-8 backdrop-blur-2xl shadow-2xl">
          <div className="flex items-center gap-2 mb-6 text-xs font-bold text-sky-400 uppercase tracking-wider">
            <ShieldCheck className="w-4 h-4" />
            <span>Authorized Administrator Authentication</span>
          </div>

          {error && (
            <div className="mb-5 p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-2.5 text-rose-300 text-xs">
              <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-rose-200">Access Denied</p>
                <p className="text-rose-300/90 mt-0.5">{error}</p>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                Admin Email Address
              </label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@trucklink.ai"
                  required
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-950/90 border border-slate-700/70 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                Security Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  required
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-950/90 border border-slate-700/70 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-colors"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full mt-2 py-3 px-4 text-white font-bold text-sm rounded-xl shadow-lg flex items-center justify-center gap-2 transition-all disabled:opacity-50 bg-gradient-to-r from-brand-600 to-sky-500 hover:from-brand-500 hover:to-sky-400 shadow-sky-600/25"
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Verifying Credentials...</span>
                </>
              ) : (
                <>
                  <span>Authenticate & Enter</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Security Notice */}
          <div className="mt-6 pt-4 border-t border-slate-800 text-center space-y-1">
            <p className="text-xs text-slate-400">
              Access is strictly restricted to authorized Super Administrators.
            </p>
            <p className="text-[11px] font-mono text-slate-500">
              Public registration is disabled. Managed via Firebase Admin SDK.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
