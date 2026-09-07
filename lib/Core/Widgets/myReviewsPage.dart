import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';

class MyReviewsPage extends StatelessWidget {
  final String? userId;
  final String userRole; // 'Driver' or 'Broker'
  final String? userName;

  const MyReviewsPage({
    super.key,
    this.userId,
    required this.userRole,
    this.userName,
  });

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Recent";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return "Recent";
    }
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveUserId = (userId != null && userId!.isNotEmpty)
        ? userId!
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    final bool isDriver = userRole.toLowerCase() == 'driver';
    final Color primaryColor = isDriver ? Appcolors.tertiaryGreen : Appcolors.secondaryPurple;

    if (effectiveUserId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: Center(
            child: Text(
              "Please sign in to view your reviews.",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final String collectionName = isDriver ? "Driver" : "Broker";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 18 : width * 0.12;

            return Column(
              children: [
                // ── Top Header ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    15,
                    horizontalPadding,
                    10,
                  ),
                  child: Row(
                    children: [
                      BackArrowButton(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "My Reviews",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Real-Time Reviews Stream ─────────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(collectionName)
                        .doc(effectiveUserId)
                        .collection("Reviews")
                        .orderBy("created_at", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "Error loading reviews: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      // Calculate live statistics
                      int totalReviews = 0;
                      double sumRating = 0.0;
                      int star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0;

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final r = (data['rating'] as num?)?.toDouble() ?? 0.0;
                        if (r > 0) {
                          totalReviews++;
                          sumRating += r;

                          final rounded = r.round();
                          if (rounded >= 5) {
                            star5++;
                          } else if (rounded == 4) {
                            star4++;
                          } else if (rounded == 3) {
                            star3++;
                          } else if (rounded == 2) {
                            star2++;
                          } else if (rounded <= 1) {
                            star1++;
                          }
                        }
                      }

                      final double avgRating = totalReviews > 0
                          ? double.parse((sumRating / totalReviews).toStringAsFixed(1))
                          : 0.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          6,
                          horizontalPadding,
                          30,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Overall Rating Summary Card ────────────────
                            _buildRatingSummaryCard(
                              avgRating: avgRating,
                              totalReviews: totalReviews,
                              star5: star5,
                              star4: star4,
                              star3: star3,
                              star2: star2,
                              star1: star1,
                              primaryColor: primaryColor,
                            ),

                            const SizedBox(height: 22),

                            // ── Section Title ──────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Recent Reviews",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (totalReviews > 0)
                                  Text(
                                    "$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Review Cards List / Empty State ───────────
                            if (docs.isEmpty)
                              _buildEmptyReviews(primaryColor: primaryColor)
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final String reviewerName =
                                      (data['reviewer_name'] ?? 'Verified Client').toString();
                                  final String reviewerRole =
                                      (data['reviewer_role'] ?? '').toString();
                                  final double rating =
                                      (data['rating'] as num?)?.toDouble() ?? 5.0;
                                  final String comment =
                                      (data['comment'] ?? '').toString().trim();
                                  final dynamic createdAt = data['created_at'];
                                  final String orderId =
                                      (data['order_id'] ?? data['orderId'] ?? '').toString();

                                  return _buildReviewTile(
                                    reviewerName: reviewerName,
                                    reviewerRole: reviewerRole,
                                    rating: rating,
                                    comment: comment,
                                    dateStr: _formatDate(createdAt),
                                    orderId: orderId,
                                    primaryColor: primaryColor,
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingSummaryCard({
    required double avgRating,
    required int totalReviews,
    required int star5,
    required int star4,
    required int star3,
    required int star2,
    required int star1,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Big Average Score
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  totalReviews > 0 ? avgRating.toStringAsFixed(1) : "0.0",
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStarRow(avgRating, size: 16),
                const SizedBox(height: 8),
                Text(
                  totalReviews > 0
                      ? "Based on $totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}"
                      : "No ratings yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 90,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),

          // Right side: Star Breakdown Bars
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildRatingBar(5, star5, totalReviews),
                const SizedBox(height: 4),
                _buildRatingBar(4, star4, totalReviews),
                const SizedBox(height: 4),
                _buildRatingBar(3, star3, totalReviews),
                const SizedBox(height: 4),
                _buildRatingBar(2, star2, totalReviews),
                const SizedBox(height: 4),
                _buildRatingBar(1, star1, totalReviews),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int starNum, int count, int total) {
    final double fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Text(
          "$starNum",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            "$count",
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRow(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final double starValue = index + 1.0;
        if (rating >= starValue) {
          return Icon(Icons.star_rounded, color: Colors.amber, size: size);
        } else if (rating >= starValue - 0.5) {
          return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_outline_rounded, color: Colors.grey.shade300, size: size);
        }
      }),
    );
  }

  Widget _buildReviewTile({
    required String reviewerName,
    required String reviewerRole,
    required double rating,
    required String comment,
    required String dateStr,
    required String orderId,
    required Color primaryColor,
  }) {
    final String cleanRole = reviewerRole.isNotEmpty
        ? (reviewerRole.toLowerCase() == 'user' ? 'Shipper' : reviewerRole)
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Reviewer Name, Role, Rating & Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withOpacity(0.12),
                child: Text(
                  reviewerName.trim().isNotEmpty
                      ? reviewerName.trim()[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reviewerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (cleanRole.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cleanRole.toUpperCase(),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildStarRow(rating, size: 14),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (orderId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Order #$orderId",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review Comment
          Text(
            comment.isNotEmpty ? comment : "No comment provided.",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: comment.isNotEmpty ? Colors.black87 : Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews({required Color primaryColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_border_rounded, color: primaryColor, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Reviews Yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You haven't received any reviews yet.\nComplete shipments and fulfill orders to receive ratings and feedback.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
