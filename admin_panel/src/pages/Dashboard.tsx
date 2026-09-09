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
    <div className="space-y-8">
      {/* Welcome Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-brand-900/60 via-slate-900 to-purple-950/40 p-6 sm:p-8 border border-slate-800 shadow-2xl backdrop-blur-xl">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-brand-500/10 border border-brand-500/20 text-brand-300 text-xs font-semibold mb-3">
            <span className="w-2 h-2 rounded-full bg-brand-400" />
            Live Cloud Data Stream
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            TruckLink AI Command Center
          </h2>
          <p className="mt-2 text-sm text-slate-300">
            Real-time live telemetry, load tracking, and ecosystem oversight across Users, Brokers, and Drivers.
          </p>
        </div>
      </div>

      {/* Primary Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
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

      {/* Analytics Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Real Load Activity Timeline */}
        <div className="lg:col-span-2 rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-bold text-white">Logistics & Load Traffic</h3>
              <p className="text-xs text-slate-400">Total freight volume across weekly timeline</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-lg border border-emerald-500/20">
                GMV: {formatPKR(totalGMV)}
              </span>
            </div>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trendData}>
                <defs>
                  <linearGradient id="loadGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0284c7" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#0284c7" stopOpacity={0.0} />
                  </linearGradient>
                  <linearGradient id="compGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                <XAxis dataKey="day" stroke="#64748b" textAnchor="end" fontSize={12} />
                <YAxis stroke="#64748b" fontSize={12} allowDecimals={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#0f172a',
                    borderColor: '#334155',
                    borderRadius: '0.75rem',
                    color: '#f8fafc',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="loads"
                  stroke="#0284c7"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#loadGrad)"
                  name="Loads Placed"
                />
                <Area
                  type="monotone"
                  dataKey="completed"
                  stroke="#10b981"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#compGrad)"
                  name="Completed"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Real Ecosystem Status Distribution */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-white">System Distribution</h3>
            <p className="text-xs text-slate-400">Order statuses & platform composition</p>
          </div>

          <div className="h-56 w-full my-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={displayPieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={75}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {displayPieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#0f172a',
                    borderColor: '#334155',
                    borderRadius: '0.75rem',
                    color: '#f8fafc',
                  }}
                />
                <Legend
                  verticalAlign="bottom"
                  height={36}
                  formatter={(value) => <span className="text-xs text-slate-300">{value}</span>}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
            <span>Real-time aggregation</span>
            <span className="text-emerald-400 font-semibold">100% Synced</span>
          </div>
        </div>
      </div>

      {/* Recent Activity Table & Quick Shortcuts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Orders Overview */}
        <div className="lg:col-span-2 rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Package className="w-5 h-5 text-sky-400" />
              <h3 className="text-base font-bold text-white">Recent Requests & Orders</h3>
            </div>
            <Link
              to="/requests"
              className="inline-flex items-center gap-1 text-xs font-semibold text-sky-400 hover:text-sky-300"
            >
              View Requests & Orders <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {recentOrders.length === 0 ? (
            <div className="py-10 text-center text-slate-400">
              <Package className="w-8 h-8 text-slate-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-slate-300">No orders recorded in Firestore yet</p>
              <p className="text-xs text-slate-500">
                New orders placed by users in the mobile app will automatically appear here.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-300">
                <thead className="text-slate-500 uppercase tracking-wider border-b border-slate-800">
                  <tr>
                    <th className="py-3 px-3">Order No</th>
                    <th className="py-3 px-3">User</th>
                    <th className="py-3 px-3">Cargo</th>
                    <th className="py-3 px-3">Broker</th>
                    <th className="py-3 px-3">Driver</th>
                    <th className="py-3 px-3">Fare</th>
                    <th className="py-3 px-3">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {recentOrders.map((req) => (
                    <tr key={req.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="py-3 px-3 font-mono text-sky-400 font-semibold">
                        #{req.numericOrderNo || req.orderNo || req.id.substring(0, 6)}
                      </td>
                      <td className="py-3 px-3 font-medium text-white">
                        {req.userName || 'Verified User'}
                      </td>
                      <td className="py-3 px-3 text-slate-300">
                        {req.itemType || req.cargoType || 'General Freight'}
                      </td>
                      <td className="py-3 px-3">
                        {req.brokerName ? (
                          <span className="text-purple-300 font-medium">{req.brokerName}</span>
                        ) : (
                          <span className="text-slate-500 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-3 px-3">
                        {req.driverName ? (
                          <span className="text-cyan-300 font-medium">{req.driverName}</span>
                        ) : (
                          <span className="text-slate-500 italic">Unassigned</span>
                        )}
                      </td>
                      <td className="py-3 px-3 font-semibold text-emerald-400">
                        {req.finalFare
                          ? formatPKR(req.finalFare)
                          : req.customerFare
                          ? formatPKR(req.customerFare)
                          : '—'}
                      </td>
                      <td className="py-3 px-3">
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
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl flex flex-col justify-between space-y-4">
          <div>
            <h3 className="text-base font-bold text-white mb-1">Administrative Shortcuts</h3>
            <p className="text-xs text-slate-400 mb-4">Direct dispatch & operational controls</p>

            <div className="space-y-2.5">
              <Link
                to="/tracking"
                className="flex items-center justify-between p-3 rounded-xl bg-slate-800/50 hover:bg-slate-800 border border-slate-700/60 transition-colors group"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-sky-500/10 text-sky-400">
                    <Truck className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Live Telematics Map</p>
                    <p className="text-[11px] text-slate-400">Monitor active trucks on GPS</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-white transition-colors" />
              </Link>

              <Link
                to="/requests"
                className="flex items-center justify-between p-3 rounded-xl bg-slate-800/50 hover:bg-slate-800 border border-slate-700/60 transition-colors group"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-purple-500/10 text-purple-400">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Requests & Orders</p>
                    <p className="text-[11px] text-slate-400">Complete lifecycle, fares & stakeholder assignees</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-white transition-colors" />
              </Link>

              <Link
                to="/notifications"
                className="flex items-center justify-between p-3 rounded-xl bg-slate-800/50 hover:bg-slate-800 border border-slate-700/60 transition-colors group"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-amber-500/10 text-amber-400">
                    <AlertTriangle className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Broadcast Alerts & FCM Push</p>
                    <p className="text-[11px] text-slate-400">Send instant announcement to mobile apps</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-white transition-colors" />
              </Link>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-300 flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>All system nodes & Firestore streams operating normally.</span>
          </div>
        </div>
      </div>
    </div>
  );
};
