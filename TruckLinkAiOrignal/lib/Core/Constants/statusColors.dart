import 'package:flutter/material.dart';

class StatusConfig {
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
  final IconData icon;

  const StatusConfig({
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
    required this.icon,
  });
}

/// Centralized status color and styling mapping for all 16 workflow states
/// across User, Broker, and Driver modules in TruckLink AI.
class StatusColors {
  // Brand / Semantic Color Palette
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color bluePrimary = Color(0xFF0D6EFD);
  static const Color greenSuccess = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF059669);
  static const Color purpleTransit = Color(0xFF7C3AED);
  static const Color redDanger = Color(0xFFEF4444);
  static const Color redDark = Color(0xFFDC2626);
  static const Color greyNeutral = Color(0xFF6B7280);

  /// Returns the semantic background color for a given status string.
  static Color getColor(String? rawStatus) {
    final status = (rawStatus ?? '').trim().toLowerCase();

    switch (status) {
      // 1. Pending / Waiting states -> Amber
      case 'pending':
      case 'waiting':
      case 'waiting_broker':
      case 'waiting_driver':
      case 'waiting_response':
      case 'requested':
        return amberWarning;

      // 2. Request / Offer / Fare sent -> Blue
      case 'request_sent':
      case 'offer_sent':
      case 'driver_offer_sent':
      case 'fare_offered':
      case 'quote_sent':
        return bluePrimary;

      // 3. Accepted states -> Green
      case 'accepted':
      case 'quote_accepted':
      case 'accepted_by_user':
      case 'accepted_by_broker':
      case 'accepted_by_driver':
      case 'driver_assigned':
      case 'driver_accepted':
        return greenSuccess;

      // 4. In Transit / Active Ride states -> Purple/Blue
      case 'in_transit':
      case 'in_progress':
      case 'on_ride':
      case 'arrived_at_pickup':
      case 'heading_to_drop':
      case 'cargo_collected':
      case 'trip_started':
        return purpleTransit;

      // 5. Completed -> Dark Green
      case 'completed':
      case 'delivered':
      case 'trip_completed':
        return greenDark;

      // 6. Rejected -> Red
      case 'rejected':
      case 'rejected_by_user':
      case 'rejected_by_broker':
      case 'rejected_by_driver':
      case 'quote_rejected':
      case 'declined':
        return redDanger;

      // 7. Cancelled -> Dark Red
      case 'cancelled':
      case 'canceled':
      case 'trip_cancelled':
        return redDark;

      default:
        return greyNeutral;
    }
  }

  /// Returns the human-readable UI label for a given status string.
  static String getLabel(String? rawStatus, {String? role}) {
    final status = (rawStatus ?? '').trim().toLowerCase();

    switch (status) {
      case 'pending':
        return 'Pending';
      case 'fare_offered':
        return role == 'Broker' ? 'Quote Sent' : 'Quote Received';
      case 'driver_offer_sent':
        return role == 'Driver' ? 'New Offer' : 'Driver Offer Sent';
      case 'accepted':
        return 'Accepted';
      case 'accepted_by_user':
        return 'Accepted by User';
      case 'accepted_by_driver':
        return 'Driver Confirmed';
      case 'in_transit':
        return 'In Transit';
      case 'arrived_at_pickup':
        return 'At Pickup';
      case 'heading_to_drop':
        return 'Cargo In Transit';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Returns full UI configuration (color, label, icon, background, border)
  static StatusConfig getStatusConfig(String? rawStatus, {String? role}) {
    final status = (rawStatus ?? '').trim().toLowerCase();
    final color = getColor(status);
    final label = getLabel(status, role: role);

    IconData icon;
    switch (status) {
      case 'pending':
      case 'waiting':
      case 'waiting_broker':
      case 'waiting_driver':
      case 'waiting_response':
      case 'requested':
        icon = Icons.hourglass_top_rounded;
        break;
      case 'request_sent':
      case 'offer_sent':
      case 'driver_offer_sent':
      case 'fare_offered':
      case 'quote_sent':
        icon = Icons.send_rounded;
        break;
      case 'accepted':
      case 'quote_accepted':
      case 'accepted_by_user':
      case 'accepted_by_broker':
      case 'accepted_by_driver':
      case 'driver_assigned':
      case 'driver_accepted':
        icon = Icons.check_circle_rounded;
        break;
      case 'in_transit':
      case 'in_progress':
      case 'on_ride':
      case 'arrived_at_pickup':
      case 'heading_to_drop':
      case 'cargo_collected':
      case 'trip_started':
        icon = Icons.local_shipping_rounded;
        break;
      case 'completed':
      case 'delivered':
      case 'trip_completed':
        icon = Icons.task_alt_rounded;
        break;
      case 'rejected':
      case 'rejected_by_user':
      case 'rejected_by_broker':
      case 'rejected_by_driver':
      case 'quote_rejected':
      case 'declined':
        icon = Icons.cancel_rounded;
        break;
      case 'cancelled':
      case 'canceled':
      case 'trip_cancelled':
        icon = Icons.block_rounded;
        break;
      default:
        icon = Icons.info_outline_rounded;
    }

    return StatusConfig(
      color: color,
      backgroundColor: color.withOpacity(0.08),
      borderColor: color.withOpacity(0.3),
      label: label,
      icon: icon,
    );
  }
}
