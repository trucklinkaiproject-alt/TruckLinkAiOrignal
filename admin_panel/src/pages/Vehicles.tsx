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
          <div className="w-10 h-10 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center font-bold text-sky-400 shrink-0">
            <Truck className="w-5 h-5" />
          </div>
          <div>
            <span className="font-mono font-bold text-white text-sm tracking-wider bg-slate-950 px-2 py-0.5 rounded border border-slate-800">
              {v.vehicleNumber}
            </span>
            <div className="mt-1 flex items-center gap-1.5 text-xs text-slate-400">
              <span className="font-medium text-sky-300">{v.vehicleType}</span>
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
            <User className="w-3.5 h-3.5 text-slate-400" />
            <p className="font-semibold text-white text-xs">{v.driverName}</p>
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
          <p className="text-slate-300 font-mono">{v.driverPhone}</p>
          {v.driverEmail && <p className="text-[11px] text-slate-500">{v.driverEmail}</p>}
        </div>
      ),
    },
    {
      key: 'brokerName',
      header: 'Affiliated Broker',
      sortable: true,
      render: (v) => (
        <div className="text-xs">
          <div className="flex items-center gap-1 text-purple-300 font-medium">
            <Building className="w-3.5 h-3.5 text-purple-400" />
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
          <div className="flex items-center gap-1 text-amber-400 font-bold">
            <Star className="w-3 h-3 fill-amber-400" />
            <span>{v.rating ? v.rating.toFixed(1) : '5.0'}</span>
          </div>
          <p className="text-[11px] text-slate-400 mt-0.5">
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
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <CarFront className="w-6 h-6 text-sky-400" />
            <h2 className="text-2xl font-black text-white">Trucks & Fleet Capacity</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Real-time fleet inventory derived dynamically from registered driver vehicles in Firebase.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>Active Fleet Units: <strong className="text-white">{vehicleRecords.length}</strong></span>
        </div>
      </div>

      {/* Metrics Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl bg-slate-900/70 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Total Registered Fleet</p>
            <h3 className="text-2xl font-bold text-white mt-1">{vehicleRecords.length} Units</h3>
            <p className="text-[11px] text-sky-400 mt-1">From Driver collection</p>
          </div>
          <div className="p-3 bg-sky-500/10 rounded-xl text-sky-400 border border-sky-500/20">
            <Truck className="w-6 h-6" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-slate-900/70 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Online & Available</p>
            <h3 className="text-2xl font-bold text-emerald-400 mt-1">{onlineCount} Active</h3>
            <p className="text-[11px] text-emerald-400/80 mt-1">Ready for dispatch</p>
          </div>
          <div className="p-3 bg-emerald-500/10 rounded-xl text-emerald-400 border border-emerald-500/20">
            <CheckCircle2 className="w-6 h-6" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-slate-900/70 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Offline / On Route</p>
            <h3 className="text-2xl font-bold text-amber-400 mt-1">{offlineCount} Standby</h3>
            <p className="text-[11px] text-slate-400 mt-1">Inactive or on trip</p>
          </div>
          <div className="p-3 bg-amber-500/10 rounded-xl text-amber-400 border border-amber-500/20">
            <Clock className="w-6 h-6" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-slate-900/70 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Broker Networked</p>
            <h3 className="text-2xl font-bold text-purple-400 mt-1">
              {vehicleRecords.filter((v) => v.brokerId).length} Units
            </h3>
            <p className="text-[11px] text-purple-300 mt-1">Linked to Transporters</p>
          </div>
          <div className="p-3 bg-purple-500/10 rounded-xl text-purple-400 border border-purple-500/20">
            <Building className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Filter Component */}
      <div className="flex flex-wrap items-center gap-3 p-4 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl">
        <div className="flex items-center gap-2 text-xs font-semibold text-slate-400">
          <Filter className="w-4 h-4 text-sky-400" />
          <span>Filters:</span>
        </div>

        <div className="flex items-center gap-2">
          <label className="text-xs text-slate-400">Vehicle Type:</label>
          <select
            value={selectedVehicleType}
            onChange={(e) => setSelectedVehicleType(e.target.value)}
            className="px-3 py-1.5 bg-slate-950 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-brand-500"
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
          <label className="text-xs text-slate-400">Status / Readiness:</label>
          <select
            value={selectedAvailability}
            onChange={(e) => setSelectedAvailability(e.target.value)}
            className="px-3 py-1.5 bg-slate-950 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-brand-500"
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
            className="text-xs text-sky-400 hover:text-sky-300 underline font-medium ml-auto"
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
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
          >
            <Eye className="w-4 h-4 text-sky-400" />
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
          <div className="space-y-6">
            <div className="flex items-center gap-4 pb-4 border-b border-slate-800">
              <div className="w-16 h-16 rounded-2xl bg-sky-500/10 border border-sky-500/30 flex items-center justify-center font-bold text-2xl text-sky-400">
                <Truck className="w-8 h-8" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h4 className="text-lg font-bold text-white font-mono tracking-wider">
                    {selectedRecord.vehicleNumber}
                  </h4>
                  <Badge variant={selectedRecord.isAvailable ? 'success' : 'neutral'} size="sm">
                    {selectedRecord.isAvailable ? 'Online' : 'Offline'}
                  </Badge>
                </div>
                <p className="text-xs text-sky-400 font-semibold mt-0.5">
                  Vehicle Type: {selectedRecord.vehicleType}
                </p>
                <p className="text-[11px] text-slate-500 font-mono mt-0.5">
                  Driver UID: {selectedRecord.driverId}
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <User className="w-3.5 h-3.5 text-slate-400" /> Registered Driver
                </span>
                <p className="text-slate-200 font-bold text-sm">{selectedRecord.driverName}</p>
                <p className="text-slate-400 text-[11px] mt-0.5">{selectedRecord.driverPhone}</p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Building className="w-3.5 h-3.5 text-purple-400" /> Associated Transporter / Broker
                </span>
                <p className="text-purple-300 font-bold text-sm">{selectedRecord.brokerName}</p>
                <p className="text-slate-500 text-[11px] font-mono mt-0.5">
                  {selectedRecord.brokerId ? `ID: ${selectedRecord.brokerId}` : 'Direct Carrier'}
                </p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <Star className="w-3.5 h-3.5 text-amber-400" /> Performance Rating
                </span>
                <p className="text-amber-400 font-bold text-sm">
                  {selectedRecord.rating ? selectedRecord.rating.toFixed(1) : '5.0'} ★
                </p>
                <p className="text-slate-400 text-[11px] mt-0.5">
                  Completed {selectedRecord.completedTrips} Trips ({selectedRecord.totalTrips} Total)
                </p>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800">
                <span className="text-slate-500 font-semibold uppercase flex items-center gap-1.5 mb-1">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" /> Verification Status
                </span>
                <p className="text-emerald-400 font-bold text-sm">
                  {selectedRecord.status.toUpperCase()}
                </p>
                <p className="text-slate-400 text-[11px] mt-0.5">
                  Availability: {selectedRecord.availabilityStatus}
                </p>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-800 flex justify-end gap-3">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold transition-colors"
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
