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
          className="fixed inset-0 z-40 bg-slate-900/60 backdrop-blur-xs lg:hidden"
        />
      )}

      <aside
        className={`fixed top-0 left-0 bottom-0 z-50 w-64 bg-slate-900 border-r border-slate-800 flex flex-col transition-transform duration-200 ease-in-out lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="h-16 px-5 border-b border-slate-800 flex items-center justify-between bg-slate-950">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-md bg-sky-700 flex items-center justify-center text-white">
              <Truck className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-white text-sm tracking-tight">TruckLink AI</span>
              </div>
              <span className="text-[10px] text-slate-400 font-medium tracking-wide uppercase">
                Admin Console
              </span>
            </div>
          </div>
        </div>

        {/* Navigation List */}
        <div className="flex-1 overflow-y-auto px-3 py-4 space-y-5">
          {navItems.map((group) => (
            <div key={group.category} className="space-y-1">
              <p className="px-3 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
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
                        `flex items-center justify-between px-3 py-2 rounded-md text-xs sm:text-sm font-medium transition-colors ${
                          isActive
                            ? 'bg-slate-800 text-white font-semibold'
                            : 'text-slate-300 hover:text-white hover:bg-slate-800/60'
                        }`
                      }
                    >
                      <div className="flex items-center gap-2.5">
                        <Icon className="w-4 h-4 text-slate-400" />
                        <span>{link.name}</span>
                      </div>
                    </NavLink>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* User Info / Logout Footer */}
        <div className="p-3 border-t border-slate-800 bg-slate-950">
          <div className="flex items-center justify-between p-2 rounded-md bg-slate-900 border border-slate-800 mb-2">
            <div className="flex items-center gap-2 overflow-hidden">
              <div className="w-7 h-7 rounded bg-slate-800 text-slate-300 flex items-center justify-center font-bold text-xs shrink-0">
                <Shield className="w-3.5 h-3.5 text-sky-400" />
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
            <span className="text-[10px] font-medium bg-slate-800 text-slate-300 px-1.5 py-0.5 rounded border border-slate-700">
              {adminProfile?.role || 'Admin'}
            </span>
          </div>

          <button
            onClick={() => logout()}
            className="w-full flex items-center justify-center gap-2 px-3 py-1.5 text-xs font-medium text-slate-300 hover:text-rose-400 hover:bg-slate-800/80 rounded-md border border-slate-800 transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
};
