import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { Badge } from '../components/common/Badge';
import { subscribeAuditLogs } from '../services/firestoreService';
import { AuditLog } from '../types/models';
import { ShieldCheck, Clock, User, FileCode, Shield } from 'lucide-react';

export const AuditLogs: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = subscribeAuditLogs((data) => {
      setLogs(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const formatTimestamp = (ts: any) => {
    if (!ts) return 'Just now';
    if (ts.toDate) {
      return ts.toDate().toLocaleString();
    }
    if (ts.seconds) {
      return new Date(ts.seconds * 1000).toLocaleString();
    }
    return String(ts);
  };

  const columns: Column<AuditLog>[] = [
    {
      key: 'action',
      header: 'Administrative Action',
      sortable: true,
      render: (l) => (
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-sky-400 font-mono text-xs">
            <Shield className="w-4 h-4" />
          </div>
          <div>
            <p className="font-mono font-bold text-white text-xs">{l.action}</p>
            <p className="text-[11px] text-slate-400">
              Target: <span className="text-sky-400">{l.targetCollection}</span> / {l.targetId?.substring(0, 10)}...
            </p>
          </div>
        </div>
      ),
    },
    {
      key: 'adminEmail',
      header: 'Admin Actor',
      sortable: true,
      render: (l) => (
        <div className="flex items-center gap-1.5 text-xs text-slate-300">
          <User className="w-3.5 h-3.5 text-slate-500" />
          <span>{l.adminEmail}</span>
        </div>
      ),
    },
    {
      key: 'timestamp',
      header: 'Timestamp',
      sortable: true,
      render: (l) => (
        <div className="flex items-center gap-1.5 text-xs text-slate-400 font-mono">
          <Clock className="w-3.5 h-3.5 text-slate-500" />
          <span>{formatTimestamp(l.timestamp)}</span>
        </div>
      ),
    },
    {
      key: 'details',
      header: 'Metadata / Context',
      render: (l) => (
        <span className="font-mono text-[11px] text-slate-400 bg-slate-950 px-2 py-1 rounded border border-slate-800">
          {l.details ? JSON.stringify(l.details) : 'None'}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-sky-400" />
            <h2 className="text-2xl font-black text-white">Administrative Audit Trail</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Immutable security ledger tracking administrative operations, verification events, and data mutations.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-400 bg-slate-900 px-3.5 py-2 rounded-xl border border-slate-800">
          <span className="w-2 h-2 rounded-full bg-emerald-400" />
          <span>Audit Stream: <strong>Live</strong></span>
        </div>
      </div>

      <DataTable
        data={logs}
        columns={columns}
        searchPlaceholder="Search audit logs by action, admin, target..."
        searchFields={['action', 'adminEmail', 'targetCollection', 'targetId']}
        loading={loading}
        emptyMessage="No administrative audit logs recorded yet in Firestore 'AuditLogs'"
      />
    </div>
  );
};
