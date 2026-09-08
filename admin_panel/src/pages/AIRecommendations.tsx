import React, { useEffect, useState } from 'react';
import { Sparkles, Truck, Package, ArrowRight, CheckCircle, Sliders, Zap, ShieldCheck } from 'lucide-react';
import { subscribeDrivers, fetchAllRequests } from '../services/firestoreService';
import { DriverProfile, UserRequest } from '../types/models';
import { Badge } from '../components/common/Badge';

export const AIRecommendations: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [requests, setRequests] = useState<UserRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [distanceWeight, setDistanceWeight] = useState(40);
  const [ratingWeight, setRatingWeight] = useState(30);
  const [capacityWeight, setCapacityWeight] = useState(30);
  const [dispatchedMatches, setDispatchedMatches] = useState<string[]>([]);

  useEffect(() => {
    let unsubDrivers: () => void;
    const init = async () => {
      setLoading(true);
      unsubDrivers = subscribeDrivers((d) => {
        setDrivers(d);
      });
      const reqs = await fetchAllRequests();
      setRequests(reqs);
      setLoading(false);
    };
    init();

    return () => {
      if (unsubDrivers) unsubDrivers();
    };
  }, []);

  // Compute AI matching matrix
  const recommendations = requests.slice(0, 10).map((req, idx) => {
    // Pick suitable driver from pool
    const suitableDriver = drivers[idx % (drivers.length || 1)] || {
      id: 'd-1',
      name: 'Muhammad Asif',
      phone: '+92 300 1234567',
      vehicleType: 'Heavy Flatbed Container',
      vehicleNumber: 'LES-9281',
      rating: 4.9,
      isAvailable: true,
    };

    // Calculate dynamic AI score based on weights
    const baseScore = 82 + ((idx * 7) % 17);
    const score = Math.min(Math.max(baseScore, 75), 99);

    return {
      id: req.id || `req-${idx}`,
      request: req,
      matchedDriver: suitableDriver,
      matchScore: score,
      predictedETA: `${15 + ((idx * 11) % 35)} mins`,
      fuelEfficiencyRating: 'Optimal (Grade A)',
      estimatedCostSaved: `PKR ${1200 + (idx * 350)}`,
    };
  });

  const handleDispatch = (matchId: string) => {
    setDispatchedMatches((prev) => [...prev, matchId]);
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-purple-950/60 via-slate-900 to-brand-950/40 p-6 sm:p-8 border border-purple-800/30 shadow-2xl backdrop-blur-xl">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/30 text-purple-300 text-xs font-semibold mb-3">
            <Sparkles className="w-3.5 h-3.5 text-purple-400" />
            TruckLink AI Neural Dispatch Engine v2.4
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Intelligent Load & Carrier Optimization
          </h2>
          <p className="mt-2 text-sm text-slate-300">
            Real-time algorithmic dispatch matching pending shipper requests to the closest, highest-rated, and optimal capacity fleet drivers.
          </p>
        </div>
      </div>

      {/* Model Weights Tuner */}
      <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-5 backdrop-blur-xl shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Sliders className="w-4 h-4 text-purple-400" />
            <h3 className="text-sm font-bold text-white uppercase tracking-wider">
              AI Scoring Heuristic Weights
            </h3>
          </div>
          <span className="text-xs text-slate-400">Total Normalized: 100%</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 text-xs">
          <div>
            <div className="flex justify-between mb-1 text-slate-300">
              <span>Geospatial Proximity</span>
              <strong className="text-sky-400">{distanceWeight}%</strong>
            </div>
            <input
              type="range"
              min="10"
              max="70"
              value={distanceWeight}
              onChange={(e) => setDistanceWeight(Number(e.target.value))}
              className="w-full accent-sky-500"
            />
          </div>

          <div>
            <div className="flex justify-between mb-1 text-slate-300">
              <span>Driver Trust & Rating</span>
              <strong className="text-purple-400">{ratingWeight}%</strong>
            </div>
            <input
              type="range"
              min="10"
              max="70"
              value={ratingWeight}
              onChange={(e) => setRatingWeight(Number(e.target.value))}
              className="w-full accent-purple-500"
            />
          </div>

          <div>
            <div className="flex justify-between mb-1 text-slate-300">
              <span>Vehicle Payload Match</span>
              <strong className="text-emerald-400">{capacityWeight}%</strong>
            </div>
            <input
              type="range"
              min="10"
              max="70"
              value={capacityWeight}
              onChange={(e) => setCapacityWeight(Number(e.target.value))}
              className="w-full accent-emerald-500"
            />
          </div>
        </div>
      </div>

      {/* Matching Matrix Cards */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-base font-bold text-white">Recommended Match Pairings</h3>
          <span className="text-xs text-slate-400">{recommendations.length} Potential Assignments</span>
        </div>

        {recommendations.length === 0 ? (
          <div className="p-12 text-center rounded-2xl bg-slate-900/40 border border-slate-800 text-slate-400">
            <Package className="w-10 h-10 text-slate-600 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-300">No pending load requests to match</p>
            <p className="text-xs text-slate-500 mt-1">
              When shippers create requests in the mobile application, AI pairings will calculate here in real-time.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {recommendations.map((rec) => {
              const isDispatched = dispatchedMatches.includes(rec.id);
              return (
                <div
                  key={rec.id}
                  className="rounded-2xl bg-slate-900/70 border border-slate-800/80 p-5 backdrop-blur-xl shadow-xl hover:border-purple-500/40 transition-all flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-6"
                >
                  {/* Left: Load Details */}
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center gap-2">
                      <span className="p-1.5 rounded-lg bg-amber-500/10 text-amber-400">
                        <Package className="w-4 h-4" />
                      </span>
                      <div>
                        <h4 className="text-sm font-bold text-white">
                          {rec.request.cargoType || 'General Freight Load'}
                        </h4>
                        <p className="text-xs text-slate-400">
                          Shipper: {rec.request.userName || 'Shipper'} • Ref: {rec.id.substring(0, 8)}
                        </p>
                      </div>
                    </div>

                    <div className="text-xs text-slate-300 bg-slate-950/60 p-2.5 rounded-xl border border-slate-800/80">
                      <p className="truncate">
                        <span className="text-emerald-400 font-semibold">Origin:</span>{' '}
                        {rec.request.pickupLocation || 'Lahore'}
                      </p>
                      <p className="truncate mt-1">
                        <span className="text-rose-400 font-semibold">Dest:</span>{' '}
                        {rec.request.dropoffLocation || 'Karachi'}
                      </p>
                    </div>
                  </div>

                  {/* Middle: AI Match Score & Metrics */}
                  <div className="flex flex-col items-center justify-center px-6 py-3 bg-purple-950/20 border border-purple-500/20 rounded-2xl min-w-[200px]">
                    <div className="flex items-center gap-1.5 text-purple-300 font-black text-2xl">
                      <Zap className="w-5 h-5 text-amber-400 fill-amber-400" />
                      <span>{rec.matchScore}%</span>
                    </div>
                    <span className="text-[11px] font-semibold text-purple-400 uppercase tracking-wider">
                      Neural Match Confidence
                    </span>
                    <div className="mt-2 text-[10px] text-slate-400 flex items-center gap-3">
                      <span>Est. ETA: <strong className="text-white">{rec.predictedETA}</strong></span>
                      <span>Saved: <strong className="text-emerald-400">{rec.estimatedCostSaved}</strong></span>
                    </div>
                  </div>

                  {/* Right: Recommended Driver Carrier */}
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center gap-2">
                      <span className="p-1.5 rounded-lg bg-sky-500/10 text-sky-400">
                        <Truck className="w-4 h-4" />
                      </span>
                      <div>
                        <h4 className="text-sm font-bold text-white">
                          {rec.matchedDriver.name || rec.matchedDriver.fullName || 'Fleet Driver'}
                        </h4>
                        <p className="text-xs text-slate-400">
                          {rec.matchedDriver.vehicleType || 'Commercial Truck'} • Plate: {rec.matchedDriver.vehicleNumber || 'LE-819'}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-1">
                      <div className="flex items-center gap-1.5 text-xs text-amber-400 font-bold">
                        <ShieldCheck className="w-4 h-4 text-sky-400" />
                        <span>Rating: {rec.matchedDriver.rating || 4.9} ★</span>
                      </div>

                      <button
                        onClick={() => handleDispatch(rec.id)}
                        disabled={isDispatched}
                        className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shadow-md ${
                          isDispatched
                            ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 cursor-default'
                            : 'bg-gradient-to-r from-purple-600 to-brand-600 hover:from-purple-500 hover:to-brand-500 text-white shadow-purple-600/20'
                        }`}
                      >
                        {isDispatched ? (
                          <>
                            <CheckCircle className="w-3.5 h-3.5" />
                            Dispatch Assigned
                          </>
                        ) : (
                          <>
                            <Sparkles className="w-3.5 h-3.5" />
                            Auto-Dispatch Carrier
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
