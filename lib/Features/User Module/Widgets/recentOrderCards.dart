
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class RecentOrderCard extends StatelessWidget {
  final String orderNumber;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final String status;

  const RecentOrderCard({
    required this.orderNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.status,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case "completed":
      case "delivered":
      case "accepted":
        return Appcolors.tertiaryGreen;
      case "in progress":
      case "active":
        return Colors.orange;
      case "cancelled":
        return Colors.redAccent;
      case "pending":
        return Colors.yellowAccent;
      case "rejected":
        return Colors.redAccent;
      default:
        return Appcolors.primaryBlue; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Order #$orderNumber",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 7, color: Appcolors.primaryBlue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  pickupLocation,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward,
                  size: 13,
                  color: Colors.grey[400],
                ),
              ),
              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  dropLocation,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
      ),
    );
  }
}