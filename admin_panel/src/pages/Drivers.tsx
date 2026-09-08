import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import {
  subscribeDrivers,
  updateDriverStatus,
  deleteDriverDoc
} from '../services/firestoreService';
import { DriverProfile } from '../types/models';
import { useAuth } from '../context/AuthContext';
import {
  Truck,
  Ban,
  CheckCircle2,
  Trash2,
  Eye,
  Star,
  Phone,
  CreditCard,
  FileBadge,
  MapPin,
  Car
} from 'lucide-react';

export const Drivers: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDriver, setSelectedDriver] = useState<DriverProfile | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    const unsub = subscribeDrivers((data) => {
      setDrivers(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleToggleBlock = async (driver: DriverProfile) => {
    const newStatus = driver.status === 'blocked' ? 'active' : 'blocked';
    setActionLoading(true);
    try {
      await updateDriverStatus(driver.id, newStatus, adminEmail);
    } catch (err) {
      console.error('Failed to update driver status:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedDriver) return;
    setActionLoading(true);
    try {
      await deleteDriverDoc(selectedDriver.id, adminEmail);
      setIsDeleteModalOpen(false);
      setSelectedDriver(null);
    } catch (err) {
      console.error('Failed to delete driver:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<DriverProfile>[] = [
    {
      key: 'name',
      header: 'Driver Name / ID',
      sortable: true,
      render: (d) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center font-bold text-cyan-400">
            <Truck className="w-5 h-5 text-cyan-400" />
          </div>
          <div>
            <p className="font-semibold text-white">{d.name || d.fullName || 'Fleet Driver'}</p>
            <p className="text-xs text-slate-400 font-mono">{d.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'phone',
      header: 'Phone / CNIC',
      render: (d) => (
        <div className="text-xs">
          <p className="text-slate-200">{d.phone || '—'}</p>
          <p className="text-slate-500">{d.cnic ? `CNIC: ${d.cnic}` : 'No CNIC'}</p>
        </div>
      ),
    },
    {
      key: 'vehicleType',
      header: 'Vehicle & Reg No.',
      sortable: true,
      render: (d) => (
        <div>
          <span className="font-medium text-white">{d.vehicleType || d.vehicleModel || 'Truck'}</span>
          <p className="text-xs font-mono text-cyan-400">{d.vehicleNumber || '—'}</p>
        </div>
      ),
    },
    {
      key: 'isAvailable',
      header: 'Availability',
      sortable: true,
      render: (d) => (
        <Badge variant={d.isAvailable ? 'success' : 'neutral'}>
          {d.isAvailable ? 'Available' : 'Busy / Offline'}
        </Badge>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      sortable: true,
      render: (d) => (
        <div className="flex items-center gap-1 text-amber-400 font-semibold text-xs">
          <Star className="w-3.5 h-3.5 fill-amber-400" />
          <span>{d.rating ? Number(d.rating).toFixed(1) : '5.0'}</span>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Account Status',
      sortable: true,
      render: (d) => (
        <Badge variant={d.status === 'blocked' ? 'danger' : 'info'}>
          {d.status || 'Active'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Truck className="w-6 h-6 text-cyan-400" />
            <h2 className="text-2xl font-black text-white">Fleet Drivers Registry</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Track driver verifications, licenses, active assignments, and vehicle registrations.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
            <span>Online: <strong className="text-emerald-400">{drivers.filter((d) => d.isAvailable).length}</strong> / {drivers.length}</span>
          </div>
        </div>
      </div>

      <DataTable
        data={drivers}
        columns={columns}
        searchPlaceholder="Search drivers by name, phone, CNIC, vehicle number..."
        searchFields={['name', 'fullName', 'phone', 'cnic', 'vehicleNumber', 'vehicleType', 'id']}
        loading={loading}
        emptyMessage="No drivers found in Firestore 'Driver' collection"
        actions={(d) => (
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => {
                setSelectedDriver(d);
                setIsDetailOpen(true);
              }}
              title="Inspect Driver"
              className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
            >
              <Eye className="w-4 h-4 text-cyan-400" />
            </button>
            <button
              onClick={() => handleToggleBlock(d)}
              disabled={actionLoading}
              title={d.status === 'blocked' ? 'Unblock Driver' : 'Block Driver'}
              className={`p-1.5 rounded-lg transition-colors ${
                d.status === 'blocked'
                  ? 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30'
                  : 'bg-amber-500/20 text-amber-400 hover:bg-amber-500/30'
              }`}
            >
              {d.status === 'blocked' ? <CheckCircle2 className="w-4 h-4" /> : <Ban className="w-4 h-4" />}
            </button>
            <button
              onClick={() => {
                setSelectedDriver(d);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Driver"
              className="p-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 text-rose-400 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        )}
      />

      {/* Driver Inspection Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Driver & Vehicle Verification Dossier"
        maxWidth="lg"
      >
        {selectedDriver && (
          <div className="space-y-6">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-800">
              <div className="w-16 h-16 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center font-bold text-2xl text-cyan-400">
                <Truck className="w-8 h-8" />
              </div>
              <div>
                <h4 className="text-lg font-bold text-white">{selectedDriver.name || selectedDriver.fullName || 'Fleet Driver'}</h4>
                <p className="text-xs font-mono text-cyan-400">UID: {selectedDriver.id}</p>
                <div className="mt-1 flex items-center gap-2">
                  <Badge variant={selectedDriver.isAvailable ? 'success' : 'neutral'}>
                    {selectedDriver.isAvailable ? 'Ready for Dispatch' : 'Offline / On Trip'}
                  </Badge>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone Number
                </span>
                <p className="text-slate-200 font-medium">{selectedDriver.phone || '—'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <CreditCard className="w-3.5 h-3.5 text-slate-400" /> CNIC / ID Number
                </span>
                <p className="text-slate-200 font-medium">{selectedDriver.cnic || 'Not registered'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Car className="w-3.5 h-3.5 text-slate-400" /> Vehicle Type & Reg
                </span>
                <p className="text-slate-200 font-medium">
                  {selectedDriver.vehicleType || 'Truck'} ({selectedDriver.vehicleNumber || 'No Plate'})
                </p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <FileBadge className="w-3.5 h-3.5 text-slate-400" /> Driving License
                </span>
                <p className="text-slate-200 font-medium">{selectedDriver.licenseNumber || 'Verified'}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Telematics GPS Location
                </span>
                <p className="text-slate-200 font-medium">
                  {selectedDriver.currentLocation
                    ? `Lat: ${selectedDriver.currentLocation.latitude}, Lng: ${selectedDriver.currentLocation.longitude}`
                    : selectedDriver.latitude && selectedDriver.longitude
                    ? `Lat: ${selectedDriver.latitude}, Lng: ${selectedDriver.longitude}`
                    : 'GPS coordinates unavailable'}
                </p>
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
        title="Remove Driver Record"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-sm text-slate-300">
            Are you sure you want to permanently delete driver{' '}
            <strong className="text-white">{selectedDriver?.name || selectedDriver?.phone}</strong> from the database?
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
