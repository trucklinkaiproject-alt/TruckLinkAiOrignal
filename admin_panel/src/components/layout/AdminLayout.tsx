import React, { useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export const AdminLayout: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  const getPageTitle = (pathname: string) => {
    switch (pathname) {
      case '/dashboard':
        return 'System Overview & Real-time Metrics';
      case '/users':
        return 'Users Management';
      case '/brokers':
        return 'Brokers Management';
      case '/drivers':
        return 'Fleet Drivers Registry';
      case '/vehicles':
        return 'Trucks, Fleets & Capacities';
      case '/requests':
      case '/orders':
        return 'Requests & Orders Dossier';
      case '/tracking':
        return 'Live GPS & Fleet Telematics Map';
      case '/ratings':
        return 'Ratings, Feedback & Trust Score';
      case '/notifications':
        return 'Broadcast Alerts & Notifications';
      case '/messages':
        return 'Live Communications Oversight';
      case '/analytics':
        return 'Logistics Analytics & Revenue';
      case '/audit-logs':
        return 'Security & Administrative Audit Logs';
      case '/settings':
        return 'Platform Settings & Admin Accounts';
      default:
        return 'Operations Command';
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col lg:flex-row">
      {/* Navigation Sidebar */}
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 lg:pl-72">
        <Header
          onToggleSidebar={() => setSidebarOpen(!sidebarOpen)}
          title={getPageTitle(location.pathname)}
        />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
