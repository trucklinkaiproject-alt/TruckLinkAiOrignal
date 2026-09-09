import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Briefcase,
  Truck,
  CarFront,
  FileText,
  MapPin,
  Star,
  Bell,
  MessageSquare,
  BarChart3,
  ShieldCheck,
  Settings,
  LogOut,
  ChevronRight,
  Shield
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface SidebarProps {
  isOpen: boolean;
  onClose?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const { adminProfile, logout } = useAuth();

  const navItems = [
    {
      category: 'MAIN',
      links: [
        { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Live Tracking', path: '/tracking', icon: MapPin },
      ],
    },
    {
      category: 'STAKEHOLDERS',
      links: [
        { name: 'Users', path: '/users', icon: Users },
        { name: 'Brokers', path: '/brokers', icon: Briefcase },
        { name: 'Drivers', path: '/drivers', icon: Truck },
        { name: 'Vehicles & Fleet', path: '/vehicles', icon: CarFront },
      ],
    },
    {
      category: 'LOGISTICS & OPS',
      links: [
        { name: 'Requests & Orders', path: '/requests', icon: FileText },
        { name: 'Ratings & Reviews', path: '/ratings', icon: Star },
        { name: 'Message Oversight', path: '/messages', icon: MessageSquare },
      ],
    },
    {
      category: 'ADMINISTRATION',
      links: [
        { name: 'Broadcast Alerts', path: '/notifications', icon: Bell },
        { name: 'Analytics & Insights', path: '/analytics', icon: BarChart3 },
        { name: 'Audit Logs', path: '/audit-logs', icon: ShieldCheck },
        { name: 'Admin Settings', path: '/settings', icon: Settings },
      ],
    },
  ];

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          onClick={onClose}
          className="fixed inset-0 z-40 bg-slate-950/80 backdrop-blur-sm lg:hidden"
        />
      )}

      <aside
        className={`fixed top-0 left-0 bottom-0 z-50 w-72 bg-slate-900/95 border-r border-slate-800 backdrop-blur-xl flex flex-col transition-transform duration-300 ease-in-out lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="h-16 px-6 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-brand-600 to-sky-400 p-0.5 flex items-center justify-center shadow-lg shadow-sky-500/20">
              <div className="w-full h-full bg-slate-950 rounded-[10px] flex items-center justify-center">
                <Truck className="w-5 h-5 text-sky-400" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-extrabold text-white text-base tracking-tight">TruckLink</span>
                <span className="px-1.5 py-0.2 bg-gradient-to-r from-brand-500 to-cyan-400 text-slate-950 font-black text-[10px] rounded uppercase tracking-wider">
                  AI
                </span>
              </div>
              <span className="text-[10px] text-slate-400 font-medium tracking-wide uppercase">
                Admin Control Center
              </span>
            </div>
          </div>
        </div>

        {/* Navigation List */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-6">
          {navItems.map((group) => (
            <div key={group.category} className="space-y-1">
              <p className="px-3 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                {group.category}
              </p>
              <div className="mt-1 space-y-0.5">
                {group.links.map((link) => {
                  const Icon = link.icon;
                  return (
                    <NavLink
                      key={link.path}
                      to={link.path}
                      onClick={() => onClose && onClose()}
                      className={({ isActive }) =>
                        `flex items-center justify-between px-3 py-2 rounded-xl text-sm font-medium transition-all group ${
                          isActive
                            ? 'bg-gradient-to-r from-brand-500/20 to-sky-500/10 text-sky-300 border border-sky-500/30 shadow-sm'
                            : 'text-slate-300 hover:text-white hover:bg-slate-800/60'
                        }`
                      }
                    >
                      <div className="flex items-center gap-3">
                        <Icon className="w-4 h-4 text-slate-400 group-hover:text-sky-400 transition-colors" />
                        <span>{link.name}</span>
                      </div>
                      <ChevronRight className="w-3.5 h-3.5 opacity-0 group-hover:opacity-100 transition-opacity text-slate-400" />
                    </NavLink>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* User Info / Logout Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/40">
          <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-800/50 border border-slate-700/50 mb-2">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="w-8 h-8 rounded-lg bg-sky-500/20 text-sky-400 flex items-center justify-center font-bold text-xs border border-sky-500/30 shrink-0">
                <Shield className="w-4 h-4" />
              </div>
              <div className="overflow-hidden text-left">
                <p className="text-xs font-semibold text-white truncate">
                  {adminProfile?.displayName || 'System Admin'}
                </p>
                <p className="text-[10px] text-slate-400 truncate">
                  {adminProfile?.email || 'admin@trucklink.ai'}
                </p>
              </div>
            </div>
            <span className="text-[10px] font-semibold bg-emerald-500/20 text-emerald-400 px-1.5 py-0.5 rounded border border-emerald-500/30">
              {adminProfile?.role || 'Admin'}
            </span>
          </div>

          <button
            onClick={() => logout()}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 text-xs font-semibold text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 rounded-xl border border-rose-500/20 transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
};
