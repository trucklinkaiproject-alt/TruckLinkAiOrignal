import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';

class DriverAlertPage extends StatefulWidget {
  const DriverAlertPage({super.key});

  @override
  State<DriverAlertPage> createState() => _DriverAlertPageState();
}

class _DriverAlertPageState extends State<DriverAlertPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isClearing = false;

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final String? driverUid = _auth.currentUser?.uid;
    if (driverUid == null || driverUid.isEmpty) return;

    await NotificationService().markAllAsRead(
      collectionName: "Driver",
      uid: driverUid,
      existingDocs: docs,
    );
  }

  Future<void> _clearAllNotifications(List<QueryDocumentSnapshot> docs) async {
    if (_isClearing) return;
    final String? driverUid = _auth.currentUser?.uid;
    if (driverUid == null || driverUid.isEmpty || docs.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Clear all notifications?",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          "This will permanently delete all driver alerts.",
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
        collectionName: "Driver",
        uid: driverUid,
        existingDocs: docs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All driver alerts cleared."),
            backgroundColor: Appcolors.tertiaryGreen,
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
      case 'driver_assigned':
      case 'new_shipment':
        return Icons.local_shipping_rounded;
      case 'broker_offer':
      case 'counter_quote':
      case 'fare_offered':
        return Icons.payments_rounded;
      case 'request_accepted':
      case 'offer_accepted':
      case 'driver_accepted':
        return Icons.check_circle_rounded;
      case 'request_rejected':
      case 'offer_rejected':
      case 'driver_rejected':
        return Icons.cancel_rounded;
      case 'chat':
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'trip_started':
      case 'in_transit':
      case 'cargo_collected':
        return Icons.navigation_rounded;
      case 'trip_completed':
      case 'delivered':
        return Icons.task_alt_rounded;
      case 'admin':
      case 'admin_alert':
        return Icons.security_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'driver_assigned':
      case 'new_shipment':
      case 'chat':
      case 'new_message':
        return Appcolors.primaryBlue;
      case 'broker_offer':
      case 'counter_quote':
      case 'fare_offered':
        return StatusColors.amberDark;
      case 'request_accepted':
      case 'offer_accepted':
      case 'driver_accepted':
      case 'trip_completed':
      case 'delivered':
        return Appcolors.tertiaryGreen;
      case 'request_rejected':
      case 'offer_rejected':
      case 'driver_rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'trip_started':
      case 'in_transit':
      case 'cargo_collected':
        return StatusColors.purpleTransit;
      case 'admin':
      case 'admin_alert':
        return Colors.deepPurple;
      default:
        return Appcolors.tertiaryGreen;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return "Recently";
    }

    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat("dd MMM, hh:mm a").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String currentDriverUid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Driver Alerts",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: currentDriverUid.isNotEmpty
                ? _firestore
                    .collection("Driver")
                    .doc(currentDriverUid)
                    .collection("Notifications")
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final unreadCount = docs.where((d) => (d.data() as Map<String, dynamic>)['is_read'] != true).length;

              if (docs.isEmpty) return const SizedBox.shrink();

              return Row(
                children: [
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () => _markAllAsRead(docs),
                      child: const Text(
                        "Mark all read",
                        style: TextStyle(
                          color: Appcolors.tertiaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
                    tooltip: "Clear all alerts",
                    onPressed: () => _clearAllNotifications(docs),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: currentDriverUid.isEmpty
          ? const Center(child: Text("Please log in to view alerts."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("Driver")
                  .doc(currentDriverUid)
                  .collection("Notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Appcolors.tertiaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "Error loading notifications: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Appcolors.tertiaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_off_outlined,
                            size: 40,
                            color: Appcolors.tertiaryGreen,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "No Alerts Yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Driver assignments, offers, and trip alerts will appear here.",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final bool isMobile = width < 600;
                    final double horizontalPadding = isMobile ? 16 : width * 0.12;

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final String notifId = (data['id'] ?? doc.id).toString();
                        final String title = (data['title'] ?? 'Notification').toString();
                        final String body = (data['body'] ?? data['subtitle'] ?? '').toString();
                        final String type = (data['type'] ?? 'general').toString();
                        final bool isRead = data['is_read'] == true;
                        final String timeStr = _formatTimestamp(data['timestamp'] ?? data['created_at']);
                        final IconData icon = _getIconForType(type);
                        final Color typeColor = _getColorForType(type);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              // Mark as read immediately
                              if (!isRead) {
                                await NotificationService().markAsRead(
                                  collectionName: "Driver",
                                  uid: currentDriverUid,
                                  notificationId: notifId,
                                );
                              }

                              // Deep link navigation
                              await NotificationNavigationService().handleNotificationTap(data);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? Colors.grey.shade200 : Appcolors.tertiaryGreen.withOpacity(0.4),
                                  width: isRead ? 1.0 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isRead ? 0.03 : 0.06),
                                    blurRadius: isRead ? 6 : 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: typeColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
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
                                                  fontSize: 14.5,
                                                  fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(left: 6),
                                                decoration: const BoxDecoration(
                                                  color: Appcolors.tertiaryGreen,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          body,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isRead ? Colors.grey[600] : Colors.black87,
                                            height: 1.35,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
