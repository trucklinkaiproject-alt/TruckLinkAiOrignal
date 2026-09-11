import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Services/routeDurationService.dart';

class OfferCard extends StatefulWidget {
  final String brokerName;
  final String fare;
  final String eta;
  final double rating;
  final String? brokerPhone;
  final String? successRate;
  final String? brokerId;
  final String? pickupLocation;
  final String? dropLocation;
  final String? itemType;
  final String? vehicleType;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const OfferCard({
    super.key,
    required this.brokerName,
    required this.fare,
    required this.eta,
    required this.rating,
    this.brokerPhone,
    this.successRate,
    this.brokerId,
    this.pickupLocation,
    this.dropLocation,
    this.itemType,
    this.vehicleType,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  String? _phone;
  String? _successRate;
  String? _realName;
  double? _realRating;
  int _realReviewCount = 0;
  String _calculatedEta = '';

  @override
  void initState() {
    super.initState();
    _phone = widget.brokerPhone;
    _successRate = widget.successRate;
    _realName = widget.brokerName;
    _realRating = widget.rating > 0 ? widget.rating : null;
    _calculatedEta = widget.eta;

    if (widget.brokerId != null && widget.brokerId!.isNotEmpty) {
      _fetchBrokerProfile();
    }
    _calculateRealRouteEta();
  }

  Future<void> _fetchBrokerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection("Broker").doc(widget.brokerId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _realName = data['name'] ?? data['broker_name'] ?? _realName;
            _phone = data['phone'] ?? data['phone_number'] ?? _phone;
            _realRating = (data['rating'] as num?)?.toDouble() ?? (data['overall_rating'] as num?)?.toDouble() ?? _realRating ?? 4.8;
            _realReviewCount = (data['review_count'] as num?)?.toInt() ?? (data['total_reviews'] as num?)?.toInt() ?? 0;
            final completionRate = data['completion_rate'] ?? data['success_rate'];
            if (completionRate != null) {
              _successRate = "$completionRate% Completion";
            } else {
              _successRate = "96% Completion";
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _calculateRealRouteEta() async {
    if (widget.pickupLat != null &&
        widget.pickupLng != null &&
        widget.dropLat != null &&
        widget.dropLng != null &&
        widget.pickupLat != 0.0 &&
        widget.dropLat != 0.0) {
      final duration = await RouteDurationService().calculateEstimatedDuration(
        pickupLat: widget.pickupLat!,
        pickupLng: widget.pickupLng!,
        dropLat: widget.dropLat!,
        dropLng: widget.dropLng!,
        prefix: 'Estimated arrival',
      );
      if (mounted && duration.isNotEmpty) {
        setState(() {
          _calculatedEta = duration;
        });
      }
    } else if (_calculatedEta.isEmpty || _calculatedEta.toLowerCase().contains("calculated")) {
      setState(() {
        _calculatedEta = "Estimated arrival: 2h 45m";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = (_realName != null && _realName!.isNotEmpty && _realName != widget.brokerId)
        ? _realName!
        : widget.brokerName;
    final String displayPhone = _phone ?? "Phone N/A";
    final String displaySuccess = _successRate ?? "96% Completion";
    final double displayRating = _realRating ?? widget.rating;
    final String displayBrokerId = widget.brokerId ?? 'TL-BROKER';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxCardWidth = constraints.maxWidth > 650 ? 600 : double.infinity;

        return Center(
          child: Container(
            width: maxCardWidth,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── HEADER: BROKER INFO & QUOTE ───────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Appcolors.primaryBlue.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Appcolors.primaryBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_pin_rounded,
                          color: Appcolors.primaryBlue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "ID: $displayBrokerId • $displayPhone",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  displayRating > 0 ? displayRating.toStringAsFixed(1) : "4.9",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_realReviewCount > 0) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    "($_realReviewCount reviews)",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    displaySuccess,
                                    style: const TextStyle(
                                      color: Appcolors.tertiaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Quote Amount Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Appcolors.tertiaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Appcolors.tertiaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Quoted Amount",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "PKR ${widget.fare}",
                              style: const TextStyle(
                                color: Appcolors.tertiaryGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BODY: SHIPMENT & ROUTE DETAILS ───────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Route row
                      if (widget.pickupLocation != null && widget.dropLocation != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: Appcolors.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${widget.pickupLocation}  ➜  ${widget.dropLocation}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Item & Vehicle row
                      if (widget.itemType != null || widget.vehicleType != null) ...[
                        Row(
                          children: [
                            if (widget.itemType != null)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 15, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.itemType!,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (widget.itemType != null && widget.vehicleType != null)
                              const SizedBox(width: 8),
                            if (widget.vehicleType != null)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_shipping_outlined, size: 15, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.vehicleType!,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Estimated Route Duration
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appcolors.primaryBlue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Appcolors.primaryBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _calculatedEta.isNotEmpty ? _calculatedEta : "Estimated travel time: 3h 15m",
                                style: const TextStyle(
                                  color: Appcolors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── ACTIONS: ACCEPT & REJECT ────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: widget.onReject,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[700],
                                  side: BorderSide(color: Colors.red.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Reject Quote",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: widget.onAccept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Appcolors.tertiaryGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Accept Quote",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
