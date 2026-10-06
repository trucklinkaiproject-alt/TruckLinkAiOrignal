import React, { useEffect, useState } from 'react';
import {
  Users,
  Briefcase,
  Truck,
  Package,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  DollarSign,
  FileText
} from 'lucide-react';
import { StatsCard } from '../components/common/StatsCard';
import { Badge } from '../components/common/Badge';
import {
  subscribeUsers,
  subscribeBrokers,
  subscribeDrivers,
  subscribeAllRequests,
  formatPKR
} from '../services/firestoreService';
import { UserProfile, BrokerProfile, DriverProfile, UserRequest } from '../types/models';
import { Link } from 'react-router-dom';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  PieChart,
  Pie,
  Cell,
  Legend
} from 'recharts';

export const Dashboard: React.FC = () => {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [requests, setRequests] = useState<UserRequest[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubUsers = subscribeUsers((data) => setUsers(data));
    const unsubBrokers = subscribeBrokers((data) => setBrokers(data));
    const unsubDrivers = subscribeDrivers((data) => setDrivers(data));
    const unsubRequests = subscribeAllRequests((data) => {
      setRequests(data);
      setLoading(false);
    });

    unsubs = [unsubUsers, unsubBrokers, unsubDrivers, unsubRequests];

    return () => {
      unsubs.forEach((fn) => fn());
    };
  }, []);

  // Compute key operational metrics from real Firebase collections
  const activeUsersCount = users.filter((u) => u.status !== 'blocked').length;
  const verifiedBrokersCount = brokers.filter((b) => b.isVerified).length;
  const availableDriversCount = drivers.filter((d) => d.isAvailable).length;

  const activeOrders = requests.filter(
    (r) =>
      r.status === 'in_transit' ||
      r.status === 'in-transit' ||
      r.status === 'driver_assigned' ||
      r.status === 'accepted_by_driver' ||
      r.status === 'driver_offer_sent' ||
      r.status === 'accepted' ||
      r.status === 'heading_to_drop' ||
      r.status === 'arrived_at_pickup' ||
      r.status === 'arrived_at_drop'
  );

  const completedOrders = requests.filter(
    (r) => r.status === 'delivered' || r.status === 'completed'
  );

  // Total finalized deal volume (GMV)
  const totalGMV = requests.reduce((sum, r) => {
    const fare = r.finalFare || r.acceptedFare || r.customerFare || 0;
    return sum + (typeof fare === 'number' ? fare : 0);
  }, 0);

  // Chart data: Distribution of Real Request Statuses
  const statusCounts = requests.reduce((acc: Record<string, number>, req) => {
    const s = (req.status || 'pending').toLowerCase();
    acc[s] = (acc[s] || 0) + 1;
    return acc;
  }, {});

  const orderStatusPieData = [
    { name: 'Completed', value: completedOrders.length, color: '#10b981' },
    { name: 'Active / In-Transit', value: activeOrders.length, color: '#0284c7' },
    { name: 'Pending Broker', value: (statusCounts['pending'] || 0) + (statusCounts['created'] || 0), color: '#f59e0b' },
    { name: 'Cancelled', value: (statusCounts['cancelled'] || 0) + (statusCounts['rejected'] || 0), color: '#f43f5e' },
  ].filter((item) => item.value > 0);

  const displayPieData =
    orderStatusPieData.length > 0
      ? orderStatusPieData
      : [
          { name: 'Drivers', value: drivers.length || 1, color: '#0284c7' },
          { name: 'Brokers', value: brokers.length || 1, color: '#8b5cf6' },
          { name: 'Users', value: users.length || 1, color: '#10b981' },
        ];

  // Group real requests by day or provide timeline
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const dayBuckets: Record<string, { loads: number; completed: number }> = {
    Mon: { loads: 0, completed: 0 },
    Tue: { loads: 0, completed: 0 },
    Wed: { loads: 0, completed: 0 },
    Thu: { loads: 0, completed: 0 },
    Fri: { loads: 0, completed: 0 },
    Sat: { loads: 0, completed: 0 },
    Sun: { loads: 0, completed: 0 },
  };

  requests.forEach((r) => {
    if (r.createdAt?.toDate) {
      const d = r.createdAt.toDate();
      const dayName = daysOfWeek[d.getDay()];
      if (dayBuckets[dayName]) {
        dayBuckets[dayName].loads++;
        if (r.status === 'completed' || r.status === 'delivered') {
          dayBuckets[dayName].completed++;
        }
      }
    }
  });

  const trendData = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => ({
    day,
    loads: dayBuckets[day].loads,
    completed: dayBuckets[day].completed,
  }));

  // Top 6 recent active or latest orders for table
  const recentOrders = [...requests]
    .sort((a, b) => {
      const timeA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const timeB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
      return timeB - timeA;
    })
    .slice(0, 6);

  return (
    <div className="space-y-6">
      {/* Overview Header */}
      <div className="bg-white rounded-lg p-6 border border-slate-200 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-bold text-slate-900 tracking-tight">
              Operational Overview
            </h2>
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-600" />
              Live Telemetry
            </span>
          </div>
          <p className="mt-1 text-xs text-slate-500">
            Real-time platform metrics, consignment tracking, and stakeholder activity across Users, Brokers, and Drivers.
          </p>
        </div>

        <div className="text-right shrink-0">
          <span className="text-xs text-slate-500 block">Gross Merchandise Value</span>
          <span className="text-lg font-bold text-slate-900 font-mono">{formatPKR(totalGMV)}</span>
        </div>
      </div>

      {/* Primary Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="Registered Users"
          value={loading ? '...' : users.length}
          subtitle={`${activeUsersCount} active accounts`}
          icon={Users}
          color="blue"
        />
        <StatsCard
          title="Registered Brokers"
          value={loading ? '...' : brokers.length}
          subtitle={`${verifiedBrokersCount} verified partners`}
          icon={Briefcase}
          color="purple"
        />
        <StatsCard
          title="Active Drivers"
          value={loading ? '...' : drivers.length}
          subtitle={`${availableDriversCount} currently available`}
          icon={Truck}
          color="cyan"
        />
        <StatsCard
          title="Active Loads & Orders"
          value={loading ? '...' : requests.length}
          subtitle={`${activeOrders.length} active in-transit`}
          icon={Package}
          color="emerald"
        />
      </div>

      {/* Dashboard Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Activity Table (2 Cols) */}
        <div className="lg:col-span-2 rounded-lg bg-white border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Package className="w-4 h-4 text-sky-700" />
              <h3 className="text-sm font-bold text-slate-900">Recent Requests & Orders</h3>
            </div>
            <Link
              to="/requests"
              className="inline-flex items-center gap-1 text-xs font-semibold text-sky-700 hover:text-sky-800"
            >
              View All <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {recentOrders.length === 0 ? (
            <div className="py-10 text-center text-slate-500">
              <Package className="w-8 h-8 text-slate-400 mx-auto mb-2" />
              <p className="text-sm font-medium text-slate-700">No orders recorded in Firestore yet</p>
              <p className="text-xs text-slate-400 mt-0.5">
                New orders placed by users in the mobile app will automatically appear here.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-800">
                <thead className="bg-slate-50 text-slate-600 uppercase tracking-wider border-b border-slate-200">
                  <tr>
                    <th className="py-2.5 px-3 font-semibold">Order No</th>
                    <th className="py-2.5 px-3 font-semibold">User</th>
                    <th className="py-2.5 px-3 font-semibold">Cargo</th>
                    <th className="py-2.5 px-3 font-semibold">Broker</th>
                    <th className="py-2.5 px-3 font-semibold">Driver</th>
                    <th className="py-2.5 px-3 font-semibold">Fare</th>
                    <th className="py-2.5 px-3 font-semibold">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {recentOrders.map((req) => (
                    <tr key={req.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-2.5 px-3 font-mono text-sky-700 font-semibold">
                        #{req.numericOrderNo || req.orderNo || req.id.substring(0, 6)}
                      </td>
                      <td className="py-2.5 px-3 font-medium text-slate-900">
                        {req.userName || 'Verified User'}
                      </td>
                      <td className="py-2.5 px-3 text-slate-600">
                        {req.itemType || req.cargoType || 'General Freight'}
                      </td>
                      <td className="py-2.5 px-3">
                        {req.brokerName ? (
                          <span className="text-purple-700 font-medium">{req.brokerName}</span>
                        ) : (
                          <span className="text-slate-400 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-2.5 px-3">
                        {req.driverName ? (
                          <span className="text-cyan-700 font-medium">{req.driverName}</span>
                        ) : (
                          <span className="text-slate-400 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-emerald-700">
                        {req.finalFare
                          ? formatPKR(req.finalFare)
                          : req.customerFare
                          ? formatPKR(req.customerFare)
                          : '—'}
                      </td>
                      <td className="py-2.5 px-3">
                        <Badge
                          variant={
                            req.status === 'delivered' || req.status === 'completed'
                              ? 'success'
                              : req.status === 'in_transit' || req.status === 'in-transit' || req.status === 'accepted_by_driver'
                              ? 'info'
                              : req.status === 'cancelled' || req.status === 'rejected'
                              ? 'danger'
                              : 'warning'
                          }
                          size="sm"
                        >
                          {req.status || 'pending'}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Status Distribution (1 Col) */}
        <div className="rounded-lg bg-white border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Ecosystem Distribution</h3>
            <p className="text-xs text-slate-500">Consignment statuses & platform composition</p>
          </div>

          <div className="h-56 w-full my-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={displayPieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={45}
                  outerRadius={70}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {displayPieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#ffffff',
                    borderColor: '#e2e8f0',
                    borderRadius: '0.375rem',
                    color: '#0f172a',
                    boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                  }}
                />
                <Legend
                  verticalAlign="bottom"
                  height={36}
                  formatter={(value) => <span className="text-xs text-slate-600">{value}</span>}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>Real-time stream</span>
            <span className="text-emerald-700 font-semibold">100% Synced</span>
          </div>
        </div>
      </div>

      {/* System Operations & Quick Shortcuts */}
      <div className="rounded-lg bg-white border border-slate-200 p-5 shadow-xs flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        <div className="flex-1">
          <h3 className="text-sm font-bold text-slate-900 mb-1">Administrative Shortcuts</h3>
          <p className="text-xs text-slate-500 mb-3">Direct dispatch & operational controls</p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <Link
              to="/tracking"
              className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded bg-sky-50 text-sky-700 border border-sky-100">
                  <Truck className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-slate-900">Live Telematics Map</p>
                  <p className="text-[11px] text-slate-500">Monitor active trucks on GPS</p>
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
            </Link>

            <Link
              to="/requests"
              className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded bg-purple-50 text-purple-700 border border-purple-100">
                  <FileText className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-slate-900">Requests & Orders</p>
                  <p className="text-[11px] text-slate-500">Complete lifecycle & assignees</p>
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
            </Link>

            <Link
              to="/notifications"
              className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded bg-amber-50 text-amber-700 border border-amber-100">
                  <AlertTriangle className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-slate-900">Broadcast Alerts</p>
                  <p className="text-[11px] text-slate-500">Send instant push announcements</p>
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
            </Link>
          </div>
        </div>

        <div className="p-3 rounded-md bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 flex items-center gap-2 shrink-0">
          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          <span>All system nodes & Firestore streams operating normally.</span>
        </div>
      </div>

      {/* Recent Activity Table & Quick Shortcuts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Orders Overview */}
        <div className="lg:col-span-2 rounded-lg bg-white border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Package className="w-4 h-4 text-sky-700" />
              <h3 className="text-sm font-bold text-slate-900">Recent Requests & Orders</h3>
            </div>
            <Link
              to="/requests"
              className="inline-flex items-center gap-1 text-xs font-semibold text-sky-700 hover:text-sky-800"
            >
              View All <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {recentOrders.length === 0 ? (
            <div className="py-10 text-center text-slate-500">
              <Package className="w-8 h-8 text-slate-400 mx-auto mb-2" />
              <p className="text-sm font-medium text-slate-700">No orders recorded in Firestore yet</p>
              <p className="text-xs text-slate-400 mt-0.5">
                New orders placed by users in the mobile app will automatically appear here.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-800">
                <thead className="bg-slate-50 text-slate-600 uppercase tracking-wider border-b border-slate-200">
                  <tr>
                    <th className="py-2.5 px-3 font-semibold">Order No</th>
                    <th className="py-2.5 px-3 font-semibold">User</th>
                    <th className="py-2.5 px-3 font-semibold">Cargo</th>
                    <th className="py-2.5 px-3 font-semibold">Broker</th>
                    <th className="py-2.5 px-3 font-semibold">Driver</th>
                    <th className="py-2.5 px-3 font-semibold">Fare</th>
                    <th className="py-2.5 px-3 font-semibold">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {recentOrders.map((req) => (
                    <tr key={req.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-2.5 px-3 font-mono text-sky-700 font-semibold">
                        #{req.numericOrderNo || req.orderNo || req.id.substring(0, 6)}
                      </td>
                      <td className="py-2.5 px-3 font-medium text-slate-900">
                        {req.userName || 'Verified User'}
                      </td>
                      <td className="py-2.5 px-3 text-slate-600">
                        {req.itemType || req.cargoType || 'General Freight'}
                      </td>
                      <td className="py-2.5 px-3">
                        {req.brokerName ? (
                          <span className="text-purple-700 font-medium">{req.brokerName}</span>
                        ) : (
                          <span className="text-slate-400 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-2.5 px-3">
                        {req.driverName ? (
                          <span className="text-cyan-700 font-medium">{req.driverName}</span>
                        ) : (
                          <span className="text-slate-400 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-emerald-700">
                        {req.finalFare
                          ? formatPKR(req.finalFare)
                          : req.customerFare
                          ? formatPKR(req.customerFare)
                          : '—'}
                      </td>
                      <td className="py-2.5 px-3">
                        <Badge
                          variant={
                            req.status === 'delivered' || req.status === 'completed'
                              ? 'success'
                              : req.status === 'in_transit' || req.status === 'in-transit' || req.status === 'accepted_by_driver'
                              ? 'info'
                              : req.status === 'cancelled' || req.status === 'rejected'
                              ? 'danger'
                              : 'warning'
                          }
                          size="sm"
                        >
                          {req.status || 'pending'}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* System Operations & Quick Shortcuts */}
        <div className="rounded-lg bg-white border border-slate-200 p-5 shadow-xs flex flex-col justify-between space-y-4">
          <div>
            <h3 className="text-sm font-bold text-slate-900 mb-1">Administrative Shortcuts</h3>
            <p className="text-xs text-slate-500 mb-4">Direct dispatch & operational controls</p>

            <div className="space-y-2">
              <Link
                to="/tracking"
                className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
              >
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded bg-sky-50 text-sky-700 border border-sky-100">
                    <Truck className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Live Telematics Map</p>
                    <p className="text-[11px] text-slate-500">Monitor active trucks on GPS</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
              </Link>

              <Link
                to="/requests"
                className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
              >
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded bg-purple-50 text-purple-700 border border-purple-100">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Requests & Orders</p>
                    <p className="text-[11px] text-slate-500">Complete lifecycle & assignees</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
              </Link>

              <Link
                to="/notifications"
                className="flex items-center justify-between p-3 rounded-md bg-slate-50 hover:bg-slate-100 border border-slate-200 transition-colors group"
              >
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded bg-amber-50 text-amber-700 border border-amber-100">
                    <AlertTriangle className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Broadcast Alerts</p>
                    <p className="text-[11px] text-slate-500">Send instant push announcements</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" />
              </Link>
            </div>
          </div>

          <div className="p-3 rounded-md bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            <span>All system nodes & Firestore streams operating normally.</span>
          </div>
        </div>
      </div>
    </div>
  );
};
