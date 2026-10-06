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
          <div className="w-8 h-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-slate-700 overflow-hidden shrink-0">
            {b.profileImage ? (
              <img src={b.profileImage} alt={b.companyName || b.name} className="w-full h-full object-cover" />
            ) : (
              <Building className="w-4 h-4 text-slate-600" />
            )}
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <p className="font-semibold text-slate-900 text-xs">{b.companyName || b.name || 'Unnamed Broker'}</p>
              {b.isVerified && (
                <span title="Verified Partner">
                  <ShieldCheck className="w-3.5 h-3.5 text-sky-700" />
                </span>
              )}
            </div>
            <p className="text-[11px] text-slate-500 font-mono">{b.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'name',
      header: 'Contact Person',
      render: (b) => <span className="text-slate-700 text-xs">{b.name || b.fullName || '—'}</span>,
    },
    {
      key: 'email',
      header: 'Email / Phone',
      render: (b) => (
        <div className="text-xs">
          <p className="text-slate-900">{b.email || '—'}</p>
          <p className="text-slate-500 font-mono text-[11px]">{b.phone || '—'}</p>
        </div>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      sortable: true,
      render: (b) => (
        <div className="flex items-center gap-1 text-amber-600 font-semibold text-xs">
          <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
          <span>{b.rating ? Number(b.rating).toFixed(1) : '—'}</span>
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
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <Briefcase className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Brokers & Freight Partners</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Review broker organizations, toggle verification status, and oversee fleet partnerships.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-600 bg-white px-3 py-1.5 rounded-md border border-slate-200 shadow-2xs">
            <span>Verified Partners: <strong className="text-sky-800">{brokers.filter((b) => b.isVerified).length}</strong> / {brokers.length}</span>
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
          <div className="flex items-center gap-1">
            <button
              onClick={() => {
                setSelectedBroker(b);
                setIsDetailOpen(true);
              }}
              title="Inspect Broker"
              className="p-1.5 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 transition-colors shadow-2xs"
            >
              <Eye className="w-3.5 h-3.5 text-sky-700" />
            </button>
            <button
              onClick={() => handleToggleVerify(b)}
              disabled={actionLoading}
              title={b.isVerified ? 'Revoke Verification' : 'Grant Verification'}
              className={`p-1.5 rounded-md border transition-colors shadow-2xs ${
                b.isVerified
                  ? 'border-sky-200 bg-sky-50 text-sky-700 hover:bg-sky-100'
                  : 'border-slate-200 bg-white hover:bg-slate-50 text-slate-500'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => handleToggleBlock(b)}
              disabled={actionLoading}
              title={b.status === 'blocked' ? 'Unblock Broker' : 'Block Broker'}
              className={`p-1.5 rounded-md border transition-colors shadow-2xs ${
                b.status === 'blocked'
                  ? 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                  : 'border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100'
              }`}
            >
              {b.status === 'blocked' ? <CheckCircle2 className="w-3.5 h-3.5" /> : <Ban className="w-3.5 h-3.5" />}
            </button>
            <button
              onClick={() => {
                setSelectedBroker(b);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Broker"
              className="p-1.5 rounded-md border border-rose-200 bg-rose-50 hover:bg-rose-100 text-rose-700 transition-colors shadow-2xs"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
      />

      {/* Broker Inspection Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Freight Brokerage Dossier"
        maxWidth="lg"
      >
        {selectedBroker && (
          <div className="space-y-5">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-200">
              <div className="w-14 h-14 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xl text-slate-700 overflow-hidden shrink-0">
                {selectedBroker.profileImage ? (
                  <img src={selectedBroker.profileImage} alt={selectedBroker.companyName} className="w-full h-full object-cover" />
                ) : (
                  <Building className="w-6 h-6 text-slate-600" />
                )}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h4 className="text-base font-bold text-slate-900">
                    {selectedBroker.companyName || selectedBroker.name || 'Unnamed Broker'}
                  </h4>
                  {selectedBroker.isVerified && (
                    <span className="text-[10px] font-semibold px-2 py-0.5 rounded border border-sky-200 bg-sky-50 text-sky-800">
                      Verified
                    </span>
                  )}
                </div>
                <p className="text-xs font-mono text-slate-500">UID: {selectedBroker.id}</p>
                <div className="mt-1 flex items-center gap-2 text-xs">
                  <span className="text-slate-500">Contact: <strong className="text-slate-800">{selectedBroker.name || '—'}</strong></span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Mail className="w-3.5 h-3.5 text-slate-400" /> Email Address
                </span>
                <p className="text-slate-900 font-medium">{selectedBroker.email || '—'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone Number
                </span>
                <p className="text-slate-900 font-medium">{selectedBroker.phone || '—'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Operational Hub / Address
                </span>
                <p className="text-slate-900 font-medium">{selectedBroker.address || 'No location registered'}</p>
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
        title="Delete Broker Record"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-600">
            Are you sure you want to permanently remove broker{' '}
            <strong className="font-semibold text-slate-900">{selectedBroker?.companyName || selectedBroker?.name}</strong> from Firestore?
          </p>
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
