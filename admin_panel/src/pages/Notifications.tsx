import React, { useEffect, useState } from 'react';
import { Bell, Send, CheckCircle2, Users, Briefcase, Truck, Shield } from 'lucide-react';
import {
  sendBroadcastNotification,
  subscribeNotifications
} from '../services/firestoreService';
import { SystemNotification } from '../types/models';
import { useAuth } from '../context/AuthContext';
import { Badge } from '../components/common/Badge';

export const Notifications: React.FC = () => {
  const [notifications, setNotifications] = useState<SystemNotification[]>([]);
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [targetAudience, setTargetAudience] = useState<'all' | 'users' | 'brokers' | 'drivers'>('all');
  const [sending, setSending] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    const unsub = subscribeNotifications((data) => {
      setNotifications(data);
    });
    return () => unsub();
  }, []);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) return;

    setSending(true);
    setSuccessMsg(null);
    try {
      await sendBroadcastNotification(title, message, targetAudience, adminEmail);
      setTitle('');
      setMessage('');
      setSuccessMsg('Broadcast alert dispatched successfully & FCM push notification sent to active mobile devices.');
      setTimeout(() => setSuccessMsg(null), 5000);
    } catch (err) {
      console.error('Failed to send notification:', err);
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Broadcast Alerts & Announcements</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Publish system advisories, corridor updates, weather notifications, and platform announcements.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Left: Compose Broadcast */}
        <div className="rounded-lg bg-white border border-slate-200 p-4 shadow-2xs">
          <h3 className="text-sm font-bold text-slate-900 mb-3.5 flex items-center gap-1.5 pb-2.5 border-b border-slate-100">
            <Send className="w-4 h-4 text-sky-700" />
            Compose System Alert
          </h3>

          {successMsg && (
            <div className="mb-3.5 p-3 rounded-md bg-emerald-50 border border-emerald-200 flex items-center gap-2 text-xs text-emerald-800">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}

          <form onSubmit={handleSend} className="space-y-3.5">
            <div>
              <label className="block text-[11px] font-semibold text-slate-700 uppercase tracking-wider mb-1">
                Target Recipient Group
              </label>
              <select
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value as any)}
                className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-md text-xs text-slate-900 focus:outline-none focus:border-sky-600"
              >
                <option value="all">Entire Ecosystem (All Users, Brokers & Drivers)</option>
                <option value="users">Users Only</option>
                <option value="brokers">Brokers Only</option>
                <option value="drivers">Drivers Only</option>
              </select>
            </div>

            <div>
              <label className="block text-[11px] font-semibold text-slate-700 uppercase tracking-wider mb-1">
                Alert Title / Headline
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. M-2 Motorway Fog Advisory / Rate Card Update"
                required
                className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-md text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-sky-600"
              />
            </div>

            <div>
              <label className="block text-[11px] font-semibold text-slate-700 uppercase tracking-wider mb-1">
                Message Content
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                placeholder="Type the full announcement message here..."
                required
                className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-sky-600"
              />
            </div>

            <button
              type="submit"
              disabled={sending}
              className="w-full py-2 bg-sky-700 hover:bg-sky-800 text-white text-xs font-semibold rounded-md shadow-2xs flex items-center justify-center gap-1.5 transition-colors disabled:opacity-50"
            >
              {sending ? 'Dispatching Alert...' : 'Publish System Broadcast'}
            </button>
          </form>
        </div>

        {/* Right: Broadcast History */}
        <div className="lg:col-span-2 rounded-lg bg-white border border-slate-200 p-4 shadow-2xs flex flex-col">
          <div className="flex items-center justify-between mb-3.5 pb-2.5 border-b border-slate-100">
            <h3 className="text-sm font-bold text-slate-900">Broadcast History Log</h3>
            <span className="text-xs text-slate-500">{notifications.length} Sent Broadcasts</span>
          </div>

          <div className="flex-1 overflow-y-auto space-y-2.5">
            {notifications.length === 0 ? (
              <div className="py-16 text-center text-slate-500 text-xs">
                <Bell className="w-6 h-6 mx-auto mb-2 text-slate-400" />
                No broadcast notifications dispatched yet.
              </div>
            ) : (
              notifications.map((n) => (
                <div
                  key={n.id}
                  className="p-3.5 rounded-md bg-slate-50 border border-slate-200 space-y-1.5 hover:bg-slate-100/60 transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <h4 className="font-bold text-slate-900 text-xs">{n.title}</h4>
                      <Badge
                        variant={
                          n.targetAudience === 'all'
                            ? 'info'
                            : n.targetAudience === 'drivers'
                            ? 'success'
                            : n.targetAudience === 'brokers'
                            ? 'purple'
                            : 'warning'
                        }
                        size="sm"
                      >
                        {n.targetAudience}
                      </Badge>
                    </div>
                    <span className="text-[11px] text-slate-500">
                      Sent by: <strong className="text-slate-700 font-medium">{n.sentBy}</strong>
                    </span>
                  </div>

                  <p className="text-xs text-slate-700">{n.message}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
