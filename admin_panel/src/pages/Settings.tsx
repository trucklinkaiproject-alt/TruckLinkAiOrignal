import React, { useEffect, useState } from 'react';
import { Settings as SettingsIcon, Shield, UserPlus, Server, CheckCircle2, User } from 'lucide-react';
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
    <div className="space-y-6">
      <div className="border-b border-slate-200 pb-5">
        <div className="flex items-center gap-2">
          <SettingsIcon className="w-5 h-5 text-sky-700" />
          <h2 className="text-xl font-bold text-slate-900">Platform Settings & Admin Access</h2>
        </div>
        <p className="text-xs text-slate-500 mt-1">
          Configure TruckLink AI engine parameters, security policies, and manage administrative privileges.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Firebase Cluster Info */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs space-y-4">
          <div className="flex items-center gap-2 text-slate-900 font-bold text-sm pb-3 border-b border-slate-100">
            <Server className="w-4 h-4 text-sky-700" />
            <h3>Active Firebase Environment</h3>
          </div>

          <div className="space-y-3 text-xs">
            <div className="p-3 bg-slate-50 rounded-md border border-slate-200">
              <span className="text-slate-500 font-semibold uppercase text-[11px]">Project ID</span>
              <p className="font-mono text-slate-900 font-semibold mt-0.5">trucklink-ai-orignal</p>
            </div>

            <div className="p-3 bg-slate-50 rounded-md border border-slate-200">
              <span className="text-slate-500 font-semibold uppercase text-[11px]">Auth Domain</span>
              <p className="font-mono text-slate-700 mt-0.5">trucklink-ai-orignal.firebaseapp.com</p>
            </div>

            <div className="p-3 bg-slate-50 rounded-md border border-slate-200">
              <span className="text-slate-500 font-semibold uppercase text-[11px]">Cloud Firestore Cluster</span>
              <p className="text-emerald-700 font-semibold mt-0.5 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
                Multi-Region Active Sync
              </p>
            </div>
          </div>
        </div>

        {/* Current Admin Account Card */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs space-y-4">
          <div className="flex items-center gap-2 text-slate-900 font-bold text-sm pb-3 border-b border-slate-100">
            <Shield className="w-4 h-4 text-sky-700" />
            <h3>Your Admin Profile</h3>
          </div>

          <div className="p-4 rounded-md bg-slate-50 border border-slate-200 space-y-3 text-xs">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-sm bg-sky-100 text-sky-800 font-bold flex items-center justify-center border border-sky-200">
                <User className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-slate-900 text-sm">{adminProfile?.displayName || 'System Admin'}</h4>
                <p className="text-slate-500 font-mono text-[11px]">{adminProfile?.email}</p>
              </div>
            </div>

            <div className="pt-2 border-t border-slate-200 flex items-center justify-between">
              <span className="text-slate-600">Assigned Role:</span>
              <Badge variant="purple" size="sm">{adminProfile?.role || 'Super Admin'}</Badge>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-slate-600">Account Status:</span>
              <Badge variant="success" size="sm">Active</Badge>
            </div>
          </div>
        </div>

        {/* Authorize New Admin */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs">
          <div className="flex items-center gap-2 text-slate-900 font-bold text-sm mb-4 pb-3 border-b border-slate-100">
            <UserPlus className="w-4 h-4 text-sky-700" />
            <h3>Grant Admin Privileges</h3>
          </div>

          {successMsg && (
            <div className="mb-4 p-3 rounded-md bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-600" />
              <span>{successMsg}</span>
            </div>
          )}

          <form onSubmit={handleCreateAdmin} className="space-y-3 text-xs">
            <div>
              <label className="block font-semibold text-slate-700 uppercase tracking-wider text-[11px] mb-1">
                Admin UID (Firebase Auth UID)
              </label>
              <input
                type="text"
                value={newUid}
                onChange={(e) => setNewUid(e.target.value)}
                placeholder="User UID from Firebase Auth"
                required
                className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-sky-700 focus:border-sky-700"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-700 uppercase tracking-wider text-[11px] mb-1">
                Admin Email
              </label>
              <input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="newadmin@trucklink.ai"
                required
                className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-sky-700 focus:border-sky-700"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-700 uppercase tracking-wider text-[11px] mb-1">
                Display Name
              </label>
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Full Name"
                className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-sky-700 focus:border-sky-700"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-700 uppercase tracking-wider text-[11px] mb-1">
                Role Permission
              </label>
              <select
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as any)}
                className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-slate-900 focus:outline-none focus:ring-1 focus:ring-sky-700 focus:border-sky-700"
              >
                <option value="admin">Admin (Full Operational Controls)</option>
                <option value="moderator">Moderator (Read-Only & Dispatch)</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={addingAdmin}
              className="w-full mt-2 py-2 bg-sky-700 hover:bg-sky-800 disabled:opacity-50 text-white font-medium rounded-md shadow-2xs transition-colors"
            >
              {addingAdmin ? 'Saving...' : 'Authorize Admin'}
            </button>
          </form>
        </div>
      </div>

      {/* Admins Registry Table */}
      <div className="rounded-lg bg-white border border-slate-200 shadow-2xs overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200">
          <h3 className="text-sm font-bold text-slate-900">Authorized System Administrators</h3>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-600 uppercase tracking-wider text-[11px] font-semibold border-b border-slate-200">
              <tr>
                <th className="py-3 px-6">Admin Name & Email</th>
                <th className="py-3 px-6">Firebase UID</th>
                <th className="py-3 px-6">Role</th>
                <th className="py-3 px-6">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {adminsList.map((a) => (
                <tr key={a.uid} className="hover:bg-slate-50/70 transition-colors">
                  <td className="py-3.5 px-6">
                    <p className="font-semibold text-slate-900">{a.displayName || 'Administrator'}</p>
                    <p className="text-slate-500">{a.email}</p>
                  </td>
                  <td className="py-3.5 px-6 font-mono text-sky-700 text-xs">{a.uid}</td>
                  <td className="py-3.5 px-6">
                    <Badge variant={a.role === 'superadmin' ? 'purple' : 'info'} size="sm">
                      {a.role || 'admin'}
                    </Badge>
                  </td>
                  <td className="py-3.5 px-6">
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
