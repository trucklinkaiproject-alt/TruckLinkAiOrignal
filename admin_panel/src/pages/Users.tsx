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
          <div className="w-8 h-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-slate-700 overflow-hidden shrink-0">
            {u.profileImage || u.profilePicUrl ? (
              <img src={u.profileImage || u.profilePicUrl} alt={u.name || 'User'} className="w-full h-full object-cover" />
            ) : (
              (u.name || u.fullName || 'U').charAt(0).toUpperCase()
            )}
          </div>
          <div>
            <p className="font-semibold text-slate-900 text-xs">{u.name || u.fullName || 'Unnamed User'}</p>
            <p className="text-[11px] text-slate-500 font-mono">{u.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'email',
      header: 'Contact Email',
      sortable: true,
      render: (u) => <span className="text-slate-700 text-xs">{u.email || '—'}</span>,
    },
    {
      key: 'phone',
      header: 'Phone',
      render: (u) => <span className="text-slate-700 text-xs">{u.phone || u.phoneNumber || '—'}</span>,
    },
    {
      key: 'role',
      header: 'Role',
      render: (u) => (
        <span className="text-xs font-medium uppercase tracking-wider text-slate-600">
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
    <div className="space-y-5">
      {/* Page Heading */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <UsersIcon className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Users & Customers</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Manage registered users, view profile records, and regulate platform access.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-600 bg-white px-3 py-1.5 rounded-md border border-slate-200 shadow-2xs">
          <span className="w-2 h-2 rounded-full bg-emerald-500" />
          <span>Total Records: <strong className="text-slate-900">{users.length}</strong></span>
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
          <div className="flex items-center gap-1">
            <button
              onClick={() => {
                setSelectedUser(u);
                setIsDetailOpen(true);
              }}
              title="View Details"
              className="p-1.5 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 transition-colors shadow-2xs"
            >
              <Eye className="w-3.5 h-3.5 text-sky-700" />
            </button>
            <button
              onClick={() => handleToggleBlock(u)}
              disabled={actionLoading}
              title={u.status === 'blocked' ? 'Unblock User' : 'Block User'}
              className={`p-1.5 rounded-md border transition-colors shadow-2xs ${
                u.status === 'blocked'
                  ? 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                  : 'border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100'
              }`}
            >
              {u.status === 'blocked' ? (
                <CheckCircle className="w-3.5 h-3.5" />
              ) : (
                <Ban className="w-3.5 h-3.5" />
              )}
            </button>
            <button
              onClick={() => {
                setSelectedUser(u);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Record"
              className="p-1.5 rounded-md border border-rose-200 bg-rose-50 hover:bg-rose-100 text-rose-700 transition-colors shadow-2xs"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
      />

      {/* User Details Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="User Profile Record"
        maxWidth="lg"
      >
        {selectedUser && (
          <div className="space-y-5">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-200">
              <div className="w-14 h-14 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xl text-slate-700 overflow-hidden shrink-0">
                {selectedUser.profileImage || selectedUser.profilePicUrl ? (
                  <img src={selectedUser.profileImage || selectedUser.profilePicUrl} alt={selectedUser.name} className="w-full h-full object-cover" />
                ) : (
                  (selectedUser.name || 'U').charAt(0).toUpperCase()
                )}
              </div>
              <div>
                <h4 className="text-base font-bold text-slate-900">
                  {selectedUser.name || selectedUser.fullName || 'Unnamed User'}
                </h4>
                <p className="text-xs font-mono text-slate-500">UID: {selectedUser.id}</p>
                <div className="mt-1 flex items-center gap-2">
                  <Badge variant={selectedUser.status === 'blocked' ? 'danger' : 'success'}>
                    {selectedUser.status === 'blocked' ? 'Blocked' : 'Active'}
                  </Badge>
                  <span className="text-xs text-slate-500 font-medium">Role: {selectedUser.role || 'User'}</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Mail className="w-3.5 h-3.5 text-slate-400" /> Email Address
                </span>
                <p className="text-slate-900 font-medium">{selectedUser.email || '—'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone Number
                </span>
                <p className="text-slate-900 font-medium">{selectedUser.phone || selectedUser.phoneNumber || '—'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Address / Location
                </span>
                <p className="text-slate-900 font-medium">{selectedUser.address || 'No registered street address'}</p>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-md text-xs font-semibold shadow-2xs"
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
          <div className="p-3.5 rounded-md bg-rose-50 border border-rose-200 flex items-start gap-3">
            <ShieldAlert className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div>
              <h4 className="text-xs font-bold text-rose-900">Permanent Firestore Deletion</h4>
              <p className="text-xs text-rose-700 mt-0.5">
                Are you sure you want to delete the user document for{' '}
                <strong className="font-semibold text-rose-950">{selectedUser?.name || selectedUser?.email}</strong>? This will remove their record from Firestore.
              </p>
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-md text-xs font-semibold shadow-2xs"
            >
              Cancel
            </button>
            <button
              onClick={handleDelete}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-rose-700 hover:bg-rose-800 text-white rounded-md text-xs font-semibold shadow-2xs transition-colors"
            >
              {actionLoading ? 'Deleting...' : 'Confirm Delete'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
