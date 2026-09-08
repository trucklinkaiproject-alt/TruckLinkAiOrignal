import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import {
  subscribeOrders,
  updateOrderStatus
} from '../services/firestoreService';
import { OrderItem } from '../types/models';
import { useAuth } from '../context/AuthContext';
import {
  Package,
  Eye,
  Edit,
  CheckCircle,
  Clock,
  MapPin,
  DollarSign,
  Truck,
  User,
  Building
} from 'lucide-react';

export const Orders: React.FC = () => {
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<OrderItem | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isEditStatusOpen, setIsEditStatusOpen] = useState(false);
  const [newStatus, setNewStatus] = useState<string>('delivered');
  const [actionLoading, setActionLoading] = useState(false);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    const unsub = subscribeOrders((data) => {
      setOrders(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleUpdateStatus = async () => {
    if (!selectedOrder) return;
    setActionLoading(true);
    try {
      await updateOrderStatus(selectedOrder.id, newStatus, adminEmail);
      setIsEditStatusOpen(false);
    } catch (err) {
      console.error('Failed to update order status:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<OrderItem>[] = [
    {
      key: 'id',
      header: 'Order Reference',
      sortable: true,
      render: (o) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center font-bold text-emerald-400">
            <Package className="w-5 h-5 text-emerald-400" />
          </div>
          <div>
            <p className="font-mono font-bold text-white text-xs">{o.id.substring(0, 10)}...</p>
            <p className="text-xs text-slate-400">{o.cargoType || 'Freight Shipment'}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'price',
      header: 'Fare Amount',
      sortable: true,
      render: (o) => (
        <span className="font-mono font-bold text-emerald-400 text-xs">
          {o.price ? `PKR ${o.price}` : 'PKR —'}
        </span>
      ),
    },
    {
      key: 'route',
      header: 'Origin → Destination',
      render: (o) => (
        <div className="text-xs max-w-xs truncate text-slate-300">
          <span>{o.pickupLocation || 'Origin'}</span>
          <span className="text-slate-500 mx-1.5">→</span>
          <span>{o.dropoffLocation || 'Destination'}</span>
        </div>
      ),
    },
    {
      key: 'driverName',
      header: 'Driver / Broker',
      render: (o) => (
        <div className="text-xs">
          <p className="text-white font-medium">{o.driverName || 'Driver unassigned'}</p>
          <p className="text-slate-500">{o.brokerName || 'Direct'}</p>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Trip Status',
      sortable: true,
      render: (o) => (
        <Badge
          variant={
            o.status === 'delivered' || o.status === 'completed'
              ? 'success'
              : o.status === 'in_transit' || o.status === 'in-transit' || o.status === 'assigned'
              ? 'info'
              : o.status === 'cancelled'
              ? 'danger'
              : 'warning'
          }
        >
          {o.status || 'Pending'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Package className="w-6 h-6 text-emerald-400" />
            <h2 className="text-2xl font-black text-white">Shipments & Orders Registry</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Real-time telemetry and life-cycle management of all active and completed freight consignments.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
            <span>Total Logged Orders: <strong className="text-emerald-400">{orders.length}</strong></span>
          </div>
        </div>
      </div>

      <DataTable
        data={orders}
        columns={columns}
        searchPlaceholder="Search orders by ID, cargo, route, driver..."
        searchFields={['id', 'cargoType', 'pickupLocation', 'dropoffLocation', 'driverName', 'brokerName', 'status']}
        loading={loading}
        emptyMessage="No orders found in Firestore 'Orders' collection"
        actions={(o) => (
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => {
                setSelectedOrder(o);
                setIsDetailOpen(true);
              }}
              title="Inspect Order"
              className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
            >
              <Eye className="w-4 h-4 text-emerald-400" />
            </button>
            <button
              onClick={() => {
                setSelectedOrder(o);
                setNewStatus(o.status || 'in_transit');
                setIsEditStatusOpen(true);
              }}
              title="Update Status"
              className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
            >
              <Edit className="w-4 h-4 text-sky-400" />
            </button>
          </div>
        )}
      />

      {/* Order Details Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Freight Order Dossier"
        maxWidth="lg"
      >
        {selectedOrder && (
          <div className="space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-slate-800">
              <div>
                <p className="text-xs font-mono text-emerald-400">Order ID: {selectedOrder.id}</p>
                <h4 className="text-base font-bold text-white mt-0.5">
                  {selectedOrder.cargoType || 'Freight Shipment'}
                </h4>
              </div>
              <Badge
                variant={
                  selectedOrder.status === 'delivered' || selectedOrder.status === 'completed'
                    ? 'success'
                    : 'info'
                }
              >
                {selectedOrder.status || 'Pending'}
              </Badge>
            </div>

            <div className="space-y-4 text-xs">
              <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 space-y-3">
                <div className="flex items-start gap-2.5">
                  <div className="w-3 h-3 rounded-full bg-emerald-400 shrink-0 mt-0.5" />
                  <div>
                    <span className="text-slate-500 font-semibold uppercase">Pickup Origin</span>
                    <p className="text-slate-200 font-medium text-sm mt-0.5">
                      {selectedOrder.pickupLocation || 'Origin'}
                    </p>
                  </div>
                </div>

                <div className="border-l-2 border-dashed border-slate-800 ml-1.5 h-4" />

                <div className="flex items-start gap-2.5">
                  <div className="w-3 h-3 rounded-full bg-rose-400 shrink-0 mt-0.5" />
                  <div>
                    <span className="text-slate-500 font-semibold uppercase">Destination Dropoff</span>
                    <p className="text-slate-200 font-medium text-sm mt-0.5">
                      {selectedOrder.dropoffLocation || 'Destination'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Driver</span>
                  <p className="text-slate-200 font-medium mt-0.5">{selectedOrder.driverName || 'Unassigned'}</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Broker</span>
                  <p className="text-slate-200 font-medium mt-0.5">{selectedOrder.brokerName || 'Direct Shipper'}</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
                  <span className="text-slate-500 font-semibold uppercase">Fare Amount</span>
                  <p className="text-emerald-400 font-bold mt-0.5">
                    {selectedOrder.price ? `PKR ${selectedOrder.price}` : 'PKR —'}
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

      {/* Edit Order Status Modal */}
      <Modal
        isOpen={isEditStatusOpen}
        onClose={() => setIsEditStatusOpen(false)}
        title="Update Shipment Order Status"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-400">
            Select a new operational status for Order <strong className="text-white font-mono">{selectedOrder?.id}</strong>:
          </p>

          <select
            value={newStatus}
            onChange={(e) => setNewStatus(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-brand-500"
          >
            <option value="pending">pending</option>
            <option value="assigned">assigned</option>
            <option value="picked_up">picked_up</option>
            <option value="in_transit">in_transit</option>
            <option value="delivered">delivered</option>
            <option value="cancelled">cancelled</option>
          </select>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
            <button
              onClick={() => setIsEditStatusOpen(false)}
              disabled={actionLoading}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              onClick={handleUpdateStatus}
              disabled={actionLoading}
              className="px-4 py-2 bg-brand-600 hover:bg-brand-500 text-white rounded-xl text-xs font-semibold transition-colors"
            >
              {actionLoading ? 'Updating...' : 'Save New Status'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
