import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import {
  subscribeUsers,
  updateUserStatus,
  deleteUserDoc
} from '../services/firestoreService';
import { UserProfile } from '../types/models';
import { useAuth } from '../context/AuthContext';
import { Users as UsersIcon, Ban, CheckCircle, Trash2, Eye, ShieldAlert, Phone, Mail, MapPin } from 'lucide-react';

export const Users: React.FC = () => {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    const unsub = subscribeUsers((data) => {
      setUsers(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleToggleBlock = async (user: UserProfile) => {
    const newStatus = user.status === 'blocked' ? 'active' : 'blocked';
    setActionLoading(true);
    try {
      await updateUserStatus(user.id, newStatus, adminEmail);
    } catch (err) {
      console.error('Failed to update status:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await deleteUserDoc(selectedUser.id, adminEmail);
      setIsDeleteModalOpen(false);
      setSelectedUser(null);
    } catch (err) {
      console.error('Failed to delete user:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<UserProfile>[] = [
    {
      key: 'name',
      header: 'User',
      sortable: true,
      render: (u) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-sky-400 overflow-hidden">
            {u.profileImage || u.profilePicUrl ? (
              <img src={u.profileImage || u.profilePicUrl} alt={u.name || 'User'} className="w-full h-full object-cover" />
            ) : (
              (u.name || u.fullName || 'U').charAt(0).toUpperCase()
            )}
          </div>
          <div>
            <p className="font-semibold text-white">{u.name || u.fullName || 'Unnamed User'}</p>
            <p className="text-xs text-slate-400 font-mono">{u.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'email',
      header: 'Contact Email',
      sortable: true,
      render: (u) => u.email || '—',
    },
    {
      key: 'phone',
      header: 'Phone',
      render: (u) => u.phone || u.phoneNumber || '—',
    },
    {
      key: 'role',
      header: 'Role',
      render: (u) => (
        <span className="text-xs font-semibold uppercase tracking-wider text-slate-300">
          {u.role || 'User'}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (u) => (
        <Badge variant={u.status === 'blocked' ? 'danger' : 'success'}>
          {u.status === 'blocked' ? 'Blocked' : 'Active'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Page Heading */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <UsersIcon className="w-6 h-6 text-sky-400" />
            <h2 className="text-2xl font-black text-white">Users & Customers</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Manage registered users, view active load requests, and regulate platform access.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>Total Users: <strong className="text-white">{users.length}</strong></span>
        </div>
      </div>

      {/* Main Table */}
      <DataTable
        data={users}
        columns={columns}
        searchPlaceholder="Search users by name, email, phone, UID..."
        searchFields={['name', 'fullName', 'email', 'phone', 'phoneNumber', 'id']}
        loading={loading}
        emptyMessage="No users found in Firestore 'User' collection"
        actions={(u) => (
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => {
                setSelectedUser(u);
                setIsDetailOpen(true);
              }}
              title="View Details"
              className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
            >
              <Eye className="w-4 h-4 text-sky-400" />
            </button>
            <button
              onClick={() => handleToggleBlock(u)}
              disabled={actionLoading}
              title={u.status === 'blocked' ? 'Unblock User' : 'Block User'}
              className={`p-1.5 rounded-lg transition-colors ${
                u.status === 'blocked'
                  ? 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30'
                  : 'bg-amber-500/20 text-amber-400 hover:bg-amber-500/30'
              }`}
            >
              {u.status === 'blocked' ? (
                <CheckCircle className="w-4 h-4" />
              ) : (
                <Ban className="w-4 h-4" />
              )}
            </button>
            <button
              onClick={() => {
                setSelectedUser(u);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Record"
              className="p-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 text-rose-400 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        )}
      />

      {/* User Details Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="User Profile Details"
        maxWidth="lg"
      >
        {selectedUser && (
          <div className="space-y-6">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-800">
              <div className="w-16 h-16 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-2xl text-sky-400 overflow-hidden">
                {selectedUser.profileImage || selectedUser.profilePicUrl ? (
                  <img src={selectedUser.profileImage || selectedUser.profilePicUrl} alt={selectedUser.name} className="w-full h-full object-cover" />
                ) : (
                  (selectedUser.name || 'U').charAt(0).toUpperCase()
                )}
              </div>
              <div>
                <h4 className="text-lg font-bold text-white">
                  {selectedUser.name || selectedUser.fullName || 'Unnamed User'}
                </h4>
                <p className="text-xs font-mono text-sky-400">UID: {selectedUser.id}</p>
                <div className="mt-1 flex items-center gap-2">
                  <Badge variant={selectedUser.status === 'blocked' ? 'danger' : 'success'}>
                    {selectedUser.status === 'blocked' ? 'Blocked' : 'Active'}
                  </Badge>
                  <span className="text-xs text-slate-400">Role: {selectedUser.role || 'User'}</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Mail className="w-3.5 h-3.5 text-slate-400" /> Email
                </span>
                <p className="text-slate-200 font-medium">{selectedUser.email || '—'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone
                </span>
                <p className="text-slate-200 font-medium">{selectedUser.phone || selectedUser.phoneNumber || '—'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Address / Location
                </span>
                <p className="text-slate-200 font-medium">{selectedUser.address || 'No registered street address'}</p>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-800 flex justify-end gap-3">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
            </div>
          </div>
        )}
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        title="Confirm User Document Removal"
        maxWidth="md"
      >
        <div className="space-y-4">
          <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-3">
            <ShieldAlert className="w-6 h-6 text-rose-400 shrink-0 mt-0.5" />
            <div>
              <h4 className="text-sm font-bold text-rose-200">Permanent Firestore Deletion</h4>
              <p className="text-xs text-rose-300/80 mt-1">
                Are you sure you want to delete the user document for{' '}
                <strong className="text-white">{selectedUser?.name || selectedUser?.email}</strong>? This will remove their record from Firestore.
              </p>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              disabled={actionLoading}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              onClick={handleDelete}
              disabled={actionLoading}
              className="px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-xl text-xs font-semibold transition-colors"
            >
              {actionLoading ? 'Deleting...' : 'Confirm Delete'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
