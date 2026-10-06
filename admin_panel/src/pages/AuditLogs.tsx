import React, { useEffect, useState } from 'react';
import { DataTable, Column } from '../components/common/DataTable';
import { subscribeAuditLogs } from '../services/firestoreService';
import { AuditLog } from '../types/models';
import { ShieldCheck, Clock, User, Shield } from 'lucide-react';

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
          <div className="w-7 h-7 rounded-sm bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-700 font-mono text-xs shrink-0">
            <Shield className="w-3.5 h-3.5" />
          </div>
          <div>
            <p className="font-mono font-bold text-slate-900 text-xs">{l.action}</p>
            <p className="text-[11px] text-slate-500">
              Target: <span className="text-sky-700 font-medium">{l.targetCollection}</span> / {l.targetId?.substring(0, 10)}...
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
        <div className="flex items-center gap-1.5 text-xs text-slate-700">
          <User className="w-3.5 h-3.5 text-slate-400" />
          <span>{l.adminEmail}</span>
        </div>
      ),
    },
    {
      key: 'timestamp',
      header: 'Timestamp',
      sortable: true,
      render: (l) => (
        <div className="flex items-center gap-1.5 text-xs text-slate-600 font-mono">
          <Clock className="w-3.5 h-3.5 text-slate-400" />
          <span>{formatTimestamp(l.timestamp)}</span>
        </div>
      ),
    },
    {
      key: 'details',
      header: 'Metadata / Context',
      render: (l) => (
        <span className="font-mono text-[11px] text-slate-600 bg-slate-100 px-2 py-0.5 rounded border border-slate-200 max-w-xs truncate inline-block">
          {l.details ? JSON.stringify(l.details) : 'None'}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-sky-700" />
            <h2 className="text-xl font-bold text-slate-900">Administrative Audit Trail</h2>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Immutable security ledger tracking administrative operations, verification events, and data mutations.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-600 bg-white px-3.5 py-2 rounded-md border border-slate-200 shadow-2xs">
          <span className="w-2 h-2 rounded-full bg-emerald-500" />
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
