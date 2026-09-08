import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import { fetchAllRequests } from '../services/firestoreService';
import { UserRequest } from '../types/models';
import {
  FileText,
  Eye,
  MapPin,
  Package,
  Calendar,
  DollarSign,
  Truck,
  RefreshCw
} from 'lucide-react';

export const Requests: React.FC = () => {
  const [requests, setRequests] = useState<UserRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReq, setSelectedReq] = useState<UserRequest | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);

  const loadRequests = async () => {
    setLoading(true);
    try {
      const data = await fetchAllRequests();
      setRequests(data);
    } catch (err) {
      console.error('Failed to load user requests:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, []);

  const columns: Column<UserRequest>[] = [
    {
      key: 'id',
      header: 'Request Ref',
      sortable: true,
      render: (r) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center font-bold text-amber-400">
            <FileText className="w-5 h-5 text-amber-400" />
          </div>
          <div>
            <p className="font-mono font-bold text-white text-xs">{r.id.substring(0, 10)}...</p>
            <p className="text-xs text-slate-400">{r.userName || 'Shipper'}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'cargoType',
      header: 'Cargo / Weight',
      sortable: true,
      render: (r) => (
        <div>
          <span className="font-medium text-white">{r.cargoType || 'General Freight'}</span>
          <p className="text-xs text-slate-400">{r.weight ? `${r.weight} kg/tons` : 'Weight unspec.'}</p>
        </div>
      ),
    },
    {
      key: 'route',
      header: 'Origin → Destination',
      render: (r) => (
        <div className="text-xs max-w-xs">
          <div className="flex items-center gap-1 text-slate-300 truncate">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shrink-0" />
            <span className="truncate">{r.pickupLocation || 'Pickup location'}</span>
          </div>
          <div className="flex items-center gap-1 text-slate-400 truncate mt-0.5">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-400 shrink-0" />
            <span className="truncate">{r.dropoffLocation || 'Dropoff location'}</span>
          </div>
        </div>
      ),
    },
    {
      key: 'budget',
      header: 'Budget / Offer',
      sortable: true,
      render: (r) => (
        <span className="font-mono font-bold text-emerald-400 text-xs">
          {r.budget ? `PKR ${r.budget}` : 'Market Quote'}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      render: (r) => (
        <Badge
          variant={
            r.status === 'completed'
              ? 'success'
              : r.status === 'in-transit' || r.status === 'accepted'
              ? 'info'
              : r.status === 'cancelled'
              ? 'danger'
              : 'warning'
          }
        >
          {r.status || 'Pending'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <FileText className="w-6 h-6 text-amber-400" />
            <h2 className="text-2xl font-black text-white">Shipper Freight Load Requests</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Incoming transport quotations and load postings created by shippers in the mobile app.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={loadRequests}
            disabled={loading}
            className="inline-flex items-center gap-2 px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-xl border border-slate-700 transition-colors"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            Refresh Requests
          </button>
        </div>
      </div>

      <DataTable
        data={requests}
        columns={columns}
        searchPlaceholder="Search requests by shipper, cargo, route..."
        searchFields={['id', 'userName', 'cargoType', 'pickupLocation', 'dropoffLocation', 'budget']}
        loading={loading}
        emptyMessage="No shipper load requests found in Firestore"
        actions={(r) => (
          <button
            onClick={() => {
              setSelectedReq(r);
              setIsDetailOpen(true);
            }}
            title="Inspect Request"
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
          >
            <Eye className="w-4 h-4 text-amber-400" />
          </button>
        )}
      />

      {/* Request Details Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Freight Load Details & Specifications"
        maxWidth="lg"
      >
        {selectedReq && (
          <div className="space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-slate-800">
              <div>
                <p className="text-xs font-mono text-slate-400">Request ID: {selectedReq.id}</p>
                <h4 className="text-base font-bold text-white mt-0.5">
                  {selectedReq.cargoType || 'General Freight'}
                </h4>
              </div>
              <Badge
                variant={
                  selectedReq.status === 'completed'
                    ? 'success'
                    : selectedReq.status === 'in-transit'
                    ? 'info'
                    : 'warning'
                }
              >
                {selectedReq.status || 'Pending'}
              </Badge>
            </div>

            <div className="space-y-4 text-xs">
              <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-3">
                <div className="flex items-start gap-2.5">
                  <div className="w-3 h-3 rounded-full bg-emerald-400 shrink-0 mt-0.5" />
                  <div>
                    <span className="text-slate-500 font-semibold uppercase">Origin Pickup</span>
                    <p className="text-slate-200 font-medium text-sm mt-0.5">
                      {selectedReq.pickupLocation || 'Unspecified Origin'}
                    </p>
                  </div>
                </div>

                <div className="border-l-2 border-dashed border-slate-800 ml-1.5 h-4" />

                <div className="flex items-start gap-2.5">
                  <div className="w-3 h-3 rounded-full bg-rose-400 shrink-0 mt-0.5" />
                  <div>
                    <span className="text-slate-500 font-semibold uppercase">Destination Dropoff</span>
                    <p className="text-slate-200 font-medium text-sm mt-0.5">
                      {selectedReq.dropoffLocation || 'Unspecified Destination'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Shipper</span>
                  <p className="text-slate-200 font-medium mt-0.5">{selectedReq.userName || 'Shipper'}</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Weight</span>
                  <p className="text-slate-200 font-medium mt-0.5">{selectedReq.weight || '—'}</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Budget</span>
                  <p className="text-emerald-400 font-bold mt-0.5">
                    {selectedReq.budget ? `PKR ${selectedReq.budget}` : 'Quote required'}
                  </p>
                </div>
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
    </div>
  );
};
