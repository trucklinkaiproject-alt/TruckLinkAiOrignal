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
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <Star className="w-5 h-5 text-amber-500 fill-amber-500" />
            <h2 className="text-lg font-bold text-slate-900">Trust, Ratings & Feedback</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Review logs, rating distributions, and feedback moderation across Brokers and Drivers.
          </p>
        </div>

        <div className="flex items-center gap-2 bg-white border border-slate-200 px-3.5 py-1.5 rounded-md text-xs shadow-2xs">
          <Award className="w-4 h-4 text-amber-500" />
          <span className="text-slate-700">
            Network Trust Score: <strong className="text-slate-900 font-bold">{avgRating} / 5.0</strong>
          </span>
        </div>
      </div>

      {/* Metrics Cards & Star Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Overall Score */}
        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <p className="text-[11px] text-slate-500 uppercase font-semibold">Average Network Rating</p>
              <div className="p-2 bg-amber-50 rounded-md text-amber-600 border border-amber-200">
                <Award className="w-4 h-4" />
              </div>
            </div>
            <h3 className="text-3xl font-bold text-slate-900 mt-1 flex items-baseline gap-2">
              {avgRating} <span className="text-xs font-normal text-slate-500">/ 5.0</span>
            </h3>
            <div className="flex items-center gap-1 text-amber-500 mt-2">
              {[1, 2, 3, 4, 5].map((s) => (
                <Star
                  key={s}
                  className={`w-3.5 h-3.5 ${
                    s <= Math.round(Number(avgRating)) ? 'fill-amber-500 text-amber-500' : 'text-slate-300'
                  }`}
                />
              ))}
              <span className="text-xs text-slate-500 ml-1.5">({totalCount} Total Reviews)</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 mt-4 pt-3 border-t border-slate-100 text-xs">
            <div>
              <span className="text-slate-500 text-[11px]">Brokers Avg</span>
              <p className="text-slate-900 font-bold text-sm mt-0.5">{brokerAvg} ★</p>
              <span className="text-[10px] text-slate-500">{brokerReviews.length} reviews</span>
            </div>
            <div>
              <span className="text-slate-500 text-[11px]">Drivers Avg</span>
              <p className="text-slate-900 font-bold text-sm mt-0.5">{driverAvg} ★</p>
              <span className="text-[10px] text-slate-500">{driverReviews.length} reviews</span>
            </div>
          </div>
        </div>

        {/* Real Star Distribution */}
        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex flex-col justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold mb-2.5">Star Distribution</p>
            <div className="space-y-1.5">
              {[5, 4, 3, 2, 1].map((star) => {
                const count = starCounts[star as 1 | 2 | 3 | 4 | 5];
                const pct = totalCount > 0 ? Math.round((count / totalCount) * 100) : 0;
                return (
                  <div key={star} className="flex items-center gap-2 text-xs">
                    <span className="w-7 text-slate-600 font-mono text-[11px]">{star} ★</span>
                    <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-amber-500 rounded-full transition-all duration-300"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                    <span className="w-12 text-right text-slate-500 font-mono text-[11px]">
                      {count} ({pct}%)
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-3 border-t border-slate-100 text-xs text-slate-500 flex items-center justify-between">
            <span>Verified Order Reviews</span>
            <span className="text-emerald-700 font-medium text-[11px]">Auto Synced</span>
          </div>
        </div>

        {/* Stakeholder Health Card */}
        <div className="p-4 rounded-lg bg-white border border-slate-200 shadow-2xs flex flex-col justify-between">
          <div>
            <p className="text-[11px] text-slate-500 uppercase font-semibold mb-2.5">Carrier Assurance</p>
            <div className="space-y-2">
              <div className="p-2.5 rounded-md bg-slate-50 border border-slate-200 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="p-1.5 rounded bg-slate-100 text-slate-600">
                    <Briefcase className="w-3.5 h-3.5" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Registered Brokers</p>
                    <p className="text-[10px] text-slate-500">{brokers.length} partners</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-slate-900">{brokerAvg} ★</span>
              </div>

              <div className="p-2.5 rounded-md bg-slate-50 border border-slate-200 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="p-1.5 rounded bg-slate-100 text-slate-600">
                    <Truck className="w-3.5 h-3.5" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Active Drivers</p>
                    <p className="text-[10px] text-slate-500">{drivers.length} drivers</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-slate-900">{driverAvg} ★</span>
              </div>
            </div>
          </div>

          <div className="pt-3 border-t border-slate-100 text-xs text-emerald-700 flex items-center gap-1.5">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
            <span className="text-[11px]">Moderation controls active for Super Admin</span>
          </div>
        </div>
      </div>

      {/* Filter by Person & Search Controls */}
      <div className="p-3.5 rounded-lg bg-white border border-slate-200 shadow-2xs flex flex-col md:flex-row items-center justify-between gap-3">
        {/* Person Search */}
        <div className="relative w-full md:w-80">
          <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by Broker/Driver Name or UID..."
            value={searchPerson}
            onChange={(e) => setSearchPerson(e.target.value)}
            className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-300 rounded-md text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-sky-600"
          />
        </div>

        {/* Filter Badges & Star Selector */}
        <div className="flex flex-wrap items-center gap-2 w-full md:w-auto">
          <div className="flex items-center gap-1 bg-slate-100 border border-slate-200 p-0.5 rounded-md">
            <button
              onClick={() => setRoleFilter('all')}
              className={`px-2.5 py-1 rounded text-xs font-semibold transition-colors ${
                roleFilter === 'all'
                  ? 'bg-white text-slate-900 shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              All Roles ({reviews.length})
            </button>
            <button
              onClick={() => setRoleFilter('broker')}
              className={`px-2.5 py-1 rounded text-xs font-semibold transition-colors ${
                roleFilter === 'broker'
                  ? 'bg-white text-slate-900 shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Brokers ({brokerReviews.length})
            </button>
            <button
              onClick={() => setRoleFilter('driver')}
              className={`px-2.5 py-1 rounded text-xs font-semibold transition-colors ${
                roleFilter === 'driver'
                  ? 'bg-white text-slate-900 shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
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
            className="px-2.5 py-1.5 bg-white border border-slate-300 rounded-md text-xs text-slate-900 focus:outline-none focus:border-sky-600"
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
      <div className="rounded-lg bg-white border border-slate-200 p-4 shadow-2xs">
        <div className="flex items-center justify-between mb-3.5 pb-2.5 border-b border-slate-100">
          <div className="flex items-center gap-1.5">
            <MessageSquare className="w-4 h-4 text-sky-700" />
            <h3 className="text-sm font-bold text-slate-900">Feedback Records</h3>
          </div>
          <span className="text-xs text-slate-500">
            Showing <strong className="text-slate-900">{filteredReviews.length}</strong> verified entries
          </span>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-500">
            <p className="text-xs font-medium">Loading verified reviews from Firestore...</p>
          </div>
        ) : filteredReviews.length === 0 ? (
          <div className="py-12 text-center text-slate-500">
            <Star className="w-6 h-6 text-slate-400 mx-auto mb-1.5" />
            <p className="text-xs font-semibold text-slate-800">No reviews match current criteria</p>
            <p className="text-[11px] text-slate-500 mt-0.5">
              Verified reviews submitted by users and brokers after trip completion will automatically appear here.
            </p>
          </div>
        ) : (
          <div className="space-y-2.5">
            {filteredReviews.map((rev) => {
              const isBroker = rev.reviewee_role === 'broker' || rev.targetType === 'broker';
              return (
                <div
                  key={rev.id}
                  className="p-3.5 rounded-md bg-slate-50 border border-slate-200 hover:bg-slate-100/70 transition-all flex flex-col lg:flex-row lg:items-center justify-between gap-3"
                >
                  <div className="space-y-1 flex-1">
                    {/* Reviewee details */}
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-bold text-slate-900 text-xs">
                        {rev.reviewee_name || (isBroker ? 'Broker Partner' : 'Driver Partner')}
                      </span>
                      <Badge variant={isBroker ? 'purple' : 'info'} size="sm">
                        {isBroker ? 'Broker' : 'Driver'}
                      </Badge>
                      {rev.reviewee_id && (
                        <span className="text-[10px] font-mono text-slate-500">
                          UID: {rev.reviewee_id.substring(0, 8)}...
                        </span>
                      )}
                      <div className="flex items-center gap-0.5 text-amber-500 ml-1">
                        {[1, 2, 3, 4, 5].map((s) => (
                          <Star
                            key={s}
                            className={`w-3 h-3 ${
                              s <= Math.round(Number(rev.rating) || 0)
                                ? 'fill-amber-500 text-amber-500'
                                : 'text-slate-300'
                            }`}
                          />
                        ))}
                        <span className="text-xs font-bold text-amber-700 ml-1">
                          {Number(rev.rating).toFixed(1)}
                        </span>
                      </div>
                    </div>

                    {/* Comment text */}
                    <p className="text-xs text-slate-800 leading-relaxed">
                      "{rev.comment || 'No comment text provided'}"
                    </p>

                    {/* Reviewer info & metadata */}
                    <div className="flex flex-wrap items-center gap-2.5 text-[11px] text-slate-500 pt-0.5">
                      <span className="flex items-center gap-1">
                        <User className="w-3 h-3 text-slate-400" />
                        Reviewed by: <strong className="text-slate-700 font-medium">{rev.reviewer_name || 'Verified User'}</strong>
                        <span className="text-slate-500">({rev.reviewer_role || 'User'})</span>
                      </span>
                      {rev.order_id && (
                        <span className="flex items-center gap-1 font-mono text-slate-500">
                          <Package className="w-3 h-3 text-slate-400" />
                          Order #{rev.orderNo || rev.order_id.substring(0, 8)}
                        </span>
                      )}
                      <span>• {formatReviewDate(rev.created_at || rev.createdAt)}</span>
                    </div>
                  </div>

                  {/* Super Admin Actions */}
                  <div className="shrink-0 flex items-center gap-1.5">
                    <button
                      onClick={() => handleOpenEdit(rev)}
                      title="Edit Rating & Comment"
                      className="p-1.5 rounded-md bg-white hover:bg-slate-50 text-slate-600 border border-slate-300 transition-colors shadow-2xs"
                    >
                      <Edit className="w-3.5 h-3.5 text-sky-700" />
                    </button>
                    <button
                      onClick={() => handleOpenDelete(rev)}
                      title="Delete Review Document"
                      className="p-1.5 rounded-md bg-white hover:bg-rose-50 text-rose-700 border border-rose-200 transition-colors shadow-2xs"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
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
          <p className="text-xs text-slate-600">
            Edit the star rating and feedback comment for review on{' '}
            <strong className="text-slate-900 font-semibold">{activeReview?.reviewee_name}</strong>:
          </p>

          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
              Star Rating (1 - 5)
            </label>
            <div className="flex items-center gap-1.5">
              {[1, 2, 3, 4, 5].map((s) => (
                <button
                  type="button"
                  key={s}
                  onClick={() => setEditRating(s)}
                  className="p-1 text-amber-500 focus:outline-none"
                >
                  <Star
                    className={`w-5 h-5 ${
                      s <= editRating ? 'fill-amber-500 text-amber-500' : 'text-slate-300'
                    }`}
                  />
                </button>
              ))}
              <span className="text-xs font-bold text-slate-900 ml-1.5">{editRating}.0</span>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
              Comment Text
            </label>
            <textarea
              rows={3}
              value={editComment}
              onChange={(e) => setEditComment(e.target.value)}
              className="w-full px-3 py-2 bg-white border border-slate-300 rounded-md text-xs text-slate-900 focus:outline-none focus:border-sky-600"
              placeholder="Enter updated comment..."
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-200">
            <button
              onClick={() => setEditModalOpen(false)}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-md text-xs font-semibold shadow-2xs"
            >
              Cancel
            </button>
            <button
              onClick={handleSaveEdit}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-sky-700 hover:bg-sky-800 text-white rounded-md text-xs font-semibold shadow-2xs transition-colors"
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
          <div className="p-3.5 rounded-md bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-start gap-2.5">
            <AlertTriangle className="w-4 h-4 shrink-0 text-rose-600 mt-0.5" />
            <div>
              <p className="font-bold text-rose-900">Permanent Review Deletion</p>
              <p className="mt-0.5 text-rose-700">
                This will permanently delete this review document from both root{' '}
                <code className="bg-rose-100 px-1 py-0.5 rounded font-mono text-[10px]">Reviews</code> and the respective{' '}
                <code className="bg-rose-100 px-1 py-0.5 rounded font-mono text-[10px]">
                  {activeReview?.reviewee_role === 'driver' ? 'Driver' : 'Broker'}/.../Reviews
                </code>{' '}
                subcollection.
              </p>
            </div>
          </div>

          <div className="p-3 rounded-md bg-slate-50 border border-slate-200 text-xs text-slate-700">
            <p>
              <strong className="text-slate-900">Target:</strong> {activeReview?.reviewee_name} (
              {activeReview?.reviewee_role === 'driver' ? 'Driver' : 'Broker'})
            </p>
            <p className="mt-1">
              <strong className="text-slate-900">Rating:</strong> {activeReview?.rating} ★
            </p>
            <p className="mt-1 italic text-slate-600">"{activeReview?.comment}"</p>
          </div>

          <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-200">
            <button
              onClick={() => setDeleteModalOpen(false)}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-md text-xs font-semibold shadow-2xs"
            >
              Cancel
            </button>
            <button
              onClick={handleConfirmDelete}
              disabled={actionLoading}
              className="px-3.5 py-1.5 bg-rose-700 hover:bg-rose-800 text-white rounded-md text-xs font-semibold shadow-2xs transition-colors"
            >
              {actionLoading ? 'Deleting...' : 'Confirm Delete'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
