import React, { useEffect, useState } from 'react';
import { Settings as SettingsIcon, Shield, Key, UserPlus, Server, CheckCircle2, AlertCircle, Lock, Mail, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { collection, getDocs } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { db } from '../services/firebase';
import { AdminUser } from '../types/models';
import { Badge } from '../components/common/Badge';

export const Settings: React.FC = () => {
  const { adminProfile } = useAuth();
  const [adminsList, setAdminsList] = useState<AdminUser[]>([]);
  const [loadingAdmins, setLoadingAdmins] = useState(true);

  // New admin form
  const [newEmail, setNewEmail] = useState('');
  const [newName, setNewName] = useState('');
  const [newUid, setNewUid] = useState('');
  const [newRole, setNewRole] = useState<'admin' | 'moderator'>('admin');
  const [addingAdmin, setAddingAdmin] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fetchAdmins = async () => {
    setLoadingAdmins(true);
    try {
      const snap = await getDocs(collection(db, 'Admins'));
      const list: AdminUser[] = [];
      snap.forEach((d) => {
        list.push({ uid: d.id, ...d.data() } as AdminUser);
      });
      setAdminsList(list);
    } catch (err) {
      console.error('Failed to fetch Admins collection:', err);
    } finally {
      setLoadingAdmins(false);
    }
  };

  useEffect(() => {
    fetchAdmins();
  }, []);

  /**
   * Calls the server-side `setAdminClaim` Cloud Function.
   * No direct Firestore writes are performed from the browser for admin creation.
   */
  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEmail || !newUid) return;
    if (adminProfile?.role !== 'superadmin') {
      setErrorMsg('Only a superadmin can grant admin privileges.');
      return;
    }

    setAddingAdmin(true);
    setSuccessMsg(null);
    setErrorMsg(null);

    try {
      const functions = getFunctions();
      const setAdminClaim = httpsCallable<{ targetUid: string; role: string; email: string; displayName: string }, { success: boolean; message: string }>(
        functions,
        'setAdminClaim'
      );

      const result = await setAdminClaim({
        targetUid: newUid.trim(),
        role: newRole,
        email: newEmail.trim(),
        displayName: newName.trim() || 'Admin User',
      });

      if (result.data.success) {
        setNewEmail('');
        setNewName('');
        setNewUid('');
        setSuccessMsg(result.data.message || 'Admin privileges granted successfully.');
        fetchAdmins();
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to grant admin privileges.';
      console.error('handleCreateAdmin error:', err);
      setErrorMsg(message);
    } finally {
      setAddingAdmin(false);
    }
  };

  return (
    <div className="space-y-8">
      <div>
        <div className="flex items-center gap-2">
          <SettingsIcon className="w-6 h-6 text-sky-400" />
          <h2 className="text-2xl font-black text-white">Platform Settings & Admin Access</h2>
        </div>
        <p className="text-xs text-slate-400 mt-1">
          Configure TruckLink AI engine parameters, security policies, and manage administrative privileges.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Firebase Cluster Info */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl space-y-4">
          <div className="flex items-center gap-2 text-sky-400 font-bold text-sm">
            <Server className="w-5 h-5" />
            <h3>Active Firebase Environment</h3>
          </div>

          <div className="space-y-3 text-xs">
            <div className="p-3 bg-slate-950 rounded-xl border border-slate-800">
              <span className="text-slate-500 font-semibold uppercase">Project ID</span>
              <p className="font-mono text-white font-bold mt-0.5">trucklink-ai-orignal</p>
            </div>

            <div className="p-3 bg-slate-950 rounded-xl border border-slate-800">
              <span className="text-slate-500 font-semibold uppercase">Auth Domain</span>
              <p className="font-mono text-slate-300 mt-0.5">trucklink-ai-orignal.firebaseapp.com</p>
            </div>

            <div className="p-3 bg-slate-950 rounded-xl border border-slate-800">
              <span className="text-slate-500 font-semibold uppercase">Cloud Firestore Cluster</span>
              <p className="text-emerald-400 font-semibold mt-0.5 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                Multi-Region Active Sync
              </p>
            </div>
          </div>
        </div>

        {/* Current Admin Account Card */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl space-y-4">
          <div className="flex items-center gap-2 text-purple-400 font-bold text-sm">
            <Shield className="w-5 h-5" />
            <h3>Your Admin Profile</h3>
          </div>

          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-3 text-xs">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-purple-500/20 text-purple-300 font-black text-base flex items-center justify-center border border-purple-500/30">
                <User className="w-6 h-6" />
              </div>
              <div>
                <h4 className="font-bold text-white text-sm">{adminProfile?.displayName || 'System Admin'}</h4>
                <p className="text-slate-400 font-mono text-[11px]">{adminProfile?.email}</p>
              </div>
            </div>

            <div className="pt-2 border-t border-slate-800 flex items-center justify-between">
              <span className="text-slate-400">Assigned Role:</span>
              <Badge variant="purple" size="sm">{adminProfile?.role || 'Super Admin'}</Badge>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-slate-400">Account Status:</span>
              <Badge variant="success" size="sm">Active</Badge>
            </div>

            <div className="flex items-center gap-1.5 text-emerald-400 text-[10px] pt-1 border-t border-slate-800">
              <Key className="w-3 h-3" />
              <span>Admin claim verified via Firebase Auth token</span>
            </div>
          </div>
        </div>

        {/* Authorize New Admin – superadmin only */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <div className="flex items-center gap-2 text-emerald-400 font-bold text-sm mb-4">
            <UserPlus className="w-5 h-5" />
            <h3>Grant Admin Privileges</h3>
          </div>

          {adminProfile?.role !== 'superadmin' && (
            <div className="mb-4 p-3 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs flex items-center gap-2">
              <Lock className="w-4 h-4 shrink-0" />
              <span>Only a <strong>superadmin</strong> can grant admin privileges.</span>
            </div>
          )}

          {successMsg && (
            <div className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}

          {errorMsg && (
            <div className="mb-4 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <form onSubmit={handleCreateAdmin} className="space-y-3 text-xs">
            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Admin UID (Firebase Auth UID)
              </label>
              <input
                id="settings-admin-uid"
                type="text"
                value={newUid}
                onChange={(e) => setNewUid(e.target.value)}
                placeholder="User UID from Firebase Auth"
                required
                disabled={adminProfile?.role !== 'superadmin'}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500 disabled:opacity-50"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Admin Email
              </label>
              <input
                id="settings-admin-email"
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="newadmin@trucklink.ai"
                required
                disabled={adminProfile?.role !== 'superadmin'}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500 disabled:opacity-50"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Display Name
              </label>
              <input
                id="settings-admin-name"
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Full Name"
                disabled={adminProfile?.role !== 'superadmin'}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500 disabled:opacity-50"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Role Permission
              </label>
              <select
                id="settings-admin-role"
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as 'admin' | 'moderator')}
                disabled={adminProfile?.role !== 'superadmin'}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500 disabled:opacity-50"
              >
                <option value="admin">Admin (Full Operational Controls)</option>
                <option value="moderator">Moderator (Read-Only & Dispatch)</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={addingAdmin || adminProfile?.role !== 'superadmin'}
              className="w-full mt-2 py-2.5 bg-brand-600 hover:bg-brand-500 text-white font-bold rounded-xl shadow-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {addingAdmin ? 'Granting via Cloud Function...' : 'Authorize Admin'}
            </button>
          </form>
        </div>
      </div>

      {/* Admins Registry Table */}
      <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
        <h3 className="text-base font-bold text-white mb-4">Authorized System Administrators</h3>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950/60 text-slate-400 uppercase tracking-wider border-b border-slate-800">
              <tr>
                <th className="py-3 px-4">Admin Name & Email</th>
                <th className="py-3 px-4">Firebase UID</th>
                <th className="py-3 px-4">Role</th>
                <th className="py-3 px-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {loadingAdmins ? (
                <tr>
                  <td colSpan={4} className="py-6 text-center text-slate-500">Loading administrators…</td>
                </tr>
              ) : adminsList.length === 0 ? (
                <tr>
                  <td colSpan={4} className="py-6 text-center text-slate-500">No administrators found.</td>
                </tr>
              ) : (
                adminsList.map((a) => (
                  <tr key={a.uid} className="hover:bg-slate-800/30">
                    <td className="py-3 px-4">
                      <p className="font-bold text-white">{a.displayName || 'Administrator'}</p>
                      <p className="text-slate-400"><Mail className="inline w-3 h-3 mr-1" />{a.email}</p>
                    </td>
                    <td className="py-3 px-4 font-mono text-sky-400">{a.uid}</td>
                    <td className="py-3 px-4">
                      <Badge variant={a.role === 'superadmin' ? 'purple' : 'info'} size="sm">
                        {a.role || 'admin'}
                      </Badge>
                    </td>
                    <td className="py-3 px-4">
                      <Badge variant={a.status === 'suspended' ? 'danger' : 'success'} size="sm">
                        {a.status || 'active'}
                      </Badge>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
