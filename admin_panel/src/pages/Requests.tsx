import React, { useEffect, useState, useMemo } from 'react';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import {
  subscribeAllRequests,
  subscribeUsers,
  subscribeBrokers,
  subscribeDrivers,
  subscribeOrderDriverOffers,
} from '../services/firestoreService';
import {
  UserRequest,
  UserProfile,
  BrokerProfile,
  DriverProfile,
  DriverOfferRecord,
} from '../types/models';
import {
  FileText,
  Eye,
  Package,
  DollarSign,
  Truck,
  Search,
  Filter,
  X,
  User,
  Briefcase,
  ArrowUpDown,
  ChevronLeft,
  ChevronRight,
  Clock,
  CheckCircle2,
  XCircle,
  Layers,
  ExternalLink,
  ShieldAlert,
  AlertTriangle,
  History,
  Radio,
  MapPin,
  FileCheck,
} from 'lucide-react';

export const Requests: React.FC = () => {
  const [requests, setRequests] = useState<UserRequest[]>([]);
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [loading, setLoading] = useState(true);

  // Filter States
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUserFilter, setSelectedUserFilter] = useState<string>('all');
  const [selectedBrokerFilter, setSelectedBrokerFilter] = useState<string>('all');
  const [selectedDriverFilter, setSelectedDriverFilter] = useState<string>('all');
  const [selectedStatusFilter, setSelectedStatusFilter] = useState<string>('all');
  const [selectedCargoFilter, setSelectedCargoFilter] = useState<string>('all');

  // Sorting & Pagination
  const [sortField, setSortField] = useState<string>('numericOrderNo');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Detail Modal & Subcollection Streaming
  const [selectedReq, setSelectedReq] = useState<UserRequest | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [driverOffers, setDriverOffers] = useState<DriverOfferRecord[]>([]);
  const [loadingOffers, setLoadingOffers] = useState(false);

  useEffect(() => {
    const unsubRequests = subscribeAllRequests((data) => {
      setRequests(data);
      setLoading(false);
    });

    const unsubUsers = subscribeUsers((data) => setUsers(data));
    const unsubBrokers = subscribeBrokers((data) => setBrokers(data));
    const unsubDrivers = subscribeDrivers((data) => setDrivers(data));

    return () => {
      unsubRequests();
      unsubUsers();
      unsubBrokers();
      unsubDrivers();
    };
  }, []);

  // Derive the freshest version of selectedReq directly from real-time requests state
  const activeReq = useMemo(() => {
    if (!selectedReq) return null;
    return requests.find((r) => r.id === selectedReq.id) || selectedReq;
  }, [requests, selectedReq]);

  const activeOrderDocId = activeReq?.orderId || activeReq?.id;

  // Real-time listener for DriverOffers subcollection when an order modal is opened
  useEffect(() => {
    if (!isDetailOpen || !activeOrderDocId) {
      return;
    }

    const unsubOffers = subscribeOrderDriverOffers(activeOrderDocId, (offers) => {
      setDriverOffers(offers);
      setLoadingOffers(false);
    });

    return () => {
      unsubOffers();
    };
  }, [isDetailOpen, activeOrderDocId]);

  // Extract unique cargo types from loaded requests
  const uniqueCargoTypes = useMemo(() => {
    const set = new Set<string>();
    requests.forEach((r) => {
      const type = r.itemType || r.cargoType;
      if (type && type.trim()) set.add(type.trim());
    });
    return Array.from(set).sort();
  }, [requests]);

  // Combined Multi-Filter & Comprehensive Search Logic
  const filteredRequests = useMemo(() => {
    return requests.filter((r) => {
      // 1. User Filter (Shipper)
      if (selectedUserFilter !== 'all') {
        const uId = r.userUid || r.userId;
        if (uId !== selectedUserFilter) return false;
      }

      // 2. Broker Filter
      if (selectedBrokerFilter !== 'all') {
        const bId = r.brokerId;
        if (bId !== selectedBrokerFilter) return false;
      }

      // 3. Driver Filter
      if (selectedDriverFilter !== 'all') {
        const dId = r.assigned_driver_id || r.driverId;
        if (dId !== selectedDriverFilter) return false;
      }

      // 4. Status Filter
      if (selectedStatusFilter !== 'all') {
        const currentStatus = (r.status || 'pending').toLowerCase();
        if (selectedStatusFilter === 'pending' && currentStatus !== 'pending') return false;
        if (selectedStatusFilter === 'fare_offered' && currentStatus !== 'fare_offered') return false;
        if (selectedStatusFilter === 'accepted' && currentStatus !== 'accepted') return false;
        if (selectedStatusFilter === 'rejected' && !currentStatus.includes('reject')) return false;
        if (
          selectedStatusFilter === 'driver_assigned' &&
          currentStatus !== 'driver_offer_sent' &&
          currentStatus !== 'accepted_by_driver'
        )
          return false;
        if (
          selectedStatusFilter === 'in_transit' &&
          currentStatus !== 'in_transit' &&
          currentStatus !== 'heading_to_drop'
        )
          return false;
        if (
          selectedStatusFilter === 'completed' &&
          currentStatus !== 'completed' &&
          currentStatus !== 'delivered'
        )
          return false;
        if (selectedStatusFilter === 'cancelled' && currentStatus !== 'cancelled') return false;
      }

      // 5. Cargo Filter
      if (selectedCargoFilter !== 'all') {
        const cargo = (r.itemType || r.cargoType || '').toLowerCase();
        if (cargo !== selectedCargoFilter.toLowerCase()) return false;
      }

      // 6. Comprehensive Search Bar (Order No, Doc ID, User Name & UID, Broker Name & UID, Driver Name & UID, Cargo, Addresses)
      if (searchTerm.trim()) {
        const term = searchTerm.toLowerCase();
        const matchesOrderNo = (r.orderNo || '').toLowerCase().includes(term);
        const matchesId =
          (r.id || '').toLowerCase().includes(term) ||
          (r.orderId || '').toLowerCase().includes(term);
        const matchesUser =
          (r.userName || '').toLowerCase().includes(term) ||
          (r.userUid || '').toLowerCase().includes(term) ||
          (r.userId || '').toLowerCase().includes(term);
        const matchesBroker =
          (r.brokerName || '').toLowerCase().includes(term) ||
          (r.brokerId || '').toLowerCase().includes(term);
        const matchesDriver =
          (r.driverName || '').toLowerCase().includes(term) ||
          (r.assigned_driver_id || '').toLowerCase().includes(term) ||
          (r.driverId || '').toLowerCase().includes(term);
        const matchesCargo = (r.itemType || r.cargoType || '').toLowerCase().includes(term);
        const matchesPickup = (r.pickupLocation || '').toLowerCase().includes(term);
        const matchesDrop = (r.dropoffLocation || '').toLowerCase().includes(term);

        if (
          !matchesOrderNo &&
          !matchesId &&
          !matchesUser &&
          !matchesBroker &&
          !matchesDriver &&
          !matchesCargo &&
          !matchesPickup &&
          !matchesDrop
        ) {
          return false;
        }
      }

      return true;
    });
  }, [
    requests,
    selectedUserFilter,
    selectedBrokerFilter,
    selectedDriverFilter,
    selectedStatusFilter,
    selectedCargoFilter,
    searchTerm,
  ]);

  // Sorting Logic (Natural numeric orderNo sort by default: #1, #2, #3...)
  const sortedRequests = useMemo(() => {
    const list = [...filteredRequests];
    list.sort((a, b) => {
      let aVal: any = a[sortField];
      let bVal: any = b[sortField];

      if (sortField === 'numericOrderNo') {
        aVal = a.numericOrderNo || 0;
        bVal = b.numericOrderNo || 0;
      } else if (sortField === 'finalFare') {
        aVal = a.finalFare || a.customer_fare || a.accepted_fare || 0;
        bVal = b.finalFare || b.customer_fare || b.accepted_fare || 0;
      } else if (sortField === 'date') {
        aVal = a.createdAt || a.date || '';
        bVal = b.createdAt || b.date || '';
      }

      if (aVal === bVal) return 0;
      if (aVal === undefined || aVal === null) return 1;
      if (bVal === undefined || bVal === null) return -1;

      const comp = aVal > bVal ? 1 : -compVal(aVal, bVal);
      return sortDirection === 'asc' ? comp : -comp;
    });
    return list;
  }, [filteredRequests, sortField, sortDirection]);

  function compVal(a: any, b: any) {
    return a > b ? 1 : -1;
  }

  // Pagination
  const totalPages = Math.ceil(sortedRequests.length / itemsPerPage) || 1;
  const paginatedRequests = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return sortedRequests.slice(start, start + itemsPerPage);
  }, [sortedRequests, currentPage, itemsPerPage]);

  const handleSort = (field: string) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const handleClearFilters = () => {
    setSelectedUserFilter('all');
    setSelectedBrokerFilter('all');
    setSelectedDriverFilter('all');
    setSelectedStatusFilter('all');
    setSelectedCargoFilter('all');
    setSearchTerm('');
    setCurrentPage(1);
  };

  const isAnyFilterActive =
    selectedUserFilter !== 'all' ||
    selectedBrokerFilter !== 'all' ||
    selectedDriverFilter !== 'all' ||
    selectedStatusFilter !== 'all' ||
    selectedCargoFilter !== 'all' ||
    searchTerm.trim() !== '';

  // Render Status Badge
  const renderStatusBadge = (status?: string) => {
    const s = (status || 'pending').toLowerCase();
    if (s === 'completed' || s === 'delivered') {
      return <Badge variant="success">Completed</Badge>;
    }
    if (s === 'in_transit' || s === 'heading_to_drop') {
      return <Badge variant="info">In Transit</Badge>;
    }
    if (s === 'accepted_by_driver' || s === 'driver_offer_sent') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
          <Truck className="w-3 h-3" />
          Driver Assigned
        </span>
      );
    }
    if (s === 'accepted') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <CheckCircle2 className="w-3 h-3" />
          Broker Accepted
        </span>
      );
    }
    if (s === 'fare_offered') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
          <DollarSign className="w-3 h-3" />
          Fare Offered
        </span>
      );
    }
    if (s.includes('reject')) {
      return <Badge variant="danger">Rejected</Badge>;
    }
    if (s === 'cancelled') {
      return <Badge variant="danger">Cancelled</Badge>;
    }
    return <Badge variant="warning">Pending</Badge>;
  };

  // Render Compact Lifecycle Pill
  const renderLifecyclePill = (r: UserRequest) => {
    const s = (r.status || 'pending').toLowerCase();
    let step = 1;

    if (s.includes('reject')) {
      return (
        <div className="flex items-center gap-1.5 text-[11px] font-medium text-rose-400 bg-rose-500/10 px-2 py-0.5 rounded-lg border border-rose-500/20">
          <XCircle className="w-3 h-3" />
          <span>Declined</span>
        </div>
      );
    }
    if (s === 'completed' || s === 'delivered') {
      step = 5;
    } else if (s === 'in_transit' || s === 'heading_to_drop') {
      step = 4;
    } else if (s === 'accepted_by_driver' || s === 'driver_offer_sent') {
      step = 3;
    } else if (s === 'accepted' || s === 'fare_offered') {
      step = 2;
    }

    return (
      <div className="flex items-center gap-1.5 text-[11px] font-medium text-slate-300">
        <div className="flex gap-0.5">
          {[1, 2, 3, 4, 5].map((i) => (
            <span
              key={i}
              className={`w-1.5 h-3.5 rounded-sm ${
                i <= step ? 'bg-gradient-to-t from-sky-500 to-cyan-400' : 'bg-slate-800'
              }`}
            />
          ))}
        </div>
        <span className="text-[10px] text-slate-400 font-mono">Stage {step}/5</span>
      </div>
    );
  };

  // Currency formatter
  const formatPKR = (amount: number | string | undefined | null) => {
    if (amount === undefined || amount === null || amount === '') return 'Not finalized';
    const num = typeof amount === 'string' ? parseFloat(amount) : amount;
    if (isNaN(num) || num <= 0) return 'Not finalized';
    return `PKR ${num.toLocaleString()}`;
  };

  // Timestamp formatter
  const formatTimestamp = (val: any): string => {
    if (!val) return 'Timestamp not recorded';
    if (typeof val === 'string') return val;
    if (val.toDate && typeof val.toDate === 'function') {
      return val.toDate().toLocaleString();
    }
    if (val.seconds) {
      return new Date(val.seconds * 1000).toLocaleString();
    }
    return String(val);
  };

  // Section 7: Rejection / Cancellation Actor Analysis
  const rejectionAnalysis = useMemo(() => {
    if (!activeReq) return null;
    const status = (activeReq.status || '').toLowerCase();
    const isRejected = status.includes('reject') || status === 'cancelled';

    if (!isRejected) {
      return {
        isRejected: false,
        actor: null,
        description: 'Active record — No cancellation or rejection recorded.',
        reason: null,
      };
    }

    // Explicit actor in Firestore if present
    if (activeReq.rejection_actor || activeReq.rejected_by) {
      const actor = activeReq.rejection_actor || activeReq.rejected_by;
      return {
        isRejected: true,
        actor: actor,
        description: `Formally recorded as rejected by ${actor}.`,
        reason: activeReq.rejection_reason || activeReq.cancellationReason || null,
      };
    }

    // Check if a driver rejected
    const rejectedOffer = driverOffers.find((o) =>
      (o.status || '').toLowerCase().includes('reject')
    );
    if (status === 'rejected_by_driver' || rejectedOffer) {
      return {
        isRejected: true,
        actor: 'Driver',
        actorDetail: rejectedOffer?.driver_name || activeReq.driverName || 'Assigned Driver',
        driverId:
          rejectedOffer?.driver_id || activeReq.assigned_driver_id || activeReq.driverId,
        description:
          'The assigned driver declined the freight load offer. The order became available for broker reassignment.',
        reason: rejectedOffer?.rejection_reason || activeReq.rejection_reason || null,
      };
    }

    // Check if user declined broker quote
    const hadBrokerQuote = Boolean(
      activeReq.brokerOffer || activeReq.quoteAmount || activeReq.quote_submitted_at
    );
    const wasDealAccepted =
      activeReq.fareStatus === 'finalized' || Boolean(activeReq.accepted_fare);

    if (hadBrokerQuote && !wasDealAccepted) {
      return {
        isRejected: true,
        actor: 'User (Shipper)',
        actorDetail: activeReq.userName || 'Shipper',
        description: 'User (Shipper) declined the freight quote offered by the freight broker.',
        reason: activeReq.rejection_reason || null,
      };
    }

    // Check if broker rejected upfront
    if (
      activeReq.brokerId &&
      activeReq.brokerId !== 'notAssigned' &&
      activeReq.brokerId !== 'N/A' &&
      !hadBrokerQuote
    ) {
      return {
        isRejected: true,
        actor: 'Broker',
        actorDetail: activeReq.brokerName || 'Broker',
        description: 'Freight Broker declined or rejected the incoming load request before quoting.',
        reason: activeReq.rejection_reason || null,
      };
    }

    // Fallback: actor not definitively stored
    return {
      isRejected: true,
      actor: 'Actor: Not recorded in stored data',
      description: `Request status is marked "${activeReq.status}", but explicit actor identifier was not stored in the Firestore document.`,
      reason: activeReq.rejection_reason || activeReq.cancellationReason || null,
    };
  }, [activeReq, driverOffers]);

  return (
    <div className="space-y-6">
      {/* Top Banner Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center font-bold text-amber-400 shadow-sm">
              <FileText className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-2xl font-black text-white tracking-tight">Requests & Orders</h2>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  <Radio className="w-2.5 h-2.5 animate-pulse text-emerald-400" />
                  Live Sync
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-0.5">
                Centralized Super Admin lifecycle management for all freight load postings, broker deals, driver assignments, and completed deliveries.
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="px-3.5 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-300 flex items-center gap-2">
            <Layers className="w-3.5 h-3.5 text-amber-400" />
            <span>
              Total Live Records: <strong className="text-white font-mono">{requests.length}</strong>
            </span>
          </div>
          {isAnyFilterActive && (
            <button
              onClick={handleClearFilters}
              className="inline-flex items-center gap-1.5 px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 text-xs font-semibold rounded-xl border border-rose-500/20 transition-colors"
            >
              <X className="w-3.5 h-3.5" />
              Reset Filters
            </button>
          )}
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="p-4 bg-slate-900/80 backdrop-blur-xl rounded-2xl border border-slate-800 shadow-xl space-y-3">
        <div className="flex items-center justify-between gap-2 pb-2 border-b border-slate-800/60">
          <div className="flex items-center gap-2 text-xs font-bold text-slate-300 uppercase tracking-wider">
            <Filter className="w-3.5 h-3.5 text-sky-400" />
            <span>Unified Lifecycle & Entity Filters</span>
          </div>
          <span className="text-[11px] text-slate-500">
            Showing {sortedRequests.length} matching of {requests.length} total records
          </span>
        </div>

        {/* Filter Controls Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {/* Search Box */}
          <div className="lg:col-span-2 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              placeholder="Search Order #, Doc ID, User, Broker, Driver..."
              className="w-full pl-9 pr-3 py-2 bg-slate-950 border border-slate-700/60 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-sky-500 focus:ring-1 focus:ring-sky-500 transition-colors"
            />
          </div>

          {/* User Filter (Shipper) */}
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              User (Shipper)
            </label>
            <select
              value={selectedUserFilter}
              onChange={(e) => {
                setSelectedUserFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-2.5 py-2 bg-slate-950 border border-slate-700/60 rounded-xl text-xs text-slate-200 focus:outline-none focus:border-sky-500"
            >
              <option value="all">All Users</option>
              {users.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name || u.fullName || `Shipper (${u.id.substring(0, 6)})`}
                </option>
              ))}
            </select>
          </div>

          {/* Broker Filter */}
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Freight Broker
            </label>
            <select
              value={selectedBrokerFilter}
              onChange={(e) => {
                setSelectedBrokerFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-2.5 py-2 bg-slate-950 border border-slate-700/60 rounded-xl text-xs text-slate-200 focus:outline-none focus:border-sky-500"
            >
              <option value="all">All Brokers</option>
              {brokers.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name || b.companyName || `Broker (${b.id.substring(0, 6)})`}
                </option>
              ))}
            </select>
          </div>

          {/* Driver Filter */}
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Assigned Driver
            </label>
            <select
              value={selectedDriverFilter}
              onChange={(e) => {
                setSelectedDriverFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-2.5 py-2 bg-slate-950 border border-slate-700/60 rounded-xl text-xs text-slate-200 focus:outline-none focus:border-sky-500"
            >
              <option value="all">All Drivers</option>
              {drivers.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name || d.fullName || `Driver (${d.id.substring(0, 6)})`}
                </option>
              ))}
            </select>
          </div>

          {/* Status Filter */}
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Lifecycle Status
            </label>
            <select
              value={selectedStatusFilter}
              onChange={(e) => {
                setSelectedStatusFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-2.5 py-2 bg-slate-950 border border-slate-700/60 rounded-xl text-xs text-slate-200 focus:outline-none focus:border-sky-500"
            >
              <option value="all">All Statuses</option>
              <option value="pending">Pending Broker Quote</option>
              <option value="fare_offered">Fare Offered by Broker</option>
              <option value="accepted">Broker Accepted / Deal Agreed</option>
              <option value="driver_assigned">Driver Dispatched / Assigned</option>
              <option value="in_transit">In Transit / Live GPS</option>
              <option value="completed">Completed Delivery</option>
              <option value="rejected">Rejected / Cancelled</option>
            </select>
          </div>
        </div>

        {/* Cargo Quick Filter Badges */}
        {uniqueCargoTypes.length > 0 && (
          <div className="flex items-center gap-1.5 overflow-x-auto pt-1 text-xs">
            <span className="text-[10px] font-semibold text-slate-500 uppercase shrink-0 mr-1">
              Cargo:
            </span>
            <button
              onClick={() => setSelectedCargoFilter('all')}
              className={`px-2.5 py-1 rounded-lg text-[11px] font-medium transition-colors shrink-0 ${
                selectedCargoFilter === 'all'
                  ? 'bg-sky-500 text-slate-950 font-bold'
                  : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              All Cargo
            </button>
            {uniqueCargoTypes.map((cargo) => (
              <button
                key={cargo}
                onClick={() => setSelectedCargoFilter(cargo)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-medium transition-colors shrink-0 ${
                  selectedCargoFilter.toLowerCase() === cargo.toLowerCase()
                    ? 'bg-sky-500 text-slate-950 font-bold'
                    : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
                }`}
              >
                {cargo}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Main Request Data Table */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/60 backdrop-blur-xl shadow-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950/70 text-[11px] uppercase tracking-wider text-slate-400 border-b border-slate-800 font-bold select-none">
              <tr>
                {/* Column 1: Order No */}
                <th
                  onClick={() => handleSort('numericOrderNo')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Order No.</span>
                    <ArrowUpDown className="w-3 h-3 text-sky-400" />
                  </div>
                </th>

                {/* Column 2: User (Shipper) */}
                <th
                  onClick={() => handleSort('userName')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Shipper / User</span>
                    <ArrowUpDown className="w-3 h-3 opacity-60" />
                  </div>
                </th>

                {/* Column 3: Cargo Type */}
                <th
                  onClick={() => handleSort('itemType')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Cargo / Item</span>
                    <ArrowUpDown className="w-3 h-3 opacity-60" />
                  </div>
                </th>

                {/* Column 4: Fare / Deal */}
                <th
                  onClick={() => handleSort('finalFare')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Agreed / Deal Fare</span>
                    <ArrowUpDown className="w-3 h-3 text-emerald-400" />
                  </div>
                </th>

                {/* Column 5: Broker */}
                <th
                  onClick={() => handleSort('brokerName')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Broker</span>
                    <ArrowUpDown className="w-3 h-3 opacity-60" />
                  </div>
                </th>

                {/* Column 6: Driver */}
                <th
                  onClick={() => handleSort('driverName')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Driver & Fleet</span>
                    <ArrowUpDown className="w-3 h-3 opacity-60" />
                  </div>
                </th>

                {/* Column 7: Status */}
                <th
                  onClick={() => handleSort('status')}
                  className="px-5 py-4 cursor-pointer hover:text-white transition-colors"
                >
                  <div className="flex items-center gap-1">
                    <span>Status</span>
                    <ArrowUpDown className="w-3 h-3 opacity-60" />
                  </div>
                </th>

                {/* Column 8: Lifecycle Summary */}
                <th className="px-5 py-4">Lifecycle Step</th>

                {/* Column 9: Actions */}
                <th className="px-5 py-4 text-right">Dossier</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-800/60">
              {loading ? (
                <tr>
                  <td colSpan={9} className="px-6 py-16 text-center text-slate-400">
                    <div className="inline-flex items-center gap-3">
                      <div className="w-5 h-5 border-2 border-sky-400 border-t-transparent rounded-full animate-spin" />
                      <span className="text-sm font-medium">
                        Connecting to Firestore live request stream...
                      </span>
                    </div>
                  </td>
                </tr>
              ) : paginatedRequests.length === 0 ? (
                <tr>
                  <td colSpan={9} className="px-6 py-16 text-center text-slate-400">
                    <Package className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                    <p className="text-base font-semibold text-slate-200">
                      {isAnyFilterActive
                        ? 'No requests match the selected filters.'
                        : 'No requests found.'}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">
                      {isAnyFilterActive
                        ? 'Try clearing or changing your filter criteria.'
                        : 'Real-time listener is listening for new customer load postings in Firebase.'}
                    </p>
                    {isAnyFilterActive && (
                      <button
                        onClick={handleClearFilters}
                        className="mt-3 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold"
                      >
                        Clear All Filters
                      </button>
                    )}
                  </td>
                </tr>
              ) : (
                paginatedRequests.map((r) => {
                  const isBrokerAssigned =
                    r.brokerId && r.brokerId !== 'notAssigned' && r.brokerId !== 'N/A';
                  const isDriverAssigned =
                    r.assigned_driver_id &&
                    r.assigned_driver_id !== 'notAssigned' &&
                    r.assigned_driver_id !== 'N/A';

                  return (
                    <tr
                      key={r.id}
                      className="hover:bg-slate-800/30 transition-colors group cursor-pointer"
                      onClick={() => {
                        setSelectedReq(r);
                        setIsDetailOpen(true);
                      }}
                    >
                      {/* Column 1: Order No */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-lg bg-sky-500/10 border border-sky-500/20 flex items-center justify-center font-black text-sky-400 text-xs">
                            #{r.orderNo || r.id.substring(0, 4)}
                          </div>
                          <div>
                            <span className="font-mono font-bold text-white text-xs">
                              Order #{r.orderNo || r.id}
                            </span>
                            <p className="text-[10px] text-slate-500 font-mono truncate max-w-[120px]">
                              {r.date || (r.createdAt ? String(r.createdAt) : 'Date unrecorded')}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Column 2: User */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-300">
                            <User className="w-3.5 h-3.5" />
                          </div>
                          <div>
                            <p className="font-semibold text-slate-100">
                              {r.userName || 'Shipper'}
                            </p>
                            <p className="text-[10px] text-slate-500 font-mono">
                              {r.userPhone ||
                                (r.userUid ? `ID: ${r.userUid.substring(0, 8)}...` : 'User')}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Column 3: Cargo Type */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        <div>
                          <span className="font-semibold text-white">
                            {r.itemType || r.cargoType || 'General Freight'}
                          </span>
                          <div className="flex items-center gap-1.5 text-[10px] text-slate-400 mt-0.5">
                            <span>{r.weight ? `${r.weight} kg` : 'Weight —'}</span>
                            <span>•</span>
                            <span>{r.quantity ? `Qty: ${r.quantity}` : 'Qty —'}</span>
                          </div>
                        </div>
                      </td>

                      {/* Column 4: Fare */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        <div>
                          {r.fareStatus === 'finalized' && r.finalFare ? (
                            <div>
                              <span className="font-mono font-bold text-emerald-400 text-sm">
                                {formatPKR(r.finalFare)}
                              </span>
                              <span className="block text-[10px] font-semibold text-emerald-500/90 uppercase tracking-wider">
                                Agreed Deal
                              </span>
                            </div>
                          ) : r.fareStatus === 'offered' && r.finalFare ? (
                            <div>
                              <span className="font-mono font-semibold text-cyan-400 text-xs">
                                {formatPKR(r.finalFare)}
                              </span>
                              <span className="block text-[10px] text-cyan-500/80">
                                Offered Quote
                              </span>
                            </div>
                          ) : (
                            <div>
                              <span className="text-slate-500 font-medium text-xs italic">
                                Not finalized
                              </span>
                            </div>
                          )}
                        </div>
                      </td>

                      {/* Column 5: Broker */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        {isBrokerAssigned ? (
                          <div className="flex items-center gap-2">
                            <div className="w-6 h-6 rounded-lg bg-sky-500/10 text-sky-400 flex items-center justify-center border border-sky-500/20">
                              <Briefcase className="w-3 h-3" />
                            </div>
                            <div>
                              <p className="font-semibold text-slate-200">{r.brokerName}</p>
                              <p className="text-[10px] text-slate-500 font-mono">
                                ID: {r.brokerId ? r.brokerId.substring(0, 8) : ''}
                              </p>
                            </div>
                          </div>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-slate-800/80 text-slate-400 border border-slate-700/60">
                            Not Assigned
                          </span>
                        )}
                      </td>

                      {/* Column 6: Driver */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        {isDriverAssigned ? (
                          <div className="flex items-center gap-2">
                            <div className="w-6 h-6 rounded-lg bg-indigo-500/10 text-indigo-400 flex items-center justify-center border border-indigo-500/20">
                              <Truck className="w-3 h-3" />
                            </div>
                            <div>
                              <p className="font-semibold text-slate-200">{r.driverName}</p>
                              <p className="text-[10px] text-indigo-400/80 font-mono">
                                {r.driverVehicleNumber
                                  ? `${r.driverVehicleType || 'Truck'}: ${r.driverVehicleNumber}`
                                  : r.driverVehicleType || 'Vehicle Assigned'}
                              </p>
                            </div>
                          </div>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-slate-800/80 text-slate-400 border border-slate-700/60">
                            Not Assigned
                          </span>
                        )}
                      </td>

                      {/* Column 7: Status */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        {renderStatusBadge(r.status)}
                      </td>

                      {/* Column 8: Lifecycle */}
                      <td className="px-5 py-4 whitespace-nowrap">
                        {renderLifecyclePill(r)}
                      </td>

                      {/* Column 9: Inspect Button */}
                      <td className="px-5 py-4 whitespace-nowrap text-right">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedReq(r);
                            setIsDetailOpen(true);
                          }}
                          className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
                          title="View Request & Order Dossier"
                        >
                          <Eye className="w-4 h-4 text-sky-400" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        <div className="p-4 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400 bg-slate-950/40">
          <div>
            Showing{' '}
            <span className="font-semibold text-slate-200">
              {sortedRequests.length === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1}
            </span>{' '}
            to{' '}
            <span className="font-semibold text-slate-200">
              {Math.min(currentPage * itemsPerPage, sortedRequests.length)}
            </span>{' '}
            of <span className="font-semibold text-slate-200">{sortedRequests.length}</span> entries
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
              disabled={currentPage === 1 || loading}
              className="p-1.5 rounded-lg border border-slate-700 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="px-2 font-medium text-slate-300">
              {currentPage} / {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
              disabled={currentPage === totalPages || loading}
              className="p-1.5 rounded-lg border border-slate-700 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* 8-SECTION UNIFIED REQUEST & ORDER DOSSIER MODAL */}
      <Modal
        isOpen={isDetailOpen}
        onClose={() => {
          setIsDetailOpen(false);
          setDriverOffers([]);
        }}
        title={`Request & Order Dossier — Order #${activeReq?.orderNo || activeReq?.id || ''}`}
        maxWidth="4xl"
      >
        {activeReq && (() => {
          const selectedReq = activeReq;
          return (
            <div className="space-y-6 text-xs text-slate-300">
            {/* Dossier Header Banner */}
            <div className="flex flex-wrap items-center justify-between gap-3 p-4 rounded-xl bg-slate-950/90 border border-slate-800">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-gradient-to-tr from-sky-600 to-cyan-400 p-0.5 flex items-center justify-center font-black text-slate-950 shadow-md">
                  <Package className="w-6 h-6 text-slate-950" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-white text-base">
                      Order #{selectedReq.orderNo || selectedReq.id}
                    </span>
                    <span className="text-[10px] text-slate-500 font-mono">
                      (Firestore Doc ID: {selectedReq.id})
                    </span>
                  </div>
                  <p className="text-slate-400 mt-0.5">
                    Created at:{' '}
                    <strong className="text-slate-200">
                      {formatTimestamp(selectedReq.createdAt || selectedReq.date)}
                    </strong>
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                {renderStatusBadge(selectedReq.status)}
              </div>
            </div>

            {/* ========================================================= */}
            {/* SECTION 1: REQUEST INFORMATION */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-sky-400 font-bold uppercase tracking-wider text-[11px]">
                <Package className="w-4 h-4" />
                <span>Section 1 — Request Information</span>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Order Number
                  </span>
                  <p className="text-white font-mono font-bold text-sm mt-0.5">
                    #{selectedReq.orderNo || selectedReq.id}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Cargo / Item Type
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.itemType || selectedReq.cargoType || 'General Freight'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Weight & Quantity
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.weight ? `${selectedReq.weight} kg` : 'Weight unspec'} •{' '}
                    {selectedReq.quantity ? `Qty: ${selectedReq.quantity}` : 'Qty unspec'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Required Vehicle
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.vehicleType || selectedReq.vehicle_type || 'Standard Truck'}
                  </p>
                </div>
              </div>

              {/* Complete Pickup & Drop Locations */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-1">
                {/* Pickup */}
                <div className="p-3 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1.5">
                  <div className="flex items-center gap-1.5 text-emerald-400 font-semibold text-[11px]">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>Complete Pickup Location</span>
                  </div>
                  <p className="text-white font-medium text-xs">
                    {selectedReq.pickupLocation || 'No pickup address recorded'}
                  </p>
                  {(selectedReq.pickupLat || selectedReq.pickupLng) ? (
                    <div className="pt-1.5 border-t border-slate-800/60 flex items-center justify-between text-[10px]">
                      <span className="text-slate-400 font-mono">
                        Coordinates: {selectedReq.pickupLat?.toFixed(5)}, {selectedReq.pickupLng?.toFixed(5)}
                      </span>
                      <a
                        href={`https://www.google.com/maps?q=${selectedReq.pickupLat},${selectedReq.pickupLng}`}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 text-sky-400 hover:text-sky-300 font-semibold"
                      >
                        <ExternalLink className="w-2.5 h-2.5" />
                        Google Maps
                      </a>
                    </div>
                  ) : null}
                </div>

                {/* Drop */}
                <div className="p-3 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1.5">
                  <div className="flex items-center gap-1.5 text-rose-400 font-semibold text-[11px]">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>Complete Drop-off Location</span>
                  </div>
                  <p className="text-white font-medium text-xs">
                    {selectedReq.dropoffLocation || 'No drop-off address recorded'}
                  </p>
                  {(selectedReq.dropLat || selectedReq.dropLng) ? (
                    <div className="pt-1.5 border-t border-slate-800/60 flex items-center justify-between text-[10px]">
                      <span className="text-slate-400 font-mono">
                        Coordinates: {selectedReq.dropLat?.toFixed(5)}, {selectedReq.dropLng?.toFixed(5)}
                      </span>
                      <a
                        href={`https://www.google.com/maps?q=${selectedReq.dropLat},${selectedReq.dropLng}`}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 text-sky-400 hover:text-sky-300 font-semibold"
                      >
                        <ExternalLink className="w-2.5 h-2.5" />
                        Google Maps
                      </a>
                    </div>
                  ) : null}
                </div>
              </div>

              {selectedReq.additionalInfo && (
                <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800/80 text-slate-300">
                  <span className="text-slate-500 font-semibold uppercase text-[10px] block mb-0.5">
                    Shipper Additional Instructions:
                  </span>
                  <p className="text-xs leading-relaxed">{selectedReq.additionalInfo}</p>
                </div>
              )}
            </div>

            {/* ========================================================= */}
            {/* SECTION 2: USER INFORMATION & SPECIFIC ACTION */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-sky-400 font-bold uppercase tracking-wider text-[11px]">
                <User className="w-4 h-4" />
                <span>Section 2 — User Information & Shipper Action</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Shipper Name
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.userName || 'Shipper'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    User UID
                  </span>
                  <p className="text-slate-300 font-mono text-xs mt-0.5 truncate">
                    {selectedReq.userUid || selectedReq.userId || 'Not recorded'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Contact Phone
                  </span>
                  <p className="text-slate-300 font-mono text-xs mt-0.5">
                    {selectedReq.userPhone || 'Phone unrecorded'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Specific User Action
                  </span>
                  <div className="mt-0.5">
                    {selectedReq.fareStatus === 'finalized' || selectedReq.accepted_fare ? (
                      <span className="text-emerald-400 font-semibold text-xs flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3" />
                        Accepted Quote
                      </span>
                    ) : (selectedReq.status || '').toLowerCase().includes('reject') ? (
                      <span className="text-rose-400 font-semibold text-xs flex items-center gap-1">
                        <XCircle className="w-3 h-3" />
                        Declined / Cancelled
                      </span>
                    ) : selectedReq.status === 'fare_offered' ? (
                      <span className="text-cyan-400 font-semibold text-xs flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        Evaluating Quote
                      </span>
                    ) : (
                      <span className="text-amber-400 font-semibold text-xs flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        Created Load Posting
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* ========================================================= */}
            {/* SECTION 3: BROKER ACTIVITY */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-sky-400 font-bold uppercase tracking-wider text-[11px]">
                <Briefcase className="w-4 h-4" />
                <span>Section 3 — Freight Broker Activity</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Broker Name
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.brokerName || (
                      <span className="text-slate-500 italic font-normal">Not Assigned</span>
                    )}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Broker UID
                  </span>
                  <p className="text-slate-300 font-mono text-xs mt-0.5 truncate">
                    {selectedReq.brokerId && selectedReq.brokerId !== 'notAssigned'
                      ? selectedReq.brokerId
                      : 'Not Assigned'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Broker Quoted Fare
                  </span>
                  <p className="text-cyan-400 font-bold text-sm mt-0.5">
                    {formatPKR(selectedReq.customer_fare || selectedReq.brokerOffer || selectedReq.quoteAmount)}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Broker Contact Phone
                  </span>
                  <p className="text-slate-300 font-mono text-xs mt-0.5">
                    {selectedReq.brokerPhone || 'Phone unrecorded'}
                  </p>
                </div>
              </div>
            </div>

            {/* ========================================================= */}
            {/* SECTION 4: FINAL BROKER DEAL */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-emerald-400 font-bold uppercase tracking-wider text-[11px]">
                <FileCheck className="w-4 h-4" />
                <span>Section 4 — Final Broker Deal</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Final Agreed Fare (`accepted_fare`)
                  </span>
                  <p className="text-emerald-400 font-black text-base mt-0.5">
                    {formatPKR(selectedReq.accepted_fare || selectedReq.finalFare)}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Agreed Broker
                  </span>
                  <p className="text-white font-bold text-sm mt-0.5">
                    {selectedReq.brokerName || 'No broker agreement'}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-slate-500 font-semibold uppercase text-[10px]">
                    Agreement Timestamp
                  </span>
                  <p className="text-slate-300 font-mono text-xs mt-0.5">
                    {selectedReq.deal_accepted_at || selectedReq.accepted_at
                      ? formatTimestamp(selectedReq.deal_accepted_at || selectedReq.accepted_at)
                      : selectedReq.fareStatus === 'finalized'
                      ? 'Recorded on quote acceptance'
                      : 'Deal not yet closed'}
                  </p>
                </div>
              </div>
            </div>

            {/* ========================================================= */}
            {/* SECTION 5: DRIVER INFORMATION */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-indigo-400 font-bold uppercase tracking-wider text-[11px]">
                <Truck className="w-4 h-4" />
                <span>Section 5 — Driver Information</span>
              </div>

              {selectedReq.assigned_driver_id &&
              selectedReq.assigned_driver_id !== 'notAssigned' &&
              selectedReq.assigned_driver_id !== 'N/A' ? (
                <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                  <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                    <span className="text-slate-500 font-semibold uppercase text-[10px]">
                      Driver Name
                    </span>
                    <p className="text-white font-bold text-sm mt-0.5">
                      {selectedReq.driverName || 'Driver Assigned'}
                    </p>
                  </div>

                  <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                    <span className="text-slate-500 font-semibold uppercase text-[10px]">
                      Driver UID
                    </span>
                    <p className="text-slate-300 font-mono text-xs mt-0.5 truncate">
                      {selectedReq.assigned_driver_id || selectedReq.driverId}
                    </p>
                  </div>

                  <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                    <span className="text-slate-500 font-semibold uppercase text-[10px]">
                      Assigned Vehicle
                    </span>
                    <p className="text-white font-mono font-bold text-xs mt-0.5">
                      {selectedReq.driverVehicleNumber
                        ? `${selectedReq.driverVehicleType || 'Truck'}: ${selectedReq.driverVehicleNumber}`
                        : selectedReq.driverVehicleType || 'Vehicle Assigned'}
                    </p>
                  </div>

                  <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                    <span className="text-slate-500 font-semibold uppercase text-[10px]">
                      Agreed Driver Fare
                    </span>
                    <p className="text-indigo-400 font-bold text-sm mt-0.5">
                      {formatPKR(selectedReq.assigned_fare || selectedReq.driver_fare)}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 text-center py-5">
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    <AlertTriangle className="w-3.5 h-3.5" />
                    Driver: Not assigned
                  </span>
                  <p className="text-xs text-slate-500 mt-2">
                    No transporter or driver has been assigned to this order yet.
                  </p>
                </div>
              )}
            </div>

            {/* ========================================================= */}
            {/* SECTION 6: DRIVER RESPONSE & REASSIGNMENT HISTORY */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-indigo-400 font-bold uppercase tracking-wider text-[11px]">
                  <History className="w-4 h-4" />
                  <span>Section 6 — Driver Response & Reassignment History</span>
                </div>
                <span className="text-[10px] text-slate-500 font-mono">
                  Subcollection: Orders/{selectedReq.orderId || selectedReq.id}/DriverOffers
                </span>
              </div>

              {loadingOffers ? (
                <div className="p-6 text-center text-slate-400 bg-slate-950/40 rounded-xl">
                  <div className="w-4 h-4 border-2 border-indigo-400 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                  <span>Streaming driver offers...</span>
                </div>
              ) : driverOffers.length === 0 ? (
                <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 text-center py-5">
                  <p className="text-slate-400 font-medium">No driver offers dispatched yet.</p>
                  <p className="text-[11px] text-slate-500 mt-1">
                    When the freight broker dispatches offers to drivers via TruckLink AI, all offer attempts, responses, and reassignments will stream here in real time.
                  </p>
                </div>
              ) : (
                <div className="rounded-xl border border-slate-800/80 overflow-hidden bg-slate-950/60">
                  <table className="w-full text-left text-xs text-slate-300">
                    <thead className="bg-slate-900/80 text-[10px] uppercase font-bold text-slate-400 border-b border-slate-800">
                      <tr>
                        <th className="px-3.5 py-2.5">Driver Name & UID</th>
                        <th className="px-3.5 py-2.5">Offered Fare</th>
                        <th className="px-3.5 py-2.5">Vehicle</th>
                        <th className="px-3.5 py-2.5">Dispatched At</th>
                        <th className="px-3.5 py-2.5">Driver Status</th>
                        <th className="px-3.5 py-2.5">Response Notes</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50 text-[11px]">
                      {driverOffers.map((offer) => {
                        const offerStatus = (offer.status || 'pending').toLowerCase();
                        const isAccepted = offerStatus === 'accepted_by_driver';
                        const isRejected = offerStatus.includes('reject');

                        return (
                          <tr key={offer.id} className="hover:bg-slate-800/30 transition-colors">
                            <td className="px-3.5 py-2.5 whitespace-nowrap">
                              <p className="font-semibold text-white">
                                {offer.driver_name || 'Driver'}
                              </p>
                              <p className="text-[10px] text-slate-500 font-mono">
                                ID: {offer.driver_id || 'ID unrecorded'}
                              </p>
                            </td>

                            <td className="px-3.5 py-2.5 whitespace-nowrap font-mono font-semibold text-emerald-400">
                              {formatPKR(offer.fare)}
                            </td>

                            <td className="px-3.5 py-2.5 whitespace-nowrap text-slate-300">
                              {offer.vehicle_number
                                ? `${offer.vehicle_type || 'Truck'}: ${offer.vehicle_number}`
                                : offer.vehicle_type || 'Truck'}
                            </td>

                            <td className="px-3.5 py-2.5 whitespace-nowrap text-slate-400 font-mono text-[10px]">
                              {formatTimestamp(offer.created_at)}
                            </td>

                            <td className="px-3.5 py-2.5 whitespace-nowrap">
                              {isAccepted ? (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                  <CheckCircle2 className="w-2.5 h-2.5" />
                                  Accepted by Driver
                                </span>
                              ) : isRejected ? (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                                  <XCircle className="w-2.5 h-2.5" />
                                  Rejected by Driver
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                                  <Clock className="w-2.5 h-2.5" />
                                  Awaiting Response
                                </span>
                              )}
                            </td>

                            <td className="px-3.5 py-2.5 text-slate-400 max-w-[180px] truncate">
                              {offer.rejection_reason ? (
                                <span className="text-rose-300">
                                  Reason: {offer.rejection_reason}
                                </span>
                              ) : offer.accepted_at ? (
                                <span className="text-emerald-400/80 font-mono text-[10px]">
                                  Accepted: {formatTimestamp(offer.accepted_at)}
                                </span>
                              ) : (
                                <span className="text-slate-500 italic">—</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* ========================================================= */}
            {/* SECTION 7: REJECTION / CANCELLATION ACTOR ANALYSIS */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-3">
              <div className="flex items-center gap-2 text-rose-400 font-bold uppercase tracking-wider text-[11px]">
                <ShieldAlert className="w-4 h-4" />
                <span>Section 7 — Rejection / Cancellation Actor Analysis</span>
              </div>

              {rejectionAnalysis?.isRejected ? (
                <div className="p-4 rounded-xl bg-rose-950/20 border border-rose-800/40 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="px-2.5 py-0.5 rounded-md text-xs font-bold bg-rose-500/20 text-rose-300 border border-rose-500/30">
                        Actor: {rejectionAnalysis.actor}
                      </span>
                      {rejectionAnalysis.actorDetail && (
                        <span className="text-xs text-slate-300 font-medium">
                          ({rejectionAnalysis.actorDetail})
                        </span>
                      )}
                    </div>
                    <span className="text-[10px] font-mono text-rose-400/70">
                      Status: {selectedReq.status}
                    </span>
                  </div>

                  <p className="text-slate-200 text-xs leading-relaxed">
                    {rejectionAnalysis.description}
                  </p>

                  {rejectionAnalysis.reason && (
                    <div className="p-2.5 rounded-lg bg-slate-950/60 border border-slate-800 text-slate-300 text-xs">
                      <strong className="text-rose-400 uppercase text-[10px] block">
                        Reason Provided:
                      </strong>
                      <p className="mt-0.5">{rejectionAnalysis.reason}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="p-3.5 rounded-xl bg-emerald-950/20 border border-emerald-800/40 flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
                  <div>
                    <h5 className="font-semibold text-emerald-300 text-xs">
                      Active Order — No Rejection or Cancellation
                    </h5>
                    <p className="text-[11px] text-slate-400 mt-0.5">
                      This freight request has progressed normally without cancellations by the User, Broker, or Driver.
                    </p>
                  </div>
                </div>
              )}
            </div>

            {/* ========================================================= */}
            {/* SECTION 8: CHRONOLOGICAL LIFECYCLE TIMELINE */}
            {/* ========================================================= */}
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-sky-400 font-bold uppercase tracking-wider text-[11px]">
                  <Clock className="w-4 h-4" />
                  <span>Section 8 — Chronological Real Firestore Lifecycle Timeline</span>
                </div>
                <span className="text-[10px] text-slate-500">Real Timestamps Only</span>
              </div>

              <div className="relative pl-6 space-y-4 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-800">
                {/* 1. Request Created */}
                <div className="relative">
                  <div className="absolute -left-6 top-0.5 w-4 h-4 rounded-full bg-emerald-500 flex items-center justify-center text-slate-950 font-black text-[9px]">
                    ✓
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">1. Freight Request Created</h5>
                      <span className="text-emerald-400 text-[10px] font-mono">
                        {formatTimestamp(selectedReq.createdAt || selectedReq.date)}
                      </span>
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      Customer {selectedReq.userName || 'User'} created load posting for{' '}
                      <strong className="text-slate-200">
                        {selectedReq.itemType || selectedReq.cargoType || 'General Freight'}
                      </strong>
                    </p>
                  </div>
                </div>

                {/* 2. Broker Assignment & Quotation */}
                <div className="relative">
                  <div
                    className={`absolute -left-6 top-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      selectedReq.brokerId && selectedReq.brokerId !== 'notAssigned'
                        ? 'bg-sky-500 text-slate-950'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {selectedReq.brokerId && selectedReq.brokerId !== 'notAssigned' ? '✓' : '2'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">2. Broker Assignment & Quotation</h5>
                      {selectedReq.quote_submitted_at && (
                        <span className="text-sky-400 text-[10px] font-mono">
                          {formatTimestamp(selectedReq.quote_submitted_at)}
                        </span>
                      )}
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      {selectedReq.brokerName && selectedReq.brokerName !== 'Not Assigned'
                        ? `Freight Broker ${selectedReq.brokerName} quoted ${formatPKR(
                            selectedReq.customer_fare || selectedReq.brokerOffer || selectedReq.quoteAmount
                          )}`
                        : 'Awaiting broker review and quotation'}
                    </p>
                  </div>
                </div>

                {/* 3. Deal Acceptance */}
                <div className="relative">
                  <div
                    className={`absolute -left-6 top-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      selectedReq.fareStatus === 'finalized' || selectedReq.accepted_fare
                        ? 'bg-emerald-500 text-slate-950'
                        : (selectedReq.status || '').toLowerCase().includes('reject')
                        ? 'bg-rose-500 text-white'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {selectedReq.fareStatus === 'finalized' || selectedReq.accepted_fare
                      ? '✓'
                      : (selectedReq.status || '').toLowerCase().includes('reject')
                      ? '✕'
                      : '3'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">3. Deal Acceptance & Agreed Fare</h5>
                      {(selectedReq.deal_accepted_at || selectedReq.accepted_at) && (
                        <span className="text-emerald-400 text-[10px] font-mono">
                          {formatTimestamp(selectedReq.deal_accepted_at || selectedReq.accepted_at)}
                        </span>
                      )}
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      {selectedReq.fareStatus === 'finalized' || selectedReq.accepted_fare
                        ? `Deal agreed between User and Broker for ${formatPKR(
                            selectedReq.accepted_fare || selectedReq.finalFare
                          )}`
                        : (selectedReq.status || '').toLowerCase().includes('reject')
                        ? 'Deal was rejected / declined'
                        : 'Pending customer acceptance'}
                    </p>
                  </div>
                </div>

                {/* 4. Driver Dispatch & Assignment */}
                <div className="relative">
                  <div
                    className={`absolute -left-6 top-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      selectedReq.assigned_driver_id && selectedReq.assigned_driver_id !== 'notAssigned'
                        ? 'bg-indigo-500 text-white'
                        : driverOffers.length > 0
                        ? 'bg-amber-500 text-slate-950'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {selectedReq.assigned_driver_id && selectedReq.assigned_driver_id !== 'notAssigned'
                      ? '✓'
                      : '4'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">4. Driver Assignment & Offers</h5>
                      {driverOffers.length > 0 && (
                        <span className="text-indigo-400 text-[10px] font-mono">
                          {formatTimestamp(driverOffers[0].created_at)}
                        </span>
                      )}
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      {selectedReq.driverName && selectedReq.driverName !== 'Not Assigned'
                        ? `Driver ${selectedReq.driverName} assigned (${
                            selectedReq.driverVehicleType || 'Truck'
                          }: ${selectedReq.driverVehicleNumber || 'Reg unrecorded'})`
                        : driverOffers.length > 0
                        ? `${driverOffers.length} driver offer(s) dispatched by broker`
                        : 'No driver offers dispatched yet'}
                    </p>
                  </div>
                </div>

                {/* 5. In Transit */}
                <div className="relative">
                  <div
                    className={`absolute -left-6 top-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      ['in_transit', 'heading_to_drop', 'completed', 'delivered'].includes(
                        (selectedReq.status || '').toLowerCase()
                      )
                        ? 'bg-cyan-500 text-slate-950'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {['in_transit', 'heading_to_drop', 'completed', 'delivered'].includes(
                      (selectedReq.status || '').toLowerCase()
                    )
                      ? '✓'
                      : '5'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">5. In Transit (Active GPS Telemetry)</h5>
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      {['in_transit', 'heading_to_drop', 'completed', 'delivered'].includes(
                        (selectedReq.status || '').toLowerCase()
                      )
                        ? 'Shipment in active transit with driver'
                        : 'Trip journey has not started'}
                    </p>
                  </div>
                </div>

                {/* 6. Completed Delivery */}
                <div className="relative">
                  <div
                    className={`absolute -left-6 top-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      ['completed', 'delivered'].includes((selectedReq.status || '').toLowerCase())
                        ? 'bg-emerald-500 text-slate-950'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {['completed', 'delivered'].includes((selectedReq.status || '').toLowerCase())
                      ? '✓'
                      : '6'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h5 className="text-white font-bold">6. Consignment Delivery Completed</h5>
                      {(selectedReq.completed_at || selectedReq.delivered_at) && (
                        <span className="text-emerald-400 text-[10px] font-mono">
                          {formatTimestamp(selectedReq.completed_at || selectedReq.delivered_at)}
                        </span>
                      )}
                    </div>
                    <p className="text-slate-400 text-[11px] mt-0.5">
                      {['completed', 'delivered'].includes((selectedReq.status || '').toLowerCase())
                        ? 'Load successfully delivered to destination'
                        : 'Pending final drop-off and recipient confirmation'}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="pt-4 border-t border-slate-800 flex justify-end gap-3">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold transition-colors"
              >
                Close Dossier
              </button>
            </div>
            </div>
          );
        })()}
      </Modal>
    </div>
  );
};
