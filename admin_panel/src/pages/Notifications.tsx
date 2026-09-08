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
      setSuccessMsg('Broadcast alert dispatched successfully to target audience.');
      setTimeout(() => setSuccessMsg(null), 4000);
    } catch (err) {
      console.error('Failed to send notification:', err);
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Bell className="w-6 h-6 text-amber-400" />
            <h2 className="text-2xl font-black text-white">Broadcast Alerts & Announcements</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Publish real-time system alerts, weather advisories, highway closures, and platform updates.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: Compose Broadcast */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
          <h3 className="text-base font-bold text-white mb-4 flex items-center gap-2">
            <Send className="w-4 h-4 text-sky-400" />
            Compose System Alert
          </h3>

          {successMsg && (
            <div className="mb-4 p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center gap-2 text-xs text-emerald-300">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}

          <form onSubmit={handleSend} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5">
                Target Recipient Group
              </label>
              <select
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value as any)}
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700/80 rounded-xl text-xs text-white focus:outline-none focus:border-brand-500"
              >
                <option value="all">Entire Ecosystem (All Shippers, Brokers & Drivers)</option>
                <option value="users">Shippers Only</option>
                <option value="brokers">Freight Brokers Only</option>
                <option value="drivers">Fleet Drivers Only</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5">
                Alert Title / Headline
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. M-2 Motorway Fog Advisory / Rate Card Update"
                required
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700/80 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-brand-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5">
                Message Content
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                placeholder="Type the full announcement message here..."
                required
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700/80 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-brand-500"
              />
            </div>

            <button
              type="submit"
              disabled={sending}
              className="w-full py-3 bg-gradient-to-r from-brand-600 to-sky-500 hover:from-brand-500 hover:to-sky-400 text-white text-xs font-bold rounded-xl shadow-lg shadow-sky-600/20 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
            >
              {sending ? 'Dispatching Alert...' : 'Publish System Broadcast'}
            </button>
          </form>
        </div>

        {/* Right: Broadcast History */}
        <div className="lg:col-span-2 rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-bold text-white">Broadcast History Log</h3>
            <span className="text-xs text-slate-400">{notifications.length} Sent Broadcasts</span>
          </div>

          <div className="flex-1 overflow-y-auto space-y-3">
            {notifications.length === 0 ? (
              <div className="py-16 text-center text-slate-500 text-xs">
                <Bell className="w-8 h-8 mx-auto mb-2 text-slate-700" />
                No broadcast notifications dispatched yet.
              </div>
            ) : (
              notifications.map((n) => (
                <div
                  key={n.id}
                  className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 space-y-2 hover:border-slate-700 transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <h4 className="font-bold text-white text-sm">{n.title}</h4>
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
                    <span className="text-[11px] text-slate-400">
                      Sent by: <strong className="text-slate-300">{n.sentBy}</strong>
                    </span>
                  </div>

                  <p className="text-xs text-slate-300">{n.message}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
