// lib/Features/User Module/Widgets/aiRecommendationCard.dart
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/brokerRecommendationModel.dart';

class AiRecommendationCard extends StatelessWidget {
  final BrokerRecommendationModel recommendation;
  final VoidCallback onTap;

  const AiRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  String _formatReason(String code) {
    switch (code) {
      case 'DRIVER_CLOSE_PROXIMITY':
      case 'NEARBY_ACTIVE_DRIVER':
        return 'Nearest Driver';
      case 'HIGH_COMPLETION_RATE':
        return 'High Completion';
      case 'TOP_RATED_BROKER':
        return 'Top Rated';
      case 'MULTIPLE_VEHICLES_AVAILABLE':
        return 'Fleet Available';
      case 'HIGH_ACCEPTANCE_RATE':
        return 'Fast Response';
      default:
        return 'Verified Fleet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTopPick = recommendation.rank == 1;
    final int scorePercent = (recommendation.recommendationScore * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopPick
              ? Appcolors.primaryBlue.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.15),
          width: isTopPick ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopPick
                ? Appcolors.primaryBlue.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isTopPick ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Rank Badge & Match Score ──────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTopPick
                            ? Appcolors.primaryBlue
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTopPick ? Icons.auto_awesome : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTopPick ? "BEST AI MATCH" : "#${recommendation.rank} RECOMMENDATION",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Appcolors.tertiaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 13,
                            color: Appcolors.tertiaryGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "$scorePercent% Match",
                            style: const TextStyle(
                              color: Appcolors.tertiaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Broker Name & Rating ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Appcolors.primaryBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Appcolors.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.brokerName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                recommendation.brokerRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              if (recommendation.totalReviews > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "(${recommendation.totalReviews} reviews)",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Metrics Row: Distance & Active Drivers ───────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Nearest Driver Distance
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 15,
                              color: Appcolors.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "${recommendation.nearestDriverDistanceKm.toStringAsFixed(1)} km to driver",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 10),
                      // Available fleet count
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 15,
                              color: Appcolors.tertiaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "${recommendation.activeDriversCount} ${recommendation.requiredVehicleType} active",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Explainability Reason Chips ──────────────────────
                if (recommendation.reasonCodes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recommendation.reasonCodes.take(3).map((code) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _formatReason(code),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Action Row ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Select & Continue",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isTopPick ? Appcolors.primaryBlue : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: isTopPick ? Appcolors.primaryBlue : Colors.grey[800],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

