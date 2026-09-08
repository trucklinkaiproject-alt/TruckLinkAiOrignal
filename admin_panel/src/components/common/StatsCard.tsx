import React from 'react';
import { LucideIcon } from 'lucide-react';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  change?: string;
  changeType?: 'positive' | 'negative' | 'neutral';
  color?: 'blue' | 'emerald' | 'amber' | 'purple' | 'rose' | 'cyan';
  subtitle?: string;
}

export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  icon: Icon,
  change,
  changeType = 'positive',
  color = 'blue',
  subtitle,
}) => {
  const colorMap = {
    blue: 'from-blue-500/20 to-sky-500/10 text-sky-400 border-sky-500/30',
    emerald: 'from-emerald-500/20 to-teal-500/10 text-emerald-400 border-emerald-500/30',
    amber: 'from-amber-500/20 to-orange-500/10 text-amber-400 border-amber-500/30',
    purple: 'from-purple-500/20 to-indigo-500/10 text-purple-400 border-purple-500/30',
    rose: 'from-rose-500/20 to-pink-500/10 text-rose-400 border-rose-500/30',
    cyan: 'from-cyan-500/20 to-blue-500/10 text-cyan-400 border-cyan-500/30',
  };

  const iconBgMap = {
    blue: 'bg-sky-500/15 text-sky-400 border-sky-500/30',
    emerald: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
    amber: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
    purple: 'bg-purple-500/15 text-purple-400 border-purple-500/30',
    rose: 'bg-rose-500/15 text-rose-400 border-rose-500/30',
    cyan: 'bg-cyan-500/15 text-cyan-400 border-cyan-500/30',
  };

  return (
    <div className={`relative overflow-hidden rounded-2xl bg-gradient-to-br ${colorMap[color]} bg-slate-900/80 p-6 border backdrop-blur-xl shadow-lg transition-all duration-300 hover:scale-[1.02] hover:shadow-xl`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-slate-400">{title}</p>
          <h3 className="mt-2 text-3xl font-bold tracking-tight text-white">{value}</h3>
          {subtitle && (
            <p className="mt-1 text-xs text-slate-400">{subtitle}</p>
          )}
          {change && (
            <div className="mt-3 flex items-center gap-1.5 text-xs">
              <span
                className={`font-semibold ${
                  changeType === 'positive'
                    ? 'text-emerald-400'
                    : changeType === 'negative'
                    ? 'text-rose-400'
                    : 'text-slate-400'
                }`}
              >
                {change}
              </span>
              <span className="text-slate-500">vs last month</span>
            </div>
          )}
        </div>
        <div className={`p-3 rounded-xl border ${iconBgMap[color]}`}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
      <div className="absolute -right-6 -bottom-6 w-24 h-24 bg-white/5 rounded-full blur-2xl pointer-events-none" />
    </div>
  );
};
