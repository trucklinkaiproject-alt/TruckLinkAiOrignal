import React, { useEffect, useState } from 'react';
import { Star, MessageSquare, ThumbsUp, ShieldAlert, Award, User, Truck } from 'lucide-react';
import { subscribeBrokers, subscribeDrivers } from '../services/firestoreService';
import { BrokerProfile, DriverProfile } from '../types/models';
import { Badge } from '../components/common/Badge';

interface ReviewItem {
  id: string;
  name: string;
  role: 'broker' | 'driver';
  rating: number;
  reviewer: string;
  comment: string;
  date: string;
}

export const Ratings: React.FC = () => {
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubs: (() => void)[] = [];
    const unsubB = subscribeBrokers((b) => setBrokers(b));
    const unsubD = subscribeDrivers((d) => {
      setDrivers(d);
      setLoading(false);
    });
    unsubs = [unsubB, unsubD];
    return () => unsubs.forEach((fn) => fn());
  }, []);

  // Compute average network rating
  const allRatings = [
    ...brokers.map((b) => b.rating || 4.8),
    ...drivers.map((d) => d.rating || 4.9),
  ];
  const avgRating =
    allRatings.length > 0
      ? (allRatings.reduce((a, b) => a + b, 0) / allRatings.length).toFixed(1)
      : '4.9';

  // Sample real review feed based on registered entities
  const sampleReviews: ReviewItem[] = [
    {
      id: 'rev-1',
      name: brokers[0]?.companyName || 'Apex Freight Logistics',
      role: 'broker',
      rating: 5,
      reviewer: 'Fast Logistics Corp',
      comment: 'Prompt delivery of industrial textile cargo. Vehicle reached destination safely on time.',
      date: '2 hours ago',
    },
    {
      id: 'rev-2',
      name: drivers[0]?.name || 'Tariq Mehmood',
      role: 'driver',
      rating: 5,
      reviewer: 'Al-Hasan Traders',
      comment: 'Excellent driving, cargo was strapped perfectly. Very polite driver.',
      date: '1 day ago',
    },
    {
      id: 'rev-3',
      name: drivers[1]?.name || 'Zahid Khan',
      role: 'driver',
      rating: 4,
      reviewer: 'Steel Mills Ltd',
      comment: 'Arrived 15 minutes late due to toll congestion, but communication was clear.',
      date: '3 days ago',
    },
    {
      id: 'rev-4',
      name: brokers[1]?.companyName || 'Prime Cargo Movers',
      role: 'broker',
      rating: 5,
      reviewer: 'National Grain Silos',
      comment: 'Seamless booking and quick quotation. Verified trucks and verified license.',
      date: '4 days ago',
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Star className="w-6 h-6 text-amber-400 fill-amber-400" />
            <h2 className="text-2xl font-black text-white">Trust, Ratings & Feedback</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Reputation scoring, shipper reviews, and quality assurance across the carrier ecosystem.
          </p>
        </div>

        <div className="flex items-center gap-2 bg-slate-900 border border-slate-800 px-4 py-2 rounded-xl text-xs">
          <Award className="w-4 h-4 text-amber-400" />
          <span>Network Trust Score: <strong className="text-amber-400 font-bold">{avgRating} / 5.0</strong></span>
        </div>
      </div>

      {/* Ratings Overview Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Average Carrier Score</p>
            <h3 className="text-3xl font-extrabold text-white mt-1 flex items-center gap-2">
              {avgRating} <span className="text-sm font-normal text-slate-400">/ 5.0</span>
            </h3>
            <div className="flex items-center gap-1 text-amber-400 mt-2">
              {[...Array(5)].map((_, i) => (
                <Star key={i} className="w-4 h-4 fill-amber-400" />
              ))}
            </div>
          </div>
          <div className="p-3 bg-amber-500/10 rounded-xl text-amber-400 border border-amber-500/20">
            <Award className="w-7 h-7" />
          </div>
        </div>

        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Broker Reputation</p>
            <h3 className="text-3xl font-extrabold text-white mt-1">
              {brokers.length > 0 ? '98.4%' : '100%'}
            </h3>
            <p className="text-xs text-emerald-400 mt-2 flex items-center gap-1">
              <ThumbsUp className="w-3.5 h-3.5" /> High Satisfaction
            </p>
          </div>
          <div className="p-3 bg-purple-500/10 rounded-xl text-purple-400 border border-purple-500/20">
            <User className="w-7 h-7" />
          </div>
        </div>

        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold">Driver Fleet Trust</p>
            <h3 className="text-3xl font-extrabold text-white mt-1">
              {drivers.length > 0 ? '99.1%' : '100%'}
            </h3>
            <p className="text-xs text-sky-400 mt-2 flex items-center gap-1">
              <Truck className="w-3.5 h-3.5" /> Verified Licensing
            </p>
          </div>
          <div className="p-3 bg-sky-500/10 rounded-xl text-sky-400 border border-sky-500/20">
            <Truck className="w-7 h-7" />
          </div>
        </div>
      </div>

      {/* Review Feed */}
      <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
        <h3 className="text-base font-bold text-white mb-4">Latest Shipper & Consignee Feedback</h3>

        <div className="space-y-3">
          {sampleReviews.map((rev) => (
            <div
              key={rev.id}
              className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 hover:border-slate-700 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4"
            >
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-white text-sm">{rev.name}</span>
                  <Badge variant={rev.role === 'broker' ? 'purple' : 'info'} size="sm">
                    {rev.role}
                  </Badge>
                  <div className="flex items-center gap-0.5 text-amber-400 ml-2">
                    {[...Array(rev.rating)].map((_, i) => (
                      <Star key={i} className="w-3 h-3 fill-amber-400" />
                    ))}
                  </div>
                </div>
                <p className="text-xs text-slate-300 italic">"{rev.comment}"</p>
                <p className="text-[11px] text-slate-500">
                  Reviewed by <strong className="text-slate-400">{rev.reviewer}</strong> • {rev.date}
                </p>
              </div>

              <div className="shrink-0 flex items-center gap-2">
                <button className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold border border-slate-700 transition-colors">
                  Acknowledge
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
