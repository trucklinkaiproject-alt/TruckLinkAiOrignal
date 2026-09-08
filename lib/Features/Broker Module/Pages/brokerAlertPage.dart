import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerChatInboxPage.dart';

class BrokerAlertPage extends StatefulWidget {
  const BrokerAlertPage({super.key});

  @override
  State<BrokerAlertPage> createState() => _BrokerAlertPageState();
}

class _BrokerAlertPageState extends State<BrokerAlertPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isClearing = false;

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final String? brokerId = _auth.currentUser?.uid;
    if (brokerId == null || brokerId.isEmpty) return;

    await NotificationService().markAllAsRead(
      collectionName: "Broker",
      uid: brokerId,
      existingDocs: docs,
    );
  }

  Future<void> _clearAllNotifications(List<QueryDocumentSnapshot> docs) async {
    if (_isClearing) return;
    final String? brokerId = _auth.currentUser?.uid;
    if (brokerId == null || brokerId.isEmpty || docs.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Clear All Notifications",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          "Are you sure you want to permanently clear all notifications for your broker account?",
          style: TextStyle(fontSize: 13.5, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
    });

    try {
      await NotificationService().clearAllNotifications(
        collectionName: "Broker",
        uid: brokerId,
        existingDocs: docs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All notifications cleared."),
            backgroundColor: Appcolors.secondaryPurple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to clear notifications: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  IconData _getIconForType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'new_request':
      case 'request':
        return Icons.mark_email_unread_outlined;
      case 'request_accepted':
      case 'broker_accepted':
      case 'quote_accepted':
        return Icons.verified_outlined;
      case 'quote_rejected':
      case 'driver_rejected':
      case 'driver_offer_rejected':
        return Icons.cancel_outlined;
      case 'driver_assigned':
      case 'driver_offer':
        return Icons.person_pin_circle_outlined;
      case 'driver_accepted':
      case 'driver_offer_accepted':
        return Icons.badge_outlined;
      case 'ride_started':
        return Icons.local_shipping_outlined;
      case 'cargo_picked_up':
      case 'driver_at_pickup':
      case 'driver_at_drop':
        return Icons.location_on_outlined;
      case 'order_completed':
        return Icons.check_circle_outline_rounded;
      case 'new_review':
      case 'review':
        return Icons.star_rate_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'new_request':
      case 'request':
      case 'new_review':
      case 'review':
        return Appcolors.secondaryPurple;
      case 'driver_accepted':
      case 'driver_offer_accepted':
      case 'driver_at_pickup':
      case 'driver_at_drop':
      case 'cargo_picked_up':
      case 'request_accepted':
      case 'quote_accepted':
      case 'order_completed':
        return Appcolors.tertiaryGreen;
      case 'quote_rejected':
      case 'driver_rejected':
      case 'driver_offer_rejected':
        return Colors.redAccent;
      case 'ride_started':
      case 'driver_assigned':
      case 'chat':
        return Appcolors.primaryBlue;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${date.day}/${date.month}/${date.year}";
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String? brokerId = _auth.currentUser?.uid;

    if (brokerId == null || brokerId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: SafeArea(
          child: _BrokerEmptyAlertState(message: "Please log in to view broker notifications."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("Notifications")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final bool hasUnread = docs.any((d) => (d.data() as Map<String, dynamic>)['is_read'] != true);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 22 : width * 0.12;

                return Column(
                  children: [
                    // -------- Header --------
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        15,
                        horizontalPadding,
                        10,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "Broker Alerts",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            TextButton(
                              style: TextButton.styleFrom(
                                overlayColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _markAllAsRead(docs),
                              child: const Text(
                                "Mark read",
                                style: TextStyle(
                                  color: Appcolors.secondaryPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (docs.isNotEmpty)
                            _isClearing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      overlayColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _clearAllNotifications(docs),
                                    child: const Text(
                                      "Clear All",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    ),

                    // -------- Notification List --------
                    Expanded(
                      child: docs.isEmpty
                          ? const _BrokerEmptyAlertState()
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                6,
                                horizontalPadding,
                                24,
                              ),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final String id = docs[index].id;
                                final String title = (data['title'] ?? 'Broker Notification').toString();
                                final String subtitle = (data['body'] ?? data['subtitle'] ?? '').toString();
                                final String time = _formatTimestamp(data['timestamp'] ?? data['created_at']);
                                final String typeStr = (data['type'] ?? 'system').toString();
                                final bool isRead = data['is_read'] == true;

                                final Color color = _getColorForType(typeStr);
                                final IconData icon = _getIconForType(typeStr);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    if (!isRead) {
                                      NotificationService().markAsRead(
                                        collectionName: "Broker",
                                        uid: brokerId,
                                        notificationId: id,
                                      );
                                    }
                                    NotificationNavigationService().handleNotificationTap(data);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      margin: const EdgeInsets.only(left: 8, top: 4),
                                                      decoration: const BoxDecoration(
                                                        color: Appcolors.secondaryPurple,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey[600],
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                time,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey[400],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BrokerEmptyAlertState extends StatelessWidget {
  final String? message;
  const _BrokerEmptyAlertState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Appcolors.secondaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Appcolors.secondaryPurple,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Notifications",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? "You're all caught up! Real-time alerts on requests, trips, and driver assignments will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
