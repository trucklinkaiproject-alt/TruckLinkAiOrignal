import React, { useEffect, useState, useRef } from 'react';
import {
  MessageSquare,
  Search,
  User,
  Truck,
  Briefcase,
  Clock,
  ShieldCheck,
  ArrowRight,
  CheckCircle2
} from 'lucide-react';
import {
  subscribeChats,
  subscribeChatMessages,
  subscribeUsers,
  subscribeBrokers,
  subscribeDrivers
} from '../services/firestoreService';
import {
  ChatThread,
  ChatMessage,
  UserProfile,
  BrokerProfile,
  DriverProfile
} from '../types/models';
import { Badge } from '../components/common/Badge';

type CategoryType = 'all' | 'user-broker' | 'broker-driver' | 'user-driver';

interface ResolvedParticipant {
  uid: string;
  name: string;
  role: 'User' | 'Broker' | 'Driver';
  details?: string;
}

interface EnrichedChatThread extends ChatThread {
  participantA?: ResolvedParticipant;
  participantB?: ResolvedParticipant;
  category: 'user-broker' | 'broker-driver' | 'user-driver' | 'other';
  displayTitle: string;
}

export const Messages: React.FC = () => {
  const [rawThreads, setRawThreads] = useState<ChatThread[]>([]);
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);

  const [selectedThread, setSelectedThread] = useState<EnrichedChatThread | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loadingThreads, setLoadingThreads] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);

  const [activeCategory, setActiveCategory] = useState<CategoryType>('all');
  const [searchTerm, setSearchTerm] = useState('');

  const messagesEndRef = useRef<HTMLDivElement>(null);

  // 1. Subscribe to core entities
  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubU = subscribeUsers((data) => setUsers(data));
    const unsubB = subscribeBrokers((data) => setBrokers(data));
    const unsubD = subscribeDrivers((data) => setDrivers(data));
    const unsubC = subscribeChats((data) => {
      setRawThreads(data);
      setLoadingThreads(false);
    });

    unsubs = [unsubU, unsubB, unsubD, unsubC];
    return () => unsubs.forEach((fn) => fn());
  }, []);

  // 2. Resolve participant profiles
  const usersMap = React.useMemo(() => {
    const map: Record<string, UserProfile> = {};
    users.forEach((u) => (map[u.id] = u));
    return map;
  }, [users]);

  const brokersMap = React.useMemo(() => {
    const map: Record<string, BrokerProfile> = {};
    brokers.forEach((b) => (map[b.id] = b));
    return map;
  }, [brokers]);

  const driversMap = React.useMemo(() => {
    const map: Record<string, DriverProfile> = {};
    drivers.forEach((d) => (map[d.id] = d));
    return map;
  }, [drivers]);

  const resolveParticipant = (uid: string, fallbackRole?: string): ResolvedParticipant => {
    if (brokersMap[uid]) {
      return {
        uid,
        name: brokersMap[uid].companyName || brokersMap[uid].name || 'Broker Partner',
        role: 'Broker',
        details: brokersMap[uid].companyName || brokersMap[uid].phone,
      };
    }
    if (driversMap[uid]) {
      return {
        uid,
        name: driversMap[uid].name || 'Driver Partner',
        role: 'Driver',
        details: driversMap[uid].vehicleNumber || driversMap[uid].phone,
      };
    }
    if (usersMap[uid]) {
      return {
        uid,
        name: usersMap[uid].name || 'User (Customer)',
        role: 'User',
        details: usersMap[uid].phone || usersMap[uid].email,
      };
    }

    // Role heuristics from fallback role string
    const r = (fallbackRole || '').toLowerCase();
    if (r.includes('broker')) {
      return { uid, name: `Broker (${uid.substring(0, 6)})`, role: 'Broker' };
    }
    if (r.includes('driver')) {
      return { uid, name: `Driver (${uid.substring(0, 6)})`, role: 'Driver' };
    }
    return { uid, name: `User (${uid.substring(0, 6)})`, role: 'User' };
  };

  // 3. Enrich and categorize threads
  const enrichedThreads: EnrichedChatThread[] = React.useMemo(() => {
    return rawThreads.map((thread) => {
      let p1Uid = '';
      let p2Uid = '';

      if (Array.isArray(thread.participants) && thread.participants.length >= 2) {
        p1Uid = thread.participants[0];
        p2Uid = thread.participants[1];
      } else if (Array.isArray(thread.participants) && thread.participants.length === 1) {
        p1Uid = thread.participants[0];
      } else {
        // Parse deterministic ID e.g. chat_user123_broker456
        const parts = thread.id.split('_');
        if (parts.length >= 3) {
          p1Uid = parts[1];
          p2Uid = parts[2];
        }
      }

      // Explicit role fallbacks from doc
      const role1 = thread.participantRoles?.[p1Uid] || (thread as any)[`role_${p1Uid}`];
      const role2 = thread.participantRoles?.[p2Uid] || (thread as any)[`role_${p2Uid}`];

      const pA = p1Uid ? resolveParticipant(p1Uid, role1) : undefined;
      const pB = p2Uid ? resolveParticipant(p2Uid, role2) : undefined;

      // Determine category based on roles
      let category: 'user-broker' | 'broker-driver' | 'user-driver' | 'other' = 'other';
      if (pA && pB) {
        const roles = [pA.role, pB.role];
        if (roles.includes('User') && roles.includes('Broker')) {
          category = 'user-broker';
        } else if (roles.includes('Broker') && roles.includes('Driver')) {
          category = 'broker-driver';
        } else if (roles.includes('User') && roles.includes('Driver')) {
          category = 'user-driver';
        }
      } else if (thread.id.includes('broker') && thread.id.includes('driver')) {
        category = 'broker-driver';
      } else if (thread.id.includes('user') && thread.id.includes('broker')) {
        category = 'user-broker';
      } else if (thread.id.includes('user') && thread.id.includes('driver')) {
        category = 'user-driver';
      }

      const title = pA && pB ? `${pA.name} ↔ ${pB.name}` : `Chat #${thread.id.substring(0, 8)}`;

      return {
        ...thread,
        participantA: pA,
        participantB: pB,
        category,
        displayTitle: title,
      };
    });
  }, [rawThreads, usersMap, brokersMap, driversMap]);

  // Select initial thread if none selected or if current thread changed
  useEffect(() => {
    if (enrichedThreads.length > 0 && !selectedThread) {
      setSelectedThread(enrichedThreads[0]);
    }
  }, [enrichedThreads]);

  // 4. Real-time messages subscription for selected thread
  useEffect(() => {
    if (!selectedThread) return;

    setLoadingMessages(true);
    const unsub = subscribeChatMessages(selectedThread.id, (msgs) => {
      setMessages(msgs);
      setLoadingMessages(false);
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    });

    return () => unsub();
  }, [selectedThread?.id]);

  // Category counts
  const countUserBroker = enrichedThreads.filter((t) => t.category === 'user-broker').length;
  const countBrokerDriver = enrichedThreads.filter((t) => t.category === 'broker-driver').length;
  const countUserDriver = enrichedThreads.filter((t) => t.category === 'user-driver').length;

  // Filtered thread list
  const filteredThreads = enrichedThreads.filter((t) => {
    if (activeCategory !== 'all' && t.category !== activeCategory) {
      return false;
    }

    if (searchTerm.trim()) {
      const q = searchTerm.toLowerCase();
      const title = t.displayTitle.toLowerCase();
      const lastMsg = (t.lastMessage || '').toLowerCase();
      const id = t.id.toLowerCase();
      const nameA = (t.participantA?.name || '').toLowerCase();
      const nameB = (t.participantB?.name || '').toLowerCase();
      return (
        title.includes(q) ||
        lastMsg.includes(q) ||
        id.includes(q) ||
        nameA.includes(q) ||
        nameB.includes(q)
      );
    }

    return true;
  });

  const getRoleBadgeVariant = (role?: string) => {
    if (role === 'Broker') return 'purple';
    if (role === 'Driver') return 'info';
    return 'success';
  };

  const formatMsgTime = (timestamp: any) => {
    if (!timestamp) return '';
    if (timestamp.toDate) {
      return timestamp.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    return '';
  };

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-sky-700" />
            <h2 className="text-lg font-bold text-slate-900">Communications Oversight</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Audit of messaging threads between Users, Brokers, and Drivers categorized by operational interaction.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-600 bg-white px-3.5 py-1.5 rounded-md border border-slate-200 shadow-2xs">
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>
            Compliance Monitoring: <strong className="text-emerald-700">Active</strong>
          </span>
        </div>
      </div>

      {/* 3 Interaction Categories Bar */}
      <div className="flex flex-wrap items-center gap-1.5 p-1 bg-white border border-slate-200 rounded-md shadow-2xs">
        <button
          onClick={() => setActiveCategory('all')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-semibold transition-colors ${
            activeCategory === 'all'
              ? 'bg-slate-900 text-white shadow-2xs'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <span>All Channels</span>
          <span className={`px-1.5 py-0.2 rounded text-[10px] ${
            activeCategory === 'all' ? 'bg-slate-800 text-slate-200' : 'bg-slate-100 text-slate-600'
          }`}>
            {enrichedThreads.length}
          </span>
        </button>

        <button
          onClick={() => setActiveCategory('user-broker')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-semibold transition-colors ${
            activeCategory === 'user-broker'
              ? 'bg-slate-900 text-white shadow-2xs'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <User className="w-3.5 h-3.5" />
          <span>User ↔ Broker</span>
          <span className={`px-1.5 py-0.2 rounded text-[10px] ${
            activeCategory === 'user-broker' ? 'bg-slate-800 text-slate-200' : 'bg-slate-100 text-slate-600'
          }`}>
            {countUserBroker}
          </span>
        </button>

        <button
          onClick={() => setActiveCategory('broker-driver')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-semibold transition-colors ${
            activeCategory === 'broker-driver'
              ? 'bg-slate-900 text-white shadow-2xs'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <Briefcase className="w-3.5 h-3.5" />
          <span>Broker ↔ Driver</span>
          <span className={`px-1.5 py-0.2 rounded text-[10px] ${
            activeCategory === 'broker-driver' ? 'bg-slate-800 text-slate-200' : 'bg-slate-100 text-slate-600'
          }`}>
            {countBrokerDriver}
          </span>
        </button>

        <button
          onClick={() => setActiveCategory('user-driver')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-semibold transition-colors ${
            activeCategory === 'user-driver'
              ? 'bg-slate-900 text-white shadow-2xs'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <Truck className="w-3.5 h-3.5" />
          <span>User ↔ Driver</span>
          <span className={`px-1.5 py-0.2 rounded text-[10px] ${
            activeCategory === 'user-driver' ? 'bg-slate-800 text-slate-200' : 'bg-slate-100 text-slate-600'
          }`}>
            {countUserDriver}
          </span>
        </button>
      </div>

      {/* Main Chat Layout: 2 Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 h-[650px]">
        {/* Left Column: Unique Conversation Tiles */}
        <div className="rounded-lg bg-white border border-slate-200 p-3.5 shadow-2xs flex flex-col h-full overflow-hidden">
          <div className="relative mb-2.5">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search conversations, names or text..."
              className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-300 rounded-md text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-sky-600"
            />
          </div>

          <div className="flex-1 overflow-y-auto space-y-2 pr-1">
            {loadingThreads ? (
              <div className="py-16 text-center text-xs text-slate-500">Loading chat threads...</div>
            ) : filteredThreads.length === 0 ? (
              <div className="py-16 text-center text-xs text-slate-500 space-y-1.5">
                <MessageSquare className="w-6 h-6 mx-auto text-slate-400" />
                <p className="font-semibold text-slate-700">No conversations in this category</p>
                <p className="text-[11px] text-slate-500">
                  New messages sent between users, brokers, or drivers will automatically appear here.
                </p>
              </div>
            ) : (
              filteredThreads.map((thread) => {
                const isSelected = selectedThread?.id === thread.id;
                return (
                  <div
                    key={thread.id}
                    onClick={() => setSelectedThread(thread)}
                    className={`p-2.5 rounded-md border transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-sky-50 border-sky-300 shadow-2xs'
                        : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    {/* Participant Names & Roles */}
                    <div className="flex items-start justify-between gap-2">
                      <div className="space-y-0.5 min-w-0">
                        <div className="flex items-center gap-1.5 flex-wrap">
                          <span className="font-bold text-slate-900 text-xs truncate max-w-[120px]">
                            {thread.participantA?.name || 'Participant 1'}
                          </span>
                          <Badge variant={getRoleBadgeVariant(thread.participantA?.role)} size="sm">
                            {thread.participantA?.role || 'User'}
                          </Badge>
                          <span className="text-slate-400 text-[10px]">↔</span>
                          <span className="font-bold text-slate-900 text-xs truncate max-w-[120px]">
                            {thread.participantB?.name || 'Participant 2'}
                          </span>
                          <Badge variant={getRoleBadgeVariant(thread.participantB?.role)} size="sm">
                            {thread.participantB?.role || 'Broker'}
                          </Badge>
                        </div>
                      </div>
                    </div>

                    {/* Last message preview */}
                    <p className="text-xs text-slate-600 truncate mt-1.5">
                      {thread.lastMessage || 'Conversation active'}
                    </p>

                    <div className="flex items-center justify-between mt-2 pt-1.5 border-t border-slate-200 text-[10px] text-slate-500">
                      <span className="font-mono">#{thread.id.substring(0, 8)}</span>
                      {thread.orderId && (
                        <span className="text-slate-600 font-medium">Order #{thread.orderId}</span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Right Column: Real-Time Message Stream Viewer */}
        <div className="lg:col-span-2 rounded-lg bg-white border border-slate-200 shadow-2xs flex flex-col h-full overflow-hidden">
          {selectedThread ? (
            <>
              {/* Active Conversation Header */}
              <div className="p-3.5 border-b border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <h4 className="font-bold text-slate-900 text-xs">
                      {selectedThread.participantA?.name || 'Participant A'}
                    </h4>
                    <Badge variant={getRoleBadgeVariant(selectedThread.participantA?.role)} size="sm">
                      {selectedThread.participantA?.role || 'User'}
                    </Badge>
                    <span className="text-slate-400">↔</span>
                    <h4 className="font-bold text-slate-900 text-xs">
                      {selectedThread.participantB?.name || 'Participant B'}
                    </h4>
                    <Badge variant={getRoleBadgeVariant(selectedThread.participantB?.role)} size="sm">
                      {selectedThread.participantB?.role || 'Broker'}
                    </Badge>
                  </div>
                  <p className="text-[10px] font-mono text-slate-500 mt-0.5">
                    Channel ID: {selectedThread.id}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <Badge variant="neutral" size="sm">
                    Audited Stream
                  </Badge>
                </div>
              </div>

              {/* Message Feed */}
              <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-slate-50/40">
                {loadingMessages ? (
                  <div className="py-20 text-center text-xs text-slate-500">
                    Loading messages from Firestore stream...
                  </div>
                ) : messages.length === 0 ? (
                  <div className="py-20 text-center text-xs text-slate-500">
                    <MessageSquare className="w-6 h-6 mx-auto mb-1.5 text-slate-400" />
                    No individual messages recorded in this conversation yet.
                  </div>
                ) : (
                  messages.map((msg, index) => {
                    const isSenderA =
                      msg.senderId === selectedThread.participantA?.uid ||
                      msg.senderRole === selectedThread.participantA?.role?.toLowerCase();

                    const senderRole = msg.senderRole
                      ? msg.senderRole.toUpperCase()
                      : isSenderA
                      ? selectedThread.participantA?.role
                      : selectedThread.participantB?.role;

                    const senderName =
                      msg.senderName ||
                      (isSenderA
                        ? selectedThread.participantA?.name
                        : selectedThread.participantB?.name) ||
                      'Participant';

                    return (
                      <div
                        key={msg.id || index}
                        className={`flex flex-col ${
                          isSenderA ? 'items-start' : 'items-end'
                        }`}
                      >
                        <div className="flex items-center gap-1.5 mb-1 px-1 text-[11px] text-slate-500">
                          <span className="font-semibold text-slate-800 text-xs">{senderName}</span>
                          <span className="text-[10px] px-1 py-0.2 rounded bg-slate-200 text-slate-700">
                            {senderRole}
                          </span>
                          <span className="text-slate-400 text-[10px]">{formatMsgTime(msg.timestamp)}</span>
                        </div>

                        <div
                          className={`max-w-[75%] p-3 rounded-lg text-xs leading-relaxed ${
                            isSenderA
                              ? 'bg-white text-slate-900 border border-slate-200 shadow-2xs'
                              : 'bg-sky-700 text-white shadow-2xs'
                          }`}
                        >
                          <p>{msg.text || (msg as any).message || ''}</p>
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Bottom Notice: Admin Audit only */}
              <div className="p-2.5 bg-slate-50 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span className="text-[11px]">Read-only compliance audit mode active.</span>
                </div>
                <span className="font-mono text-[10px] text-slate-500">
                  {messages.length} Messages Logged
                </span>
              </div>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-500 p-8 text-center">
              <MessageSquare className="w-10 h-10 mb-2 text-slate-400" />
              <p className="text-xs font-semibold text-slate-800">Select a Conversation</p>
              <p className="text-[11px] text-slate-500 mt-0.5 max-w-sm">
                Choose any conversation from the participant list on the left to inspect the real-time audited dialogue.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
