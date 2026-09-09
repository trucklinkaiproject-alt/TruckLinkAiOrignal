import React, { useEffect, useState } from 'react';
import {
  Star,
  MessageSquare,
  Award,
  Truck,
  Briefcase,
  Search,
  Filter,
  Trash2,
  Edit,
  CheckCircle2,
  AlertTriangle,
  User,
  Package
} from 'lucide-react';
import {
  subscribeAllReviews,
  subscribeBrokers,
  subscribeDrivers,
  deleteReviewDoc,
  updateReviewDoc
} from '../services/firestoreService';
import { ReviewRating, BrokerProfile, DriverProfile } from '../types/models';
import { Badge } from '../components/common/Badge';
import { Modal } from '../components/common/Modal';
import { useAuth } from '../context/AuthContext';

export const Ratings: React.FC = () => {
  const [reviews, setReviews] = useState<ReviewRating[]>([]);
  const [brokers, setBrokers] = useState<BrokerProfile[]>([]);
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [roleFilter, setRoleFilter] = useState<'all' | 'broker' | 'driver'>('all');
  const [starFilter, setStarFilter] = useState<number | 'all'>('all');
  const [searchPerson, setSearchPerson] = useState('');

  // Modals
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [activeReview, setActiveReview] = useState<ReviewRating | null>(null);
  const [editRating, setEditRating] = useState<number>(5);
  const [editComment, setEditComment] = useState<string>('');
  const [actionLoading, setActionLoading] = useState(false);

  const { adminProfile } = useAuth();
  const adminEmail = adminProfile?.email || 'admin@trucklink.ai';

  useEffect(() => {
    let unsubs: (() => void)[] = [];

    const unsubBrokers = subscribeBrokers((data) => setBrokers(data));
    const unsubDrivers = subscribeDrivers((data) => setDrivers(data));
    const unsubReviews = subscribeAllReviews((data) => {
      setReviews(data);
      setLoading(false);
    });

    unsubs = [unsubBrokers, unsubDrivers, unsubReviews];
    return () => unsubs.forEach((fn) => fn());
  }, []);

  // Compute real network metrics
  const totalCount = reviews.length;
  const totalRatingSum = reviews.reduce((acc, r) => acc + (Number(r.rating) || 0), 0);
  const avgRating = totalCount > 0 ? (totalRatingSum / totalCount).toFixed(1) : '0.0';

  // Real Star distribution
  const starCounts = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  reviews.forEach((r) => {
    const rounded = Math.min(5, Math.max(1, Math.round(Number(r.rating) || 0)));
    if (rounded >= 1 && rounded <= 5) {
      starCounts[rounded as 1 | 2 | 3 | 4 | 5]++;
    }
  });

  // Broker vs Driver stats
  const brokerReviews = reviews.filter((r) => r.reviewee_role === 'broker' || r.targetType === 'broker');
  const driverReviews = reviews.filter((r) => r.reviewee_role === 'driver' || r.targetType === 'driver');

  const brokerAvg =
    brokerReviews.length > 0
      ? (brokerReviews.reduce((sum, r) => sum + (Number(r.rating) || 0), 0) / brokerReviews.length).toFixed(1)
      : '0.0';

  const driverAvg =
    driverReviews.length > 0
      ? (driverReviews.reduce((sum, r) => sum + (Number(r.rating) || 0), 0) / driverReviews.length).toFixed(1)
      : '0.0';

  // Filtered reviews list
  const filteredReviews = reviews.filter((r) => {
    const role = (r.reviewee_role || r.targetType || 'broker').toLowerCase();
    if (roleFilter !== 'all' && role !== roleFilter) return false;

    if (starFilter !== 'all') {
      const rounded = Math.round(Number(r.rating) || 0);
      if (rounded !== starFilter) return false;
    }

    if (searchPerson.trim()) {
      const query = searchPerson.toLowerCase().trim();
      const revieweeName = (r.reviewee_name || '').toLowerCase();
      const revieweeId = (r.reviewee_id || r.targetId || '').toLowerCase();
      const reviewerName = (r.reviewer_name || '').toLowerCase();
      const orderId = (r.order_id || r.orderNo || '').toLowerCase();
      return (
        revieweeName.includes(query) ||
        revieweeId.includes(query) ||
        reviewerName.includes(query) ||
        orderId.includes(query)
      );
    }

    return true;
  });

  const handleOpenEdit = (review: ReviewRating) => {
    setActiveReview(review);
    setEditRating(Number(review.rating) || 5);
    setEditComment(review.comment || '');
    setEditModalOpen(true);
  };

  const handleOpenDelete = (review: ReviewRating) => {
    setActiveReview(review);
    setDeleteModalOpen(true);
  };

  const handleSaveEdit = async () => {
    if (!activeReview) return;
    setActionLoading(true);
    try {
      await updateReviewDoc(activeReview, editRating, editComment, adminEmail);
      setEditModalOpen(false);
    } catch (err) {
      console.error('Failed to update review:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!activeReview) return;
    setActionLoading(true);
    try {
      await deleteReviewDoc(activeReview, adminEmail);
      setDeleteModalOpen(false);
    } catch (err) {
      console.error('Failed to delete review:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const formatReviewDate = (timestamp: any) => {
    if (!timestamp) return 'Recently';
    if (timestamp.toDate) {
      return timestamp.toDate().toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    }
    return 'Recently';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Star className="w-6 h-6 text-amber-400 fill-amber-400" />
            <h2 className="text-2xl font-black text-white">Trust, Ratings & Feedback</h2>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Real Firebase review logs, star distributions, and quality assurance across Brokers and Drivers.
          </p>
        </div>

        <div className="flex items-center gap-2 bg-slate-900 border border-slate-800 px-4 py-2 rounded-xl text-xs">
          <Award className="w-4 h-4 text-amber-400" />
          <span>
            Network Trust Score: <strong className="text-amber-400 font-bold">{avgRating} / 5.0</strong>
          </span>
        </div>
      </div>

      {/* Metrics Cards & Star Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Overall Score */}
        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl flex flex-col justify-between shadow-xl">
          <div>
            <div className="flex items-center justify-between">
              <p className="text-xs text-slate-400 uppercase font-semibold">Average Network Rating</p>
              <div className="p-2 bg-amber-500/10 rounded-lg text-amber-400 border border-amber-500/20">
                <Award className="w-5 h-5" />
              </div>
            </div>
            <h3 className="text-4xl font-extrabold text-white mt-2 flex items-baseline gap-2">
              {avgRating} <span className="text-sm font-normal text-slate-400">/ 5.0</span>
            </h3>
            <div className="flex items-center gap-1 text-amber-400 mt-3">
              {[1, 2, 3, 4, 5].map((s) => (
                <Star
                  key={s}
                  className={`w-4 h-4 ${
                    s <= Math.round(Number(avgRating)) ? 'fill-amber-400' : 'text-slate-600'
                  }`}
                />
              ))}
              <span className="text-xs text-slate-400 ml-2">({totalCount} Total Reviews)</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 mt-6 pt-4 border-t border-slate-800 text-xs">
            <div>
              <span className="text-slate-500">Brokers Avg</span>
              <p className="text-purple-300 font-bold text-sm mt-0.5">{brokerAvg} ★</p>
              <span className="text-[11px] text-slate-500">{brokerReviews.length} reviews</span>
            </div>
            <div>
              <span className="text-slate-500">Drivers Avg</span>
              <p className="text-cyan-300 font-bold text-sm mt-0.5">{driverAvg} ★</p>
              <span className="text-[11px] text-slate-500">{driverReviews.length} reviews</span>
            </div>
          </div>
        </div>

        {/* Real Star Distribution */}
        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl shadow-xl flex flex-col justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold mb-3">Star Distribution</p>
            <div className="space-y-2">
              {[5, 4, 3, 2, 1].map((star) => {
                const count = starCounts[star as 1 | 2 | 3 | 4 | 5];
                const pct = totalCount > 0 ? Math.round((count / totalCount) * 100) : 0;
                return (
                  <div key={star} className="flex items-center gap-2 text-xs">
                    <span className="w-8 text-slate-400 font-mono">{star} ★</span>
                    <div className="flex-1 h-2 bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-amber-400 rounded-full transition-all duration-500"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                    <span className="w-12 text-right text-slate-400 font-mono">
                      {count} ({pct}%)
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-3 border-t border-slate-800 text-xs text-slate-400 flex items-center justify-between">
            <span>Verified Order Reviews</span>
            <span className="text-emerald-400 font-medium">Auto Synced</span>
          </div>
        </div>

        {/* Stakeholder Health Card */}
        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl shadow-xl flex flex-col justify-between">
          <div>
            <p className="text-xs text-slate-400 uppercase font-semibold mb-3">Carrier Assurance</p>
            <div className="space-y-3">
              <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-lg bg-purple-500/10 text-purple-400">
                    <Briefcase className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Registered Brokers</p>
                    <p className="text-[11px] text-slate-400">{brokers.length} partners</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-purple-400">{brokerAvg} ★</span>
              </div>

              <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-400">
                    <Truck className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">Active Drivers</p>
                    <p className="text-[11px] text-slate-400">{drivers.length} drivers</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-cyan-400">{driverAvg} ★</span>
              </div>
            </div>
          </div>

          <div className="pt-3 border-t border-slate-800 text-xs text-emerald-400 flex items-center gap-1.5">
            <CheckCircle2 className="w-4 h-4" />
            <span>Strict moderation enabled for Super Admin</span>
          </div>
        </div>
      </div>

      {/* Filter by Person & Search Controls */}
      <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800 backdrop-blur-xl shadow-xl flex flex-col md:flex-row items-center justify-between gap-3">
        {/* Person Search */}
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by Broker/Driver Name or UID..."
            value={searchPerson}
            onChange={(e) => setSearchPerson(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-950/80 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-brand-500"
          />
        </div>

        {/* Filter Badges & Star Selector */}
        <div className="flex flex-wrap items-center gap-2 w-full md:w-auto">
          <div className="flex items-center gap-1 bg-slate-950/80 border border-slate-800 p-1 rounded-xl">
            <button
              onClick={() => setRoleFilter('all')}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                roleFilter === 'all'
                  ? 'bg-brand-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              All Roles ({reviews.length})
            </button>
            <button
              onClick={() => setRoleFilter('broker')}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                roleFilter === 'broker'
                  ? 'bg-purple-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Brokers ({brokerReviews.length})
            </button>
            <button
              onClick={() => setRoleFilter('driver')}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                roleFilter === 'driver'
                  ? 'bg-cyan-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Drivers ({driverReviews.length})
            </button>
          </div>

          <select
            value={starFilter}
            onChange={(e) =>
              setStarFilter(e.target.value === 'all' ? 'all' : Number(e.target.value))
            }
            className="px-3 py-1.5 bg-slate-950/80 border border-slate-800 rounded-xl text-xs text-white focus:outline-none focus:border-brand-500"
          >
            <option value="all">All Stars</option>
            <option value="5">5 Stars</option>
            <option value="4">4 Stars</option>
            <option value="3">3 Stars</option>
            <option value="2">2 Stars</option>
            <option value="1">1 Star</option>
          </select>
        </div>
      </div>

      {/* Review Feed List */}
      <div className="rounded-2xl bg-slate-900/60 border border-slate-800 p-6 backdrop-blur-xl shadow-xl">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-amber-400" />
            <h3 className="text-base font-bold text-white">Live Feedback Records</h3>
          </div>
          <span className="text-xs text-slate-400">
            Showing <strong className="text-white">{filteredReviews.length}</strong> verified entries
          </span>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-400">
            <p className="text-sm font-medium">Loading verified reviews from Firestore...</p>
          </div>
        ) : filteredReviews.length === 0 ? (
          <div className="py-12 text-center text-slate-400">
            <Star className="w-8 h-8 text-slate-600 mx-auto mb-2" />
            <p className="text-sm font-medium text-slate-300">No reviews match current criteria</p>
            <p className="text-xs text-slate-500 mt-1">
              Verified reviews submitted by users and brokers after trip completion will automatically stream here.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredReviews.map((rev) => {
              const isBroker = rev.reviewee_role === 'broker' || rev.targetType === 'broker';
              return (
                <div
                  key={rev.id}
                  className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 hover:border-slate-700 transition-all flex flex-col lg:flex-row lg:items-center justify-between gap-4"
                >
                  <div className="space-y-1.5 flex-1">
                    {/* Reviewee details */}
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-bold text-white text-sm">
                        {rev.reviewee_name || (isBroker ? 'Broker Partner' : 'Driver Partner')}
                      </span>
                      <Badge variant={isBroker ? 'purple' : 'info'} size="sm">
                        {isBroker ? 'Broker' : 'Driver'}
                      </Badge>
                      {rev.reviewee_id && (
                        <span className="text-[11px] font-mono text-slate-500">
                          UID: {rev.reviewee_id.substring(0, 8)}...
                        </span>
                      )}
                      <div className="flex items-center gap-0.5 text-amber-400 ml-1">
                        {[1, 2, 3, 4, 5].map((s) => (
                          <Star
                            key={s}
                            className={`w-3.5 h-3.5 ${
                              s <= Math.round(Number(rev.rating) || 0)
                                ? 'fill-amber-400 text-amber-400'
                                : 'text-slate-700'
                            }`}
                          />
                        ))}
                        <span className="text-xs font-bold text-amber-300 ml-1">
                          {Number(rev.rating).toFixed(1)}
                        </span>
                      </div>
                    </div>

                    {/* Comment text */}
                    <p className="text-xs text-slate-200 leading-relaxed">
                      "{rev.comment || 'No comment text provided'}"
                    </p>

                    {/* Reviewer info & metadata */}
                    <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-400 pt-0.5">
                      <span className="flex items-center gap-1">
                        <User className="w-3 h-3 text-slate-500" />
                        Reviewed by: <strong className="text-slate-300">{rev.reviewer_name || 'Verified User'}</strong>
                        <span className="text-slate-500">({rev.reviewer_role || 'User'})</span>
                      </span>
                      {rev.order_id && (
                        <span className="flex items-center gap-1 font-mono text-slate-500">
                          <Package className="w-3 h-3 text-slate-500" />
                          Order #{rev.orderNo || rev.order_id.substring(0, 8)}
                        </span>
                      )}
                      <span>• {formatReviewDate(rev.created_at || rev.createdAt)}</span>
                    </div>
                  </div>

                  {/* Super Admin Actions */}
                  <div className="shrink-0 flex items-center gap-2">
                    <button
                      onClick={() => handleOpenEdit(rev)}
                      title="Edit Rating & Comment"
                      className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-sky-400 border border-slate-700 transition-colors"
                    >
                      <Edit className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleOpenDelete(rev)}
                      title="Delete Review Document"
                      className="p-2 rounded-lg bg-slate-800 hover:bg-rose-950/50 text-rose-400 border border-slate-700 hover:border-rose-700/50 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Edit Review Modal */}
      <Modal
        isOpen={editModalOpen}
        onClose={() => setEditModalOpen(false)}
        title="Moderate Review Document"
        maxWidth="md"
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-400">
            Edit the star rating and feedback comment for review on{' '}
            <strong className="text-white">{activeReview?.reviewee_name}</strong>:
          </p>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase mb-1.5">
              Star Rating (1 - 5)
            </label>
            <div className="flex items-center gap-2">
              {[1, 2, 3, 4, 5].map((s) => (
                <button
                  type="button"
                  key={s}
                  onClick={() => setEditRating(s)}
                  className="p-1 text-amber-400 focus:outline-none"
                >
                  <Star
                    className={`w-6 h-6 ${
                      s <= editRating ? 'fill-amber-400 text-amber-400' : 'text-slate-600'
                    }`}
                  />
                </button>
              ))}
              <span className="text-sm font-bold text-white ml-2">{editRating}.0</span>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase mb-1.5">
              Comment Text
            </label>
            <textarea
              rows={3}
              value={editComment}
              onChange={(e) => setEditComment(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-brand-500"
              placeholder="Enter updated comment..."
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
            <button
              onClick={() => setEditModalOpen(false)}
              disabled={actionLoading}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              onClick={handleSaveEdit}
              disabled={actionLoading}
              className="px-4 py-2 bg-brand-600 hover:bg-brand-500 text-white rounded-xl text-xs font-semibold transition-colors"
            >
              {actionLoading ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        title="Delete Review Document"
        maxWidth="md"
      >
        <div className="space-y-4">
          <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-xs flex items-start gap-2.5">
            <AlertTriangle className="w-5 h-5 shrink-0 text-rose-400" />
            <div>
              <p className="font-bold">Permanent Review Deletion</p>
              <p className="mt-0.5 text-rose-200/80">
                This will permanently delete this review document from both root{' '}
                <code className="bg-rose-950/40 px-1 py-0.5 rounded">Reviews</code> and the respective{' '}
                <code className="bg-rose-950/40 px-1 py-0.5 rounded">
                  {activeReview?.reviewee_role === 'driver' ? 'Driver' : 'Broker'}/.../Reviews
                </code>{' '}
                subcollection.
              </p>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 text-xs text-slate-300">
            <p>
              <strong>Target:</strong> {activeReview?.reviewee_name} (
              {activeReview?.reviewee_role === 'driver' ? 'Driver' : 'Broker'})
            </p>
            <p className="mt-1">
              <strong>Rating:</strong> {activeReview?.rating} ★
            </p>
            <p className="mt-1 italic">"{activeReview?.comment}"</p>
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
            <button
              onClick={() => setDeleteModalOpen(false)}
              disabled={actionLoading}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              onClick={handleConfirmDelete}
              disabled={actionLoading}
              className="px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-xl text-xs font-semibold transition-colors"
            >
              {actionLoading ? 'Deleting...' : 'Confirm Delete'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
