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
          <div className="w-8 h-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-slate-700 overflow-hidden shrink-0">
            <Truck className="w-4 h-4 text-slate-600" />
          </div>
          <div>
            <p className="font-semibold text-slate-900 text-xs">{d.name || d.fullName || 'Fleet Driver'}</p>
            <p className="text-[11px] text-slate-500 font-mono">{d.id.substring(0, 10)}...</p>
          </div>
        </div>
      ),
    },
    {
      key: 'phone',
      header: 'Phone / CNIC',
      render: (d) => (
        <div className="text-xs">
          <p className="text-slate-900 font-mono">{d.phone || '—'}</p>
          <p className="text-slate-500 font-mono text-[11px]">{d.cnic ? `CNIC: ${d.cnic}` : 'No CNIC'}</p>
        </div>
      ),
    },
    {
      key: 'vehicleType',
      header: 'Vehicle & Reg No.',
      sortable: true,
      render: (d) => (
        <div>
          <span className="font-medium text-slate-900 text-xs">{d.vehicleType || d.vehicleModel || 'Truck'}</span>
          <p className="text-[11px] font-mono text-sky-800 font-medium">{d.vehicleNumber || '—'}</p>
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
        <div className="flex items-center gap-1 text-amber-600 font-semibold text-xs">
          <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
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
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <Truck className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Fleet Drivers Registry</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Track driver verifications, licenses, active availability status, and vehicle assignments.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-600 bg-white px-3 py-1.5 rounded-md border border-slate-200 shadow-2xs">
            <span>Online: <strong className="text-emerald-700">{drivers.filter((d) => d.isAvailable).length}</strong> / {drivers.length}</span>
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
          <div className="flex items-center gap-1">
            <button
              onClick={() => {
                setSelectedDriver(d);
                setIsDetailOpen(true);
              }}
              title="Inspect Driver"
              className="p-1.5 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 transition-colors shadow-2xs"
            >
              <Eye className="w-3.5 h-3.5 text-sky-700" />
            </button>
            <button
              onClick={() => handleToggleBlock(d)}
              disabled={actionLoading}
              title={d.status === 'blocked' ? 'Unblock Driver' : 'Block Driver'}
              className={`p-1.5 rounded-md border transition-colors shadow-2xs ${
                d.status === 'blocked'
                  ? 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                  : 'border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100'
              }`}
            >
              {d.status === 'blocked' ? <CheckCircle2 className="w-3.5 h-3.5" /> : <Ban className="w-3.5 h-3.5" />}
            </button>
            <button
              onClick={() => {
                setSelectedDriver(d);
                setIsDeleteModalOpen(true);
              }}
              title="Delete Driver"
              className="p-1.5 rounded-md border border-rose-200 bg-rose-50 hover:bg-rose-100 text-rose-700 transition-colors shadow-2xs"
            >
              <Trash2 className="w-3.5 h-3.5" />
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
          <div className="space-y-5">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-200">
              <div className="w-14 h-14 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xl text-slate-700 shrink-0">
                <Truck className="w-6 h-6 text-slate-600" />
              </div>
              <div>
                <h4 className="text-base font-bold text-slate-900">{selectedDriver.name || selectedDriver.fullName || 'Fleet Driver'}</h4>
                <p className="text-xs font-mono text-slate-500">UID: {selectedDriver.id}</p>
                <div className="mt-1 flex items-center gap-2">
                  <Badge variant={selectedDriver.isAvailable ? 'success' : 'neutral'}>
                    {selectedDriver.isAvailable ? 'Ready for Dispatch' : 'Offline / On Trip'}
                  </Badge>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Phone className="w-3.5 h-3.5 text-slate-400" /> Phone Number
                </span>
                <p className="text-slate-900 font-medium font-mono">{selectedDriver.phone || '—'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <CreditCard className="w-3.5 h-3.5 text-slate-400" /> CNIC / National ID
                </span>
                <p className="text-slate-900 font-medium font-mono">{selectedDriver.cnic || 'Not registered'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Car className="w-3.5 h-3.5 text-slate-400" /> Vehicle Type & Reg
                </span>
                <p className="text-slate-900 font-medium">
                  {selectedDriver.vehicleType || 'Truck'} ({selectedDriver.vehicleNumber || 'No Plate'})
                </p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <FileBadge className="w-3.5 h-3.5 text-slate-400" /> Driving License
                </span>
                <p className="text-slate-900 font-medium">{selectedDriver.licenseNumber || 'Verified'}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200 sm:col-span-2">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Telematics GPS Location
                </span>
                <p className="text-slate-900 font-medium font-mono text-[11px]">
                  {selectedDriver.currentLocation
                    ? `Lat: ${selectedDriver.currentLocation.latitude}, Lng: ${selectedDriver.currentLocation.longitude}`
                    : selectedDriver.latitude && selectedDriver.longitude
                    ? `Lat: ${selectedDriver.latitude}, Lng: ${selectedDriver.longitude}`
                    : 'GPS coordinates unavailable'}
                </p>
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
        title="Remove Driver Record"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-600">
            Are you sure you want to permanently delete driver{' '}
            <strong className="font-semibold text-slate-900">{selectedDriver?.name || selectedDriver?.phone}</strong> from the database?
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
