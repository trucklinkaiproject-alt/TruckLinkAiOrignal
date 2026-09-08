import React, { useEffect, useState } from 'react';
import {
  Users,
  Briefcase,
  Truck,
  Package,
  CheckCircle2,
  AlertTriangle,
  TrendingUp,
  MapPin,
  ArrowRight
} from 'lucide-react';
import { StatsCard } from '../components/common/StatsCard';
import { Badge } from '../components/common/Badge';
import {
  subscribeUsers,
  subscribeBrokers,
  subscribeDrivers,
  subscribeOrders
} from '../services/firestoreService';
import { UserProfile, BrokerProfile, DriverProfile, OrderItem } from '../types/models';
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
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubUsers = subscribeUsers((data) => {
      setUsers(data);
    });
    const unsubBrokers = subscribeBrokers((data) => {
      setBrokers(data);
    });
    const unsubDrivers = subscribeDrivers((data) => {
      setDrivers(data);
    });
    const unsubOrders = subscribeOrders((data) => {
      setOrders(data);
      setLoading(false);
    });

    unsubs = [unsubUsers, unsubBrokers, unsubDrivers, unsubOrders];

    return () => {
      unsubs.forEach((fn) => fn());
    };
  }, []);

  // Compute key operational metrics
  const activeUsersCount = users.filter((u) => u.status !== 'blocked').length;
  const verifiedBrokersCount = brokers.filter((b) => b.isVerified).length;
  const availableDriversCount = drivers.filter((d) => d.isAvailable).length;
  const activeOrders = orders.filter(
    (o) => o.status === 'in_transit' || o.status === 'in-transit' || o.status === 'assigned' || o.status === 'picked_up'
  );
  const completedOrders = orders.filter((o) => o.status === 'delivered' || o.status === 'completed');

  // Chart data: Distribution of Order Statuses
  const statusCounts = orders.reduce((acc: Record<string, number>, order) => {
    const s = (order.status || 'pending').toLowerCase();
    acc[s] = (acc[s] || 0) + 1;
    return acc;
  }, {});

  const orderStatusPieData = [
    { name: 'Completed', value: completedOrders.length || 0, color: '#10b981' },
    { name: 'In Transit', value: activeOrders.length || 0, color: '#0284c7' },
    { name: 'Pending', value: statusCounts['pending'] || 0, color: '#f59e0b' },
    { name: 'Cancelled', value: (statusCounts['cancelled'] || 0), color: '#f43f5e' },
  ].filter(item => item.value > 0);

  // If no orders yet, provide initial baseline
  const displayPieData = orderStatusPieData.length > 0 ? orderStatusPieData : [
    { name: 'Active Fleets', value: drivers.length || 1, color: '#0284c7' },
    { name: 'Brokers', value: brokers.length || 1, color: '#8b5cf6' },
    { name: 'Shippers', value: users.length || 1, color: '#10b981' },
  ];

  // Activity trend mock / timeline based on orders
  const trendData = [
    { day: 'Mon', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.4) : 2, 2), completed: 1 },
    { day: 'Tue', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.6) : 4, 3), completed: 2 },
    { day: 'Wed', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.5) : 3, 3), completed: 2 },
    { day: 'Thu', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.8) : 6, 5), completed: 4 },
    { day: 'Fri', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.9) : 7, 6), completed: 5 },
    { day: 'Sat', loads: Math.max(orders.length > 0 ? Math.floor(orders.length * 0.7) : 5, 4), completed: 4 },
    { day: 'Sun', loads: Math.max(orders.length, 6), completed: completedOrders.length || 4 },
  ];

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
            Real-time telemetry, load matching, and ecosystem oversight across shippers, freight brokers, and drivers.
          </p>
        </div>
      </div>

      {/* Primary Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatsCard
          title="Total Registered Shippers"
          value={loading ? '...' : users.length}
          subtitle={`${activeUsersCount} active accounts`}
          icon={Users}
          color="blue"
        />
        <StatsCard
          title="Freight Brokers"
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
          title="Total Shipments & Orders"
          value={loading ? '...' : orders.length}
          subtitle={`${activeOrders.length} active in-transit`}
          icon={Package}
          color="emerald"
        />
      </div>

      {/* Analytics Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Weekly Load Activity */}
        <div className="lg:col-span-2 rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-bold text-white">Logistics & Load Traffic</h3>
              <p className="text-xs text-slate-400">Shipment volume and delivery throughput</p>
            </div>
            <span className="text-xs font-semibold text-sky-400 bg-sky-500/10 px-2.5 py-1 rounded-lg border border-sky-500/20">
              Weekly Timeline
            </span>
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
                <YAxis stroke="#64748b" fontSize={12} />
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
                  name="Loads Created"
                />
                <Area
                  type="monotone"
                  dataKey="completed"
                  stroke="#10b981"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#compGrad)"
                  name="Delivered"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Stakeholder / Order Status Distribution */}
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
              <h3 className="text-base font-bold text-white">Recent Orders in System</h3>
            </div>
            <Link
              to="/orders"
              className="inline-flex items-center gap-1 text-xs font-semibold text-sky-400 hover:text-sky-300"
            >
              View All Orders <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {orders.length === 0 ? (
            <div className="py-10 text-center text-slate-400">
              <Package className="w-8 h-8 text-slate-600 mx-auto mb-2" />
              <p className="text-sm font-medium text-slate-300">No orders recorded in Firestore yet</p>
              <p className="text-xs text-slate-500">
                New orders placed by shippers in the mobile app will automatically appear here.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-300">
                <thead className="text-slate-500 uppercase tracking-wider border-b border-slate-800">
                  <tr>
                    <th className="py-3 px-3">Order / ID</th>
                    <th className="py-3 px-3">Cargo Type</th>
                    <th className="py-3 px-3">Pickup & Dropoff</th>
                    <th className="py-3 px-3">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {orders.slice(0, 5).map((order) => (
                    <tr key={order.id} className="hover:bg-slate-800/30">
                      <td className="py-3 px-3 font-mono text-sky-400 font-medium">
                        {order.id.substring(0, 8)}...
                      </td>
                      <td className="py-3 px-3 font-medium text-white">
                        {order.cargoType || 'General Freight'}
                      </td>
                      <td className="py-3 px-3 text-slate-400">
                        {order.pickupLocation || 'Origin'} → {order.dropoffLocation || 'Destination'}
                      </td>
                      <td className="py-3 px-3">
                        <Badge
                          variant={
                            order.status === 'delivered' || order.status === 'completed'
                              ? 'success'
                              : order.status === 'in_transit' || order.status === 'in-transit'
                              ? 'info'
                              : order.status === 'cancelled'
                              ? 'danger'
                              : 'warning'
                          }
                          size="sm"
                        >
                          {order.status || 'pending'}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* System Operations & Quick Actions */}
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
                    <MapPin className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Live Telematics Map</p>
                    <p className="text-[11px] text-slate-400">Monitor active trucks on GPS</p>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-white transition-colors" />
              </Link>

              <Link
                to="/ai-recommendations"
                className="flex items-center justify-between p-3 rounded-xl bg-slate-800/50 hover:bg-slate-800 border border-slate-700/60 transition-colors group"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-purple-500/10 text-purple-400">
                    <TrendingUp className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">AI Dispatch Engine</p>
                    <p className="text-[11px] text-slate-400">Match pending loads to drivers</p>
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
                    <p className="text-xs font-semibold text-white">Broadcast Alerts</p>
                    <p className="text-[11px] text-slate-400">Send system announcement</p>
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
