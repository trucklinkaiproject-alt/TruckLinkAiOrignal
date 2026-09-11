import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';

class BrokerIcomingReqContainer extends StatelessWidget {
  const BrokerIcomingReqContainer({
    super.key,
    required this.orderNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.status,
    required this.weight,
    required this.itemType,
    this.vehicleType,
    this.onTap,
    required this.orderId,
    this.onAccept,
    this.onSubmitQuote,
    this.onReject,
  });

  final String orderNumber;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final int weight;
  final String itemType;
  final String? vehicleType;
  final String status;
  final String orderId;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onSubmitQuote;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final quoteAction = onSubmitQuote ?? onAccept;
    final Color statusColor = StatusColors.getColor(status);
    final String statusLabel = StatusColors.getLabel(status, role: 'Broker');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- Order # + Status badge --------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Order #$orderNumber",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: statusColor.withOpacity(0.12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // -------- CITY-LEVEL ROUTE --------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trip_origin_rounded,
                        size: 13,
                        color: Appcolors.secondaryPurple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pickupLocation.isNotEmpty ? pickupLocation : "Pickup",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dropLocation.isNotEmpty ? dropLocation : "Drop",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // -------- Weight / Item / Vehicle / Date --------
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      itemType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.scale_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "$weight kg",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    if (vehicleType != null && vehicleType!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        vehicleType!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),

                // -------- Single-Tap Action Buttons --------
                if (quoteAction != null || onReject != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onReject != null)
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(color: Colors.red.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: onReject,
                              child: const Text(
                                "Reject",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      if (quoteAction != null && onReject != null) const SizedBox(width: 10),
                      if (quoteAction != null)
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.secondaryPurple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: quoteAction,
                              child: const Text(
                                "Submit Quote",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
