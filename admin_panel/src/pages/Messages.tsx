import React, { useEffect, useState } from 'react';
import { MessageSquare, Search, User, Clock, ShieldCheck, RefreshCw } from 'lucide-react';
import { subscribeChats, fetchChatMessages } from '../services/firestoreService';
import { ChatThread, ChatMessage } from '../types/models';
import { Badge } from '../components/common/Badge';

export const Messages: React.FC = () => {
  const [threads, setThreads] = useState<ChatThread[]>([]);
  const [selectedThread, setSelectedThread] = useState<ChatThread | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loadingThreads, setLoadingThreads] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const unsub = subscribeChats((data) => {
      setThreads(data);
      setLoadingThreads(false);
      if (data.length > 0 && !selectedThread) {
        handleSelectThread(data[0]);
      }
    });
    return () => unsub();
  }, []);

  const handleSelectThread = async (thread: ChatThread) => {
    setSelectedThread(thread);
    setLoadingMessages(true);
    try {
      const msgs = await fetchChatMessages(thread.id);
      setMessages(msgs);
    } catch (err) {
      console.error('Failed to load messages for thread:', err);
    } finally {
      setLoadingMessages(false);
    }
  };

  const filteredThreads = threads.filter((t) => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return (
      t.id.toLowerCase().includes(term) ||
      (t.lastMessage && t.lastMessage.toLowerCase().includes(term))
    );
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <MessageSquare className="w-6 h-6 text-sky-400" />
            <h2 className="text-2xl font-black text-white">Live Communications Oversight</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Audit in-app messaging threads between shippers, freight brokers, and drivers for safety and compliance.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
          <span>Compliance Monitoring: <strong className="text-emerald-400">Active</strong></span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[650px]">
        {/* Left: Chat Threads List */}
        <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-4 backdrop-blur-xl flex flex-col h-full overflow-hidden">
          <div className="relative mb-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search chat channels..."
              className="w-full pl-9 pr-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-brand-500"
            />
          </div>

          <div className="flex-1 overflow-y-auto space-y-1.5">
            {loadingThreads ? (
              <div className="py-12 text-center text-xs text-slate-400">Loading chat threads...</div>
            ) : filteredThreads.length === 0 ? (
              <div className="py-12 text-center text-xs text-slate-500">
                <MessageSquare className="w-8 h-8 mx-auto mb-2 text-slate-700" />
                No chat conversations found in Firestore 'chats'
              </div>
            ) : (
              filteredThreads.map((thread) => (
                <div
                  key={thread.id}
                  onClick={() => handleSelectThread(thread)}
                  className={`p-3 rounded-xl border transition-all cursor-pointer ${
                    selectedThread?.id === thread.id
                      ? 'bg-sky-500/15 border-sky-500/40'
                      : 'bg-slate-950/50 border-slate-800/80 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-bold text-white">
                      Chat #{thread.id.substring(0, 8)}
                    </span>
                    <span className="text-[10px] text-slate-500">
                      {thread.participants?.length || 2} Participants
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 truncate mt-1">
                    {thread.lastMessage || 'Conversation thread active'}
                  </p>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right: Message Stream Viewer */}
        <div className="lg:col-span-2 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl flex flex-col h-full overflow-hidden">
          {selectedThread ? (
            <>
              <div className="p-4 border-b border-slate-800 bg-slate-950/40 flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-white text-sm">
                    Conversation Inspection: <span className="font-mono text-sky-400">{selectedThread.id}</span>
                  </h4>
                  <p className="text-[11px] text-slate-400">
                    Participants: {selectedThread.participants?.join(', ') || 'Direct Channel'}
                  </p>
                </div>
                <Badge variant="info" size="sm">Audited Stream</Badge>
              </div>

              <div className="flex-1 overflow-y-auto p-4 space-y-3">
                {loadingMessages ? (
                  <div className="py-16 text-center text-xs text-slate-400">Loading messages from Firestore...</div>
                ) : messages.length === 0 ? (
                  <div className="py-16 text-center text-xs text-slate-500">
                    No individual messages recorded in this thread.
                  </div>
                ) : (
                  messages.map((msg, idx) => (
                    <div
                      key={msg.id || idx}
                      className="p-3.5 rounded-xl bg-slate-950/70 border border-slate-800/80 max-w-lg space-y-1"
                    >
                      <div className="flex items-center justify-between text-[10px]">
                        <span className="font-semibold text-sky-400 font-mono">
                          Sender: {msg.senderId ? `${msg.senderId.substring(0, 10)}...` : 'User'}
                        </span>
                        <span className="text-slate-500">
                          {msg.timestamp ? 'Delivered' : 'Live'}
                        </span>
                      </div>
                      <p className="text-xs text-slate-200">{msg.text || (msg as any).message || '—'}</p>
                    </div>
                  ))
                )}
              </div>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-500 text-xs">
              <MessageSquare className="w-10 h-10 mb-2 text-slate-700" />
              Select a conversation thread on the left to inspect logs
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
