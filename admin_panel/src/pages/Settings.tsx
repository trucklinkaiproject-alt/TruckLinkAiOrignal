import React, { useEffect, useState } from 'react';
import { Settings as SettingsIcon, Shield, Key, UserPlus, Server, CheckCircle2, Lock, Mail, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { collection, getDocs, doc, setDoc, serverTimestamp } from 'firebase/firestore';
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

  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEmail || !newUid) return;

    setAddingAdmin(true);
    setSuccessMsg(null);
    try {
      const adminDocRef = doc(db, 'Admins', newUid.trim());
      await setDoc(adminDocRef, {
        email: newEmail.trim(),
        displayName: newName.trim() || 'Admin User',
        role: newRole,
        status: 'active',
        createdAt: serverTimestamp(),
        lastLoginAt: serverTimestamp(),
      });

      setNewEmail('');
      setNewName('');
      setNewUid('');
      setSuccessMsg('New Admin profile authorized and registered in Admins collection.');
      fetchAdmins();
    } catch (err) {
      console.error('Failed to add admin:', err);
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
          </div>
        </div>

        {/* Authorize New Admin */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <div className="flex items-center gap-2 text-emerald-400 font-bold text-sm mb-4">
            <UserPlus className="w-5 h-5" />
            <h3>Grant Admin Privileges</h3>
          </div>

          {successMsg && (
            <div className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}

          <form onSubmit={handleCreateAdmin} className="space-y-3 text-xs">
            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Admin UID (Firebase Auth UID)
              </label>
              <input
                type="text"
                value={newUid}
                onChange={(e) => setNewUid(e.target.value)}
                placeholder="User UID from Firebase Auth"
                required
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Admin Email
              </label>
              <input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="newadmin@trucklink.ai"
                required
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Display Name
              </label>
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Full Name"
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-400 uppercase tracking-wider mb-1">
                Role Permission
              </label>
              <select
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as any)}
                className="w-full px-3 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-white focus:outline-none focus:border-brand-500"
              >
                <option value="admin">Admin (Full Operational Controls)</option>
                <option value="moderator">Moderator (Read-Only & Dispatch)</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={addingAdmin}
              className="w-full mt-2 py-2.5 bg-brand-600 hover:bg-brand-500 text-white font-bold rounded-xl shadow-md transition-colors"
            >
              {addingAdmin ? 'Saving...' : 'Authorize Admin'}
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
              {adminsList.map((a) => (
                <tr key={a.uid} className="hover:bg-slate-800/30">
                  <td className="py-3 px-4">
                    <p className="font-bold text-white">{a.displayName || 'Administrator'}</p>
                    <p className="text-slate-400">{a.email}</p>
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
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
