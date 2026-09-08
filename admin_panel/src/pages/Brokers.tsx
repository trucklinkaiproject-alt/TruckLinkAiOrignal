import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import {
  subscribeBrokers,
  updateBrokerStatus,
  verifyBroker,
  deleteBrokerDoc
} from '../services/firestoreService';
import { BrokerProfile } from '../types/models';
import { useAuth } from '../context/AuthContext';
import {
  Briefcase,
  CheckCircle2,
  XCircle,
  Ban,
  Trash2,
  Eye,
  Star,
  Building,
  Phone,
  Mail,
  MapPin,
  ShieldCheck
} from 'lucide-react';

export const Brokers: React.FC = () => {
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBroker, setSelectedBroker] = useState<BrokerProfile | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    const unsub = subscribeBrokers((data) => {
      setBrokers(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleToggleVerify = async (broker: BrokerProfile) => {
    setActionLoading(true);
    try {
      await verifyBroker(broker.id, !broker.isVerified, adminEmail);
    } catch (err) {
      console.error('Failed to update verification:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleBlock = async (broker: BrokerProfile) => {
    const newStatus = broker.status === 'blocked' ? 'active' : 'blocked';
    setActionLoading(true);
    try {
      await updateBrokerStatus(broker.id, newStatus, adminEmail);
    } catch (err) {
      console.error('Failed to update status:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedBroker) return;
    setActionLoading(true);
    try {
      await deleteBrokerDoc(selectedBroker.id, adminEmail);
      setIsDeleteModalOpen(false);
      setSelectedBroker(null);
    } catch (err) {
      console.error('Failed to delete broker:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<BrokerProfile>[] = [
    {
      key: 'companyName',
      header: 'Brokerage / Company',
      sortable: true,
      render: (b) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center font-bold text-purple-400 overflow-hidden">
            {b.profileImage ? (
              <img src={b.profileImage} alt={b.companyName || b.name} className="w-full h-full object-cover" />
            ) : (
              <Building className="w-5 h-5 text-purple-400" />
            )}
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <p className="font-semibold text-white">{b.companyName || b.name || 'Unnamed Broker'}</p>
              {b.isVerified && (
                <span title="Verified Broker">
                  <ShieldCheck className="w-4 h-4 text-sky-400" />
                </span>
              )}
            </div>
            <p className="text-xs text-slate-400 font-mono">{b.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'name',
      header: 'Contact Person',
      render: (b) => b.name || b.fullName || '—',
    },
    {
      key: 'email',
      header: 'Email / Phone',
      render: (b) => (
        <div className="text-xs">
          <p className="text-slate-200">{b.email || '—'}</p>
          <p className="text-slate-500">{b.phone || '—'}</p>
        </div>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      sortable: true,
      render: (b) => (
        <div className="flex items-center gap-1 text-amber-400 font-semibold text-xs">
          <Star className="w-3.5 h-3.5 fill-amber-400" />
          <span>{b.rating ? Number(b.rating).toFixed(1) : '5.0'}</span>
        </div>
      ),
    },
    {
      key: 'isVerified',
      header: 'Verification',
      sortable: true,
      render: (b) => (
        <Badge variant={b.isVerified ? 'info' : 'neutral'}>
          {b.isVerified ? 'Verified Partner' : 'Unverified'}
        </Badge>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (b) => (
        <Badge variant={b.status === 'blocked' ? 'danger' : 'success'}>
          {b.status === 'blocked' ? 'Blocked' : 'Active'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Briefcase className="w-6 h-6 text-purple-400" />
            <h2 className="text-2xl font-black text-white">Freight Brokers & Transporters</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Review freight companies, toggle verification badges, and manage driver networks.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
            <span>Verified: <strong className="text-sky-400">{brokers.filter((b) => b.isVerified).length}</strong> / {brokers.length}</span>
          </div>
        </div>
      </div>

      <DataTable
        data={brokers}
        columns={columns}
        searchPlaceholder="Search brokers by company, name, email, address..."
        searchFields={['companyName', 'name', 'email', 'phone', 'address', 'id']}
        loading={loading}
        emptyMessage="No freight brokers found in Firestore 'Broker' collection"
        actions={(b) => (
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => {
                setSelectedBroker(b);
                setIsDetailOpen(true);
              }}
              title="Inspect Broker"
              className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
            >
              <Eye className="w-4 h-4 text-purple-400" />
            </button>
            <button
              onClick={() => handleToggleVerify(b)}
              disabled={actionLoading}
              title={b.isVerified ? 'Revoke Verification' : 'Grant Verification'}
              className={`p-1.5 rounded-lg transition-colors ${
                b.isVerified
                  ? 'bg-sky-500/20 text-sky-400 hover:bg-sky-500/30'
                  : 'bg-slate-800 hover:bg-slate-700 text-slate-400'
              }`}
            >
              <ShieldCheck className="w-4 h-4" />
            </button>
            <button
              onClick={() => handleToggleBlock(b)}
              disabled={actionLoading}
              title={b.status === 'blocked' ? 'Unblock Broker' : 'Block Broker'}
              className={`p-1.5 rounded-lg transition-colors ${
                b.status === 'blocked'
                  ? 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30'
                  : 'bg-amber-500/20 text-amber-400 hover:bg-amber-500/30'
              }`}
            >
              {b.status === 'blocked' ? <CheckCircle2 className="w-4 h-4" /> : <Ban className="w-4 h-4" />}
            </button>
            <button
              onClick={() => {
                setSelectedBroker(b);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Broker"
              className="p-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 text-rose-400 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        )}
      />

      {/* Broker Inspection Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Freight Brokerage Details"
        maxWidth="lg"
      >
        {selectedBroker && (
          <div className="space-y-6">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-800">
              <div className="w-16 h-16 rounded-2xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-center font-bold text-2xl text-purple-400 overflow-hidden">
                {selectedBroker.profileImage ? (
                  <img src={selectedBroker.profileImage} alt={selectedBroker.companyName} className="w-full h-full object-cover" />
                ) : (
                  <Building className="w-8 h-8" />
                )}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h4 className="text-lg font-bold text-white">
                    {selectedBroker.companyName || selectedBroker.name || 'Unnamed Broker'}
                  </h4>
                  {selectedBroker.isVerified && (
                    <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-300 border border-sky-500/30">
                      Verified
                    </span>
                  )}
                </div>
                <p className="text-xs font-mono text-purple-400">UID: {selectedBroker.id}</p>
                <div className="mt-1 flex items-center gap-2 text-xs">
                  <span className="text-slate-400">Contact: <strong>{selectedBroker.name || '—'}</strong></span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Mail className="w-3.5 h-3.5 text-slate-400" /> Email
                </span>
                <p className="text-slate-200 font-medium">{selectedBroker.email || '—'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone
                </span>
                <p className="text-slate-200 font-medium">{selectedBroker.phone || '—'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Operational Hub / Address
                </span>
                <p className="text-slate-200 font-medium">{selectedBroker.address || 'No location registered'}</p>
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
        title="Delete Broker Record"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-sm text-slate-300">
            Are you sure you want to permanently remove broker{' '}
            <strong className="text-white">{selectedBroker?.companyName || selectedBroker?.name}</strong> from Firestore?
          </p>
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
