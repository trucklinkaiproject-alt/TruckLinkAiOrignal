import React, { useState, useMemo } from 'react';
import { Search, ChevronLeft, ChevronRight, ArrowUpDown, Download } from 'lucide-react';

export interface Column<T> {
  key: string;
  header: string;
  render?: (item: T) => React.ReactNode;
  sortable?: boolean;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  searchPlaceholder?: string;
  searchFields?: (keyof T | string)[];
  loading?: boolean;
  emptyMessage?: string;
  actions?: (item: T) => React.ReactNode;
  onExport?: () => void;
  filterComponent?: React.ReactNode;
  itemsPerPage?: number;
}

export function DataTable<T extends Record<string, any>>({
  data,
  columns,
  searchPlaceholder = 'Search records...',
  searchFields = [],
  loading = false,
  emptyMessage = 'No records found in Firestore',
  actions,
  onExport,
  filterComponent,
  itemsPerPage = 10,
}: DataTableProps<T>) {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortField, setSortField] = useState<string | null>(null);
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [currentPage, setCurrentPage] = useState(1);

  const filteredData = useMemo(() => {
    let result = [...data];

    // Search filter
    if (searchTerm.trim() !== '') {
      const term = searchTerm.toLowerCase();
      result = result.filter((item) => {
        if (searchFields.length > 0) {
          return searchFields.some((field) => {
            const val = item[field as keyof T];
            return val ? String(val).toLowerCase().includes(term) : false;
          });
        }
        return Object.values(item).some((val) =>
          val ? String(val).toLowerCase().includes(term) : false
        );
      });
    }

    // Sorting
    if (sortField) {
      result.sort((a, b) => {
        const aVal = a[sortField];
        const bVal = b[sortField];
        if (aVal === bVal) return 0;
        if (aVal === undefined || aVal === null) return 1;
        if (bVal === undefined || bVal === null) return -1;
        const comp = aVal > bVal ? 1 : -1;
        return sortDirection === 'asc' ? comp : -comp;
      });
    }

    return result;
  }, [data, searchTerm, searchFields, sortField, sortDirection]);

  // Pagination
  const totalPages = Math.ceil(filteredData.length / itemsPerPage) || 1;
  const paginatedData = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredData.slice(start, start + itemsPerPage);
  }, [filteredData, currentPage, itemsPerPage]);

  const handleSort = (key: string) => {
    if (sortField === key) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(key);
      setSortDirection('asc');
    }
  };

  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-900/60 backdrop-blur-xl shadow-xl overflow-hidden">
      {/* Header controls */}
      <div className="p-4 sm:p-5 border-b border-slate-800/80 flex flex-col sm:flex-row gap-4 items-stretch sm:items-center justify-between">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            placeholder={searchPlaceholder}
            className="w-full pl-10 pr-4 py-2 bg-slate-950/80 border border-slate-700/60 rounded-xl text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-colors"
          />
        </div>

        <div className="flex items-center gap-3">
          {filterComponent}
          {onExport && (
            <button
              onClick={onExport}
              className="inline-flex items-center gap-2 px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-medium rounded-xl border border-slate-700 transition-colors"
            >
              <Download className="w-4 h-4 text-slate-400" />
              Export
            </button>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm text-slate-300">
          <thead className="bg-slate-950/50 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  onClick={() => col.sortable && handleSort(col.key)}
                  className={`px-6 py-4 font-semibold ${
                    col.sortable ? 'cursor-pointer select-none hover:text-white' : ''
                  }`}
                >
                  <div className="flex items-center gap-1.5">
                    <span>{col.header}</span>
                    {col.sortable && (
                      <ArrowUpDown className="w-3.5 h-3.5 opacity-60" />
                    )}
                  </div>
                </th>
              ))}
              {actions && <th className="px-6 py-4 font-semibold text-right">Actions</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {loading ? (
              <tr>
                <td
                  colSpan={columns.length + (actions ? 1 : 0)}
                  className="px-6 py-12 text-center text-slate-400"
                >
                  <div className="inline-flex items-center gap-3">
                    <div className="w-5 h-5 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
                    <span>Loading real-time data from Firestore...</span>
                  </div>
                </td>
              </tr>
            ) : paginatedData.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length + (actions ? 1 : 0)}
                  className="px-6 py-12 text-center text-slate-400"
                >
                  <p className="text-base font-medium text-slate-300">{emptyMessage}</p>
                  <p className="text-xs text-slate-500 mt-1">
                    {searchTerm ? 'Try adjusting your search criteria' : 'Firestore collection is ready and listening for updates'}
                  </p>
                </td>
              </tr>
            ) : (
              paginatedData.map((item, idx) => (
                <tr
                  key={item.id || idx}
                  className="hover:bg-slate-800/30 transition-colors group"
                >
                  {columns.map((col) => (
                    <td key={col.key} className="px-6 py-4 whitespace-nowrap">
                      {col.render ? col.render(item) : item[col.key] ?? '—'}
                    </td>
                  ))}
                  {actions && (
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <div className="flex items-center justify-end gap-2">
                        {actions(item)}
                      </div>
                    </td>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination footer */}
      <div className="p-4 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400 bg-slate-950/30">
        <div>
          Showing{' '}
          <span className="font-semibold text-slate-200">
            {filteredData.length === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1}
          </span>{' '}
          to{' '}
          <span className="font-semibold text-slate-200">
            {Math.min(currentPage * itemsPerPage, filteredData.length)}
          </span>{' '}
          of <span className="font-semibold text-slate-200">{filteredData.length}</span> entries
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
            disabled={currentPage === 1 || loading}
            className="p-1.5 rounded-lg border border-slate-700 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="px-2 font-medium text-slate-300">
            {currentPage} / {totalPages}
          </span>
          <button
            onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
            disabled={currentPage === totalPages || loading}
            className="p-1.5 rounded-lg border border-slate-700 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
