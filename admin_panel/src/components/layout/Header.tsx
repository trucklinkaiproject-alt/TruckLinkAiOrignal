import React from 'react';
import { Menu, Clock } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface HeaderProps {
  onToggleSidebar: () => void;
  title?: string;
}

export const Header: React.FC<HeaderProps> = ({ onToggleSidebar, title }) => {
  const { adminProfile } = useAuth();
  const currentTime = new Date().toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });

  return (
    <header className="sticky top-0 z-30 h-16 bg-slate-900/80 backdrop-blur-xl border-b border-slate-800 px-4 sm:px-6 lg:px-8 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <button
          onClick={onToggleSidebar}
          className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 lg:hidden border border-slate-700"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div>
          <h1 className="text-lg font-bold text-white tracking-tight">
            {title || 'Operations Command'}
          </h1>
          <p className="text-xs text-slate-400 hidden sm:block">
            Connected to Firebase Cluster (<span className="text-sky-400 font-mono">trucklink-ai-orignal</span>)
          </p>
        </div>
      </div>

      <div className="flex items-center gap-3 sm:gap-4">
        {/* Real-time Status Badge */}
        <div className="hidden sm:inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
          <span>Live Firestore Sync</span>
        </div>

        {/* Date Display */}
        <div className="hidden md:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-slate-300 text-xs font-medium">
          <Clock className="w-3.5 h-3.5 text-slate-400" />
          <span>{currentTime}</span>
        </div>
      </div>
    </header>
  );
};
