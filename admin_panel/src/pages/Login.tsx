import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Truck, Lock, Mail, ArrowRight, ShieldCheck, AlertCircle, UserPlus, User } from 'lucide-react';

export const Login: React.FC = () => {
  const [isRegisterMode, setIsRegisterMode] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('admin@trucklink.ai');
  const [password, setPassword] = useState('Admin@123456');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login, register, currentUser, isAdmin } = useAuth();
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
      setError('Please fill in both email and password.');
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      if (isRegisterMode) {
        await register(email.trim(), password, name.trim() || 'Super Admin');
      } else {
        await login(email.trim(), password);
      }
      navigate('/dashboard', { replace: true });
    } catch (err: any) {
      console.error('Authentication error:', err);
      if (err.code === 'auth/invalid-credential' || err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
        setError('Invalid credentials. If this account does not exist in Firebase yet, switch to "Create Super Admin" below to register it.');
      } else if (err.code === 'auth/email-already-in-use') {
        setError('This email is already registered in Firebase. Switch to "Sign In" mode to log in.');
      } else if (err.code === 'auth/weak-password') {
        setError('Password is too weak. Please use at least 6 characters.');
      } else if (err.code === 'auth/too-many-requests') {
        setError('Too many failed attempts. Please try again later.');
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
          <p className="text-sm text-slate-400">Enterprise Administration & Telematics Portal</p>
        </div>

        {/* Login Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-7 sm:p-8 backdrop-blur-2xl shadow-2xl">
          {/* Mode Switcher */}
          <div className="flex rounded-xl bg-slate-950 p-1 border border-slate-800 mb-6">
            <button
              type="button"
              onClick={() => {
                setIsRegisterMode(false);
                setError(null);
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1.5 ${
                !isRegisterMode
                  ? 'bg-brand-600 text-white shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5" />
              Sign In
            </button>
            <button
              type="button"
              onClick={() => {
                setIsRegisterMode(true);
                setError(null);
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1.5 ${
                isRegisterMode
                  ? 'bg-purple-600 text-white shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <UserPlus className="w-3.5 h-3.5" />
              Register Super Admin
            </button>
          </div>

          {error && (
            <div className="mb-5 p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-2.5 text-rose-300 text-xs">
              <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-rose-200">Authentication Alert</p>
                <p className="text-rose-300/90 mt-0.5">{error}</p>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {isRegisterMode && (
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                  Full Name
                </label>
                <div className="relative">
                  <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Super Admin"
                    className="w-full pl-10 pr-4 py-2.5 bg-slate-950/90 border border-slate-700/70 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-colors"
                  />
                </div>
              </div>
            )}

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
              <p className="text-[11px] text-slate-500 mt-1">Minimum 6 characters</p>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className={`w-full mt-2 py-3 px-4 text-white font-bold text-sm rounded-xl shadow-lg flex items-center justify-center gap-2 transition-all disabled:opacity-50 ${
                isRegisterMode
                  ? 'bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 shadow-purple-600/25'
                  : 'bg-gradient-to-r from-brand-600 to-sky-500 hover:from-brand-500 hover:to-sky-400 shadow-sky-600/25'
              }`}
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Processing Request...</span>
                </>
              ) : isRegisterMode ? (
                <>
                  <span>Create Super Admin & Enter</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              ) : (
                <>
                  <span>Sign In to Admin Panel</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Helper instructions for the user */}
          <div className="mt-5 pt-4 border-t border-slate-800 text-center space-y-1">
            <p className="text-xs text-slate-400">
              {isRegisterMode
                ? 'Creating an admin account will register it directly in Firebase Auth & Firestore Admins collection.'
                : 'Enter your Firebase credentials above, or switch tabs to register a new admin.'}
            </p>
            <p className="text-[11px] font-mono text-sky-400/90">
              Cluster: trucklink-ai-orignal
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
