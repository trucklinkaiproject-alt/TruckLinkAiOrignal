import React, { useEffect, useMemo, useState } from 'react';
import { Column, DataTable } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import { subscribeDrivers, subscribeBrokers } from '../services/firestoreService';
import { DriverProfile, BrokerProfile, VehicleRecord } from '../types/models';
import {
  CarFront,
  Truck,
  Eye,
  Star,
  Phone,
  Mail,
  Building,
  User,
  CheckCircle2,
  Clock,
  MapPin,
  Filter,
  ShieldCheck,
  Package
} from 'lucide-react';

export const Vehicles: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters and state
  const [selectedVehicleType, setSelectedVehicleType] = useState<string>('all');
  const [selectedAvailability, setSelectedAvailability] = useState<string>('all');
  const [selectedRecord, setSelectedRecord] = useState<VehicleRecord | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);

  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubB = subscribeBrokers((brokerList) => {
      setBrokers(brokerList);
    });

    const unsubD = subscribeDrivers((driverList) => {
      setDrivers(driverList);
      setLoading(false);
    });

    unsubs = [unsubB, unsubD];

    return () => {
      unsubs.forEach((fn) => fn());
    };
  }, []);

  // Map of broker IDs to broker names
  const brokerMap = useMemo(() => {
    const map = new Map<string, string>();
    brokers.forEach((b) => {
      map.set(b.id, b.companyName || b.name || 'Broker Partner');
    });
    return map;
  }, [brokers]);

  // Derive real vehicle records strictly from the real Driver documents in Firestore
  const vehicleRecords: VehicleRecord[] = useMemo(() => {
    return drivers
      .filter((d) => {
        // Must have at least a vehicle number OR vehicle type present
        const hasNum = d.vehicleNumber && d.vehicleNumber.trim().length > 0;
        const hasType = d.vehicleType && d.vehicleType.trim().length > 0;
        return hasNum || hasType;
      })
      .map((d) => {
        const resolvedBrokerName =
          d.brokerName ||
          (d.brokerId ? brokerMap.get(d.brokerId) : '') ||
          (d.created_by_broker_id ? brokerMap.get(d.created_by_broker_id) : '') ||
          'Independent';

        return {
          id: d.id || d.uid || '',
          driverId: d.uid || d.id || '',
          driverName: d.name || d.fullName || 'Fleet Driver',
          driverPhone: d.phone || d.phoneNumber || '—',
          driverEmail: d.email || '',
          vehicleType: d.vehicleType || 'Commercial Truck',
          vehicleNumber: d.vehicleNumber || 'Unregistered',
          brokerId: d.brokerId || d.created_by_broker_id || '',
          brokerName: resolvedBrokerName,
          status: d.status || 'active',
          availabilityStatus: d.availabilityStatus || (d.isAvailable ? 'online' : 'offline'),
          isAvailable: !!d.isAvailable,
          rating: d.rating ?? 5.0,
          completedTrips: d.completedTrips || 0,
          totalTrips: d.totalTrips || 0,
        };
      });
  }, [drivers, brokerMap]);

  // Unique vehicle types dynamically derived from actual records
  const availableVehicleTypes = useMemo(() => {
    const types = new Set<string>();
    vehicleRecords.forEach((v) => {
      if (v.vehicleType) types.add(v.vehicleType);
    });
    return Array.from(types);
  }, [vehicleRecords]);

  // Apply filters
  const filteredVehicles = useMemo(() => {
    return vehicleRecords.filter((v) => {
      if (selectedVehicleType !== 'all' && v.vehicleType.toLowerCase() !== selectedVehicleType.toLowerCase()) {
        return false;
      }
      if (selectedAvailability === 'available' && !v.isAvailable) {
        return false;
      }
      if (selectedAvailability === 'unavailable' && v.isAvailable) {
        return false;
      }
      return true;
    });
  }, [vehicleRecords, selectedVehicleType, selectedAvailability]);

  // Summary Metrics
  const onlineCount = vehicleRecords.filter((v) => v.isAvailable).length;
  const offlineCount = vehicleRecords.length - onlineCount;

  const columns: Column<VehicleRecord>[] = [
    {
      key: 'vehicleNumber',
      header: 'Vehicle & Reg Plate',
      sortable: true,
      render: (v) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-slate-700 shrink-0">
            <Truck className="w-4 h-4 text-slate-600" />
          </div>
          <div>
            <span className="font-mono font-bold text-slate-900 text-xs tracking-wider bg-slate-100 px-1.5 py-0.5 rounded border border-slate-200">
              {v.vehicleNumber}
            </span>
            <div className="mt-0.5 flex items-center gap-1.5 text-xs text-slate-500">
              <span className="font-medium text-sky-800">{v.vehicleType}</span>
            </div>
          </div>
        </div>
      ),
    },
    {
      key: 'driverName',
      header: 'Assigned Driver',
      sortable: true,
      render: (v) => (
        <div>
          <div className="flex items-center gap-1.5">
            <User className="w-3 h-3 text-slate-400" />
            <p className="font-semibold text-slate-900 text-xs">{v.driverName}</p>
          </div>
          <p className="text-[11px] text-slate-500 font-mono mt-0.5">UID: {v.driverId.substring(0, 10)}...</p>
        </div>
      ),
    },
    {
      key: 'driverPhone',
      header: 'Driver Contact',
      render: (v) => (
        <div className="text-xs">
          <p className="text-slate-900 font-mono">{v.driverPhone}</p>
          {v.driverEmail && <p className="text-[11px] text-slate-500">{v.driverEmail}</p>}
        </div>
      ),
    },
    {
      key: 'brokerName',
      header: 'Affiliated Transporter',
      sortable: true,
      render: (v) => (
        <div className="text-xs">
          <div className="flex items-center gap-1 text-slate-800 font-medium">
            <Building className="w-3 h-3 text-slate-400" />
            <span>{v.brokerName}</span>
          </div>
          {v.brokerId && (
            <p className="text-[10px] text-slate-500 font-mono mt-0.5">
              ID: {v.brokerId.substring(0, 8)}...
            </p>
          )}
        </div>
      ),
    },
    {
      key: 'rating',
      header: 'Rating & Trips',
      sortable: true,
      render: (v) => (
        <div className="text-xs">
          <div className="flex items-center gap-1 text-amber-600 font-bold">
            <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
            <span>{v.rating ? v.rating.toFixed(1) : '5.0'}</span>
          </div>
          <p className="text-[11px] text-slate-500 mt-0.5">
            {v.completedTrips} trips completed
          </p>
        </div>
      ),
    },
    {
      key: 'isAvailable',
      header: 'Availability',
      sortable: true,
      render: (v) => (
        <Badge variant={v.isAvailable ? 'success' : 'neutral'} size="sm">
          {v.isAvailable ? 'Online / Available' : 'Offline / Standby'}
        </Badge>
      ),
    },
  ];

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <CarFront className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Trucks & Fleet Capacity</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Fleet inventory and capacity derived directly from registered driver vehicle profiles.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-600 bg-white px-3 py-1.5 rounded-md border border-slate-200 shadow-2xs">
          <span className="w-2 h-2 rounded-full bg-emerald-500" />
          <span>Active Fleet Units: <strong className="text-slate-900">{vehicleRecords.length}</strong></span>
        </div>
      </div>

      {/* Metrics Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex items-center justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold">Total Registered Fleet</p>
            <h3 className="text-xl font-bold text-slate-900 mt-0.5">{vehicleRecords.length} Units</h3>
            <p className="text-[11px] text-slate-500 mt-0.5">From Driver collection</p>
          </div>
          <div className="p-2.5 bg-slate-100 rounded-md text-slate-700 border border-slate-200">
            <Truck className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex items-center justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold">Online & Available</p>
            <h3 className="text-xl font-bold text-emerald-700 mt-0.5">{onlineCount} Active</h3>
            <p className="text-[11px] text-emerald-700/80 mt-0.5">Ready for dispatch</p>
          </div>
          <div className="p-2.5 bg-emerald-50 rounded-md text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex items-center justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold">Offline / On Route</p>
            <h3 className="text-xl font-bold text-slate-800 mt-0.5">{offlineCount} Standby</h3>
            <p className="text-[11px] text-slate-500 mt-0.5">Inactive or on trip</p>
          </div>
          <div className="p-2.5 bg-slate-100 rounded-md text-slate-600 border border-slate-200">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex items-center justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold">Broker Networked</p>
            <h3 className="text-xl font-bold text-slate-900 mt-0.5">
              {vehicleRecords.filter((v) => v.brokerId).length} Units
            </h3>
            <p className="text-[11px] text-slate-500 mt-0.5">Linked to Transporters</p>
          </div>
          <div className="p-2.5 bg-slate-100 rounded-md text-slate-700 border border-slate-200">
            <Building className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filter Component */}
      <div className="flex flex-wrap items-center gap-3 p-3 rounded-lg bg-white border border-slate-200 shadow-2xs">
        <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-600">
          <Filter className="w-3.5 h-3.5 text-slate-500" />
          <span>Filters:</span>
        </div>

        <div className="flex items-center gap-2">
          <label className="text-xs text-slate-600">Vehicle Type:</label>
          <select
            value={selectedVehicleType}
            onChange={(e) => setSelectedVehicleType(e.target.value)}
            className="px-2.5 py-1 bg-white border border-slate-300 rounded-md text-xs text-slate-900 focus:outline-none focus:border-sky-600"
          >
            <option value="all">All Vehicle Types ({vehicleRecords.length})</option>
            {availableVehicleTypes.map((t) => (
              <option key={t} value={t}>
                {t} ({vehicleRecords.filter((v) => v.vehicleType === t).length})
              </option>
            ))}
          </select>
        </div>

        <div className="flex items-center gap-2">
          <label className="text-xs text-slate-600">Status / Readiness:</label>
          <select
            value={selectedAvailability}
            onChange={(e) => setSelectedAvailability(e.target.value)}
            className="px-2.5 py-1 bg-white border border-slate-300 rounded-md text-xs text-slate-900 focus:outline-none focus:border-sky-600"
          >
            <option value="all">All Statuses</option>
            <option value="available">Online & Available Only</option>
            <option value="unavailable">Offline / Standby Only</option>
          </select>
        </div>

        {(selectedVehicleType !== 'all' || selectedAvailability !== 'all') && (
          <button
            onClick={() => {
              setSelectedVehicleType('all');
              setSelectedAvailability('all');
            }}
            className="text-xs text-sky-700 hover:text-sky-800 underline font-medium ml-auto"
          >
            Reset Filters
          </button>
        )}
      </div>

      {/* Main Vehicles Table */}
      <DataTable
        data={filteredVehicles}
        columns={columns}
        searchPlaceholder="Search by plate number, vehicle class, driver, broker..."
        searchFields={['vehicleNumber', 'vehicleType', 'driverName', 'driverPhone', 'driverEmail', 'brokerName', 'driverId']}
        loading={loading}
        emptyMessage="No driver vehicles found matching criteria in Firestore 'Driver' collection"
        actions={(v) => (
          <button
            onClick={() => {
              setSelectedRecord(v);
              setIsDetailOpen(true);
            }}
            title="Inspect Vehicle & Driver Dossier"
            className="p-1.5 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 transition-colors shadow-2xs"
          >
            <Eye className="w-3.5 h-3.5 text-sky-700" />
          </button>
        )}
      />

      {/* Vehicle Inspection Modal */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        title="Vehicle & Driver Fleet Dossier"
        maxWidth="lg"
      >
        {selectedRecord && (
          <div className="space-y-5">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-200">
              <div className="w-14 h-14 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xl text-slate-700 shrink-0">
                <Truck className="w-6 h-6 text-slate-600" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h4 className="text-base font-bold text-slate-900 font-mono tracking-wider">
                    {selectedRecord.vehicleNumber}
                  </h4>
                  <Badge variant={selectedRecord.isAvailable ? 'success' : 'neutral'} size="sm">
                    {selectedRecord.isAvailable ? 'Online' : 'Offline'}
                  </Badge>
                </div>
                <p className="text-xs text-slate-600 font-semibold mt-0.5">
                  Vehicle Type: {selectedRecord.vehicleType}
                </p>
                <p className="text-[11px] text-slate-500 font-mono mt-0.5">
                  Driver UID: {selectedRecord.driverId}
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <User className="w-3.5 h-3.5 text-slate-400" /> Registered Driver
                </span>
                <p className="text-slate-900 font-bold text-xs">{selectedRecord.driverName}</p>
                <p className="text-slate-600 text-[11px] mt-0.5 font-mono">{selectedRecord.driverPhone}</p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Building className="w-3.5 h-3.5 text-slate-400" /> Associated Transporter / Broker
                </span>
                <p className="text-slate-900 font-bold text-xs">{selectedRecord.brokerName}</p>
                <p className="text-slate-500 text-[10px] font-mono mt-0.5">
                  {selectedRecord.brokerId ? `ID: ${selectedRecord.brokerId}` : 'Direct Carrier'}
                </p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <Star className="w-3.5 h-3.5 text-amber-500" /> Performance Rating
                </span>
                <p className="text-amber-600 font-bold text-xs">
                  {selectedRecord.rating ? selectedRecord.rating.toFixed(1) : '5.0'} ★
                </p>
                <p className="text-slate-500 text-[11px] mt-0.5">
                  Completed {selectedRecord.completedTrips} Trips ({selectedRecord.totalTrips} Total)
                </p>
              </div>

              <div className="p-3 rounded-md bg-slate-50 border border-slate-200">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1 text-[10px]">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" /> Verification Status
                </span>
                <p className="text-emerald-700 font-bold text-xs">
                  {selectedRecord.status.toUpperCase()}
                </p>
                <p className="text-slate-500 text-[11px] mt-0.5">
                  Availability: {selectedRecord.availabilityStatus}
                </p>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-md text-xs font-semibold shadow-2xs transition-colors"
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
