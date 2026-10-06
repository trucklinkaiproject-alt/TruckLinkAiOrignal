import React, { useEffect, useState } from 'react';
import {
  BarChart3,
  TrendingUp,
  DollarSign,
  Package,
  Truck,
  Briefcase,
  Users,
  MapPin,
  Calendar,
  Layers,
  Award
} from 'lucide-react';
import {
  subscribeAllRequests,
  subscribeUsers,
  subscribeBrokers,
  subscribeDrivers,
  formatPKR
} from '../services/firestoreService';
import { UserRequest, UserProfile, BrokerProfile, DriverProfile } from '../types/models';
import { StatsCard } from '../components/common/StatsCard';
import { Badge } from '../components/common/Badge';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  LineChart,
  Line,
  Legend
} from 'recharts';

export const Analytics: React.FC = () => {
  const [requests, setRequests] = useState<UserRequest[]>([]);
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubUsers = subscribeUsers((data) => setUsers(data));
    const unsubBrokers = subscribeBrokers((data) => setBrokers(data));
    const unsubDrivers = subscribeDrivers((data) => setDrivers(data));
    const unsubReqs = subscribeAllRequests((data) => {
      setRequests(data);
      setLoading(false);
    });

    unsubs = [unsubUsers, unsubBrokers, unsubDrivers, unsubReqs];
    return () => unsubs.forEach((fn) => fn());
  }, []);

  // 1. Real GMV & Financial Metrics
  const nonCancelledRequests = requests.filter(
    (r) => r.status !== 'cancelled' && r.status !== 'rejected'
  );

  const totalGMV = nonCancelledRequests.reduce((sum, r) => {
    const fare = r.finalFare || r.acceptedFare || r.customerFare || 0;
    return sum + (typeof fare === 'number' ? fare : 0);
  }, 0);

  const completedOrders = requests.filter(
    (r) => r.status === 'delivered' || r.status === 'completed'
  );

  const avgDealValue =
    nonCancelledRequests.length > 0
      ? Math.round(totalGMV / nonCancelledRequests.length)
      : 0;

  const availableDrivers = drivers.filter((d) => d.isAvailable).length;
  const driverAvailabilityRate =
    drivers.length > 0 ? Math.round((availableDrivers / drivers.length) * 100) : 0;

  // 2. Real Freight Corridors (pickupCity → dropCity)
  const corridorMap: Record<string, { corridor: string; volume: number; revenue: number }> = {};

  requests.forEach((r) => {
    const origin = (r.pickupCity || r.pickupComp || r.pickupLocation || 'Origin').trim();
    const dest = (r.dropCity || r.dropComp || r.dropoffLocation || 'Destination').trim();
    const key = `${origin} → ${dest}`;
    const fare = r.finalFare || r.acceptedFare || r.customerFare || 0;

    if (!corridorMap[key]) {
      corridorMap[key] = { corridor: key, volume: 0, revenue: 0 };
    }
    corridorMap[key].volume += 1;
    if (typeof fare === 'number') {
      corridorMap[key].revenue += fare;
    }
  });

  const topCorridors = Object.values(corridorMap)
    .sort((a, b) => b.volume - a.volume)
    .slice(0, 6);

  // 3. Real timeline data: Group requests by date/month
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const monthlyAgg: Record<string, { month: string; shipments: number; gmv: number }> = {};

  // Initialize with current & previous 5 months
  const now = new Date();
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const label = monthNames[d.getMonth()];
    monthlyAgg[label] = { month: label, shipments: 0, gmv: 0 };
  }

  requests.forEach((r) => {
    if (r.createdAt?.toDate) {
      const d = r.createdAt.toDate();
      const label = monthNames[d.getMonth()];
      if (monthlyAgg[label]) {
        monthlyAgg[label].shipments += 1;
        const fare = r.finalFare || r.acceptedFare || r.customerFare || 0;
        if (typeof fare === 'number') {
          monthlyAgg[label].gmv += Math.round(fare / 1000); // in thousands
        }
      }
    }
  });

  const monthlyTimelineData = Object.values(monthlyAgg);

  // 4. Top Performing Brokers by assigned load count
  const brokerLoadCount: Record<string, { broker: BrokerProfile; count: number; revenue: number }> = {};
  brokers.forEach((b) => {
    brokerLoadCount[b.id] = { broker: b, count: 0, revenue: 0 };
  });

  requests.forEach((r) => {
    if (r.brokerId && brokerLoadCount[r.brokerId]) {
      brokerLoadCount[r.brokerId].count += 1;
      const fare = r.finalFare || r.acceptedFare || 0;
      if (typeof fare === 'number') {
        brokerLoadCount[r.brokerId].revenue += fare;
      }
    }
  });

  const topBrokers = Object.values(brokerLoadCount)
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  // 5. Top Performing Drivers by assigned load count
  const driverLoadCount: Record<string, { driver: DriverProfile; count: number }> = {};
  drivers.forEach((d) => {
    driverLoadCount[d.id] = { driver: d, count: 0 };
  });

  requests.forEach((r) => {
    if (r.driverId && driverLoadCount[r.driverId]) {
      driverLoadCount[r.driverId].count += 1;
    }
  });

  const topDrivers = Object.values(driverLoadCount)
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-sky-700" />
            <h2 className="text-xl font-bold text-slate-900">Logistics & Revenue Analytics</h2>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Real-time telemetry, gross merchandise value (GMV), regional freight corridors, and carrier utilization.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-600 bg-white px-3.5 py-2 rounded-md border border-slate-200 shadow-2xs">
          <Calendar className="w-4 h-4 text-sky-700" />
          <span>
            Database State: <strong className="text-emerald-700">100% Live Firebase Data</strong>
          </span>
        </div>
      </div>

      {/* Primary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatsCard
          title="Gross Merchandise Value"
          value={loading ? '...' : formatPKR(totalGMV)}
          subtitle="Finalized & active consignments"
          color="emerald"
          icon={DollarSign}
        />
        <StatsCard
          title="Completed Shipments"
          value={loading ? '...' : completedOrders.length}
          subtitle={`Out of ${requests.length} total orders`}
          color="blue"
          icon={Package}
        />
        <StatsCard
          title="Avg. Deal Value"
          value={loading ? '...' : formatPKR(avgDealValue)}
          subtitle="Mean freight rate per shipment"
          color="purple"
          icon={TrendingUp}
        />
        <StatsCard
          title="Driver Availability"
          value={loading ? '...' : `${driverAvailabilityRate}%`}
          subtitle={`${availableDrivers} of ${drivers.length} drivers ready`}
          color="cyan"
          icon={Truck}
        />
      </div>

      {/* Main Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Monthly Shipments & Revenue Trend */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Platform Throughput & Velocity</h3>
              <p className="text-xs text-slate-500">Shipment volume and GMV across recent months</p>
            </div>
            <span className="text-xs font-semibold text-emerald-800 bg-emerald-50 px-2.5 py-1 rounded-sm border border-emerald-200">
              Live Stream
            </span>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={monthlyTimelineData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="month" stroke="#64748b" fontSize={12} />
                <YAxis stroke="#64748b" fontSize={12} allowDecimals={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#ffffff',
                    borderColor: '#e2e8f0',
                    borderRadius: '0.375rem',
                    color: '#0f172a',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                  }}
                />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="shipments"
                  stroke="#0369a1"
                  strokeWidth={2.5}
                  name="Shipments Placed"
                />
                <Line
                  type="monotone"
                  dataKey="gmv"
                  stroke="#059669"
                  strokeWidth={2.5}
                  name="GMV (x1000 PKR)"
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Major Freight Corridors */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Top Freight Corridors</h3>
              <p className="text-xs text-slate-500">Shipment volume by origin and destination</p>
            </div>
            <span className="text-xs font-semibold text-sky-800 bg-sky-50 px-2.5 py-1 rounded-sm border border-sky-200">
              Corridor Rank
            </span>
          </div>

          {topCorridors.length === 0 ? (
            <div className="h-64 flex flex-col items-center justify-center text-slate-400 text-xs text-center">
              <MapPin className="w-8 h-8 text-slate-300 mb-2" />
              <p className="text-slate-600 font-medium">No freight corridors logged yet</p>
              <p className="text-slate-400 mt-1 max-w-xs">
                When users post requests with pickup & drop-off locations, corridors will be calculated here.
              </p>
            </div>
          ) : (
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={topCorridors}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="corridor" stroke="#64748b" fontSize={11} />
                  <YAxis stroke="#64748b" fontSize={12} allowDecimals={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#ffffff',
                      borderColor: '#e2e8f0',
                      borderRadius: '0.375rem',
                      color: '#0f172a',
                      boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                    }}
                    formatter={(value: any, name: string) => [
                      name === 'volume' ? `${value} loads` : formatPKR(value),
                      name === 'volume' ? 'Loads Dispatched' : 'Total Corridor Value',
                    ]}
                  />
                  <Bar
                    dataKey="volume"
                    fill="#0284c7"
                    radius={[4, 4, 0, 0]}
                    name="Loads Dispatched"
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* Top Performers Row: Brokers & Drivers */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Brokers */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <Briefcase className="w-4 h-4 text-sky-700" />
              <h3 className="text-sm font-bold text-slate-900">Active Broker Partners</h3>
            </div>
            <span className="text-xs text-slate-500">{brokers.length} Registered Brokers</span>
          </div>

          {topBrokers.length === 0 ? (
            <div className="py-8 text-center text-xs text-slate-400">No brokers registered yet.</div>
          ) : (
            <div className="space-y-2.5">
              {topBrokers.map(({ broker, count, revenue }, idx) => (
                <div
                  key={broker.id}
                  className="p-3.5 rounded-md bg-slate-50 border border-slate-200/80 flex items-center justify-between hover:bg-slate-100/70 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-6 h-6 rounded-sm bg-slate-200 border border-slate-300 text-slate-700 font-bold text-xs flex items-center justify-center font-mono">
                      #{idx + 1}
                    </span>
                    <div>
                      <p className="text-xs font-bold text-slate-900">
                        {broker.companyName || broker.name || 'Broker Partner'}
                      </p>
                      <p className="text-[11px] text-slate-500">
                        {broker.city || 'Pakistan'} • {broker.rating ? `${broker.rating} ★` : 'Unrated'}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <p className="text-xs font-bold text-emerald-700">
                      {count} {count === 1 ? 'Order' : 'Orders'}
                    </p>
                    {revenue > 0 && (
                      <p className="text-[11px] text-slate-500 font-mono">{formatPKR(revenue)}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Top Drivers */}
        <div className="rounded-lg bg-white border border-slate-200 p-6 shadow-2xs">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <Truck className="w-4 h-4 text-sky-700" />
              <h3 className="text-sm font-bold text-slate-900">Active Driver Fleets</h3>
            </div>
            <span className="text-xs text-slate-500">{drivers.length} Registered Drivers</span>
          </div>

          {topDrivers.length === 0 ? (
            <div className="py-8 text-center text-xs text-slate-400">No drivers registered yet.</div>
          ) : (
            <div className="space-y-2.5">
              {topDrivers.map(({ driver, count }, idx) => (
                <div
                  key={driver.id}
                  className="p-3.5 rounded-md bg-slate-50 border border-slate-200/80 flex items-center justify-between hover:bg-slate-100/70 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-6 h-6 rounded-sm bg-slate-200 border border-slate-300 text-slate-700 font-bold text-xs flex items-center justify-center font-mono">
                      #{idx + 1}
                    </span>
                    <div>
                      <p className="text-xs font-bold text-slate-900">
                        {driver.name || 'Driver Partner'}
                      </p>
                      <p className="text-[11px] text-slate-500">
                        {driver.vehicleNumber ? `Vehicle: ${driver.vehicleNumber}` : 'Licensed Driver'} •{' '}
                        {driver.rating ? `${driver.rating} ★` : 'Unrated'}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <Badge variant={driver.isAvailable ? 'success' : 'warning'} size="sm">
                      {driver.isAvailable ? 'Available' : 'On Trip'}
                    </Badge>
                    <p className="text-[11px] text-slate-500 mt-1">
                      {count} {count === 1 ? 'Trip' : 'Trips'}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
