import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';

class OrderContainer extends StatelessWidget {
  const OrderContainer({
    super.key,
    required this.onTap,
    required this.orderNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.status,
  });

  final String orderNumber;
  final VoidCallback onTap;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color clr = StatusColors.getColor(status);
    final String label = StatusColors.getLabel(status, role: 'User');

    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    final double containerHeight = isMobile
        ? 94
        : isTablet
            ? 104
            : 118;

    final double titleSize = isMobile
        ? 14
        : isTablet
            ? 16
            : 18;

    final double textSize = isMobile
        ? 12
        : isTablet
            ? 13.5
            : 15;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        width: double.infinity,
        height: containerHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Order #$orderNumber",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: clr.withOpacity(0.12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: clr,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 11 : 12.5,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "$pickupLocation → $dropLocation",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              date,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: textSize * 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
