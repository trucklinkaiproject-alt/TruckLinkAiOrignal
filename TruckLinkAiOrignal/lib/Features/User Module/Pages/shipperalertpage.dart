import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.isRead = false,
    this.data,
  });
}

enum NotificationType { shipment, broker, driver, system }

class ShipperAlertPage extends StatefulWidget {
  const ShipperAlertPage({super.key});

  @override
  State<ShipperAlertPage> createState() => _ShipperAlertPageState();
}

class _ShipperAlertPageState extends State<ShipperAlertPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isClearing = false;

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final String? userUid = _auth.currentUser?.uid;
    if (userUid == null || userUid.isEmpty) return;

    await NotificationService().markAllAsRead(
      collectionName: "User",
      uid: userUid,
      existingDocs: docs,
    );
  }

  Future<void> _clearAllNotifications(List<QueryDocumentSnapshot> docs) async {
    if (_isClearing) return;
    final String? userUid = _auth.currentUser?.uid;
    if (userUid == null || userUid.isEmpty || docs.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Clear all notifications?",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          "This will permanently remove all your notifications.",
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
        collectionName: "User",
        uid: userUid,
        existingDocs: docs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All notifications cleared."),
            backgroundColor: Appcolors.primaryBlue,
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

  NotificationType _mapType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'request_accepted':
      case 'broker_offer':
      case 'broker':
      case 'quote_accepted':
      case 'quote_rejected':
        return NotificationType.broker;
      case 'driver_assigned':
      case 'driver_accepted':
      case 'driver_at_pickup':
      case 'driver_at_drop':
      case 'driver':
        return NotificationType.driver;
      case 'ride_started':
      case 'cargo_picked_up':
      case 'order_completed':
      case 'shipment':
      case 'order':
        return NotificationType.shipment;
      default:
        return NotificationType.system;
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
    final String? userUid = _auth.currentUser?.uid;

    if (userUid == null || userUid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: SafeArea(
          child: _EmptyState(message: "Please log in to view notifications."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection("User")
              .doc(userUid)
              .collection("Notifications")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Appcolors.primaryBlue));
            }

            final docs = snapshot.data?.docs ?? [];

            final List<NotificationItem> items = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return NotificationItem(
                id: doc.id,
                title: (data['title'] ?? 'Notification').toString(),
                subtitle: (data['body'] ?? data['subtitle'] ?? '').toString(),
                time: _formatTimestamp(data['timestamp'] ?? data['created_at']),
                type: _mapType((data['type'] ?? 'system').toString()),
                isRead: data['is_read'] == true,
                data: data,
              );
            }).toList();

            final bool hasUnread = items.any((n) => !n.isRead);

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
                          const Expanded(
                            child: Text(
                              "Notifications",
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
                                  color: Appcolors.primaryBlue,
                                  fontWeight: FontWeight.w600,
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

                    // -------- List --------
                    Expanded(
                      child: items.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                5,
                                horizontalPadding,
                                24,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _NotificationCard(
                                  item: items[index],
                                  onTap: () {
                                    if (!items[index].isRead) {
                                      NotificationService().markAsRead(
                                        collectionName: "User",
                                        uid: userUid,
                                        notificationId: items[index].id,
                                      );
                                    }
                                    if (items[index].data != null) {
                                      NotificationNavigationService().handleNotificationTap(items[index].data!);
                                    }
                                  },
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

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;
  const _NotificationCard({required this.item, this.onTap});

  _IconStyle get _style {
    switch (item.type) {
      case NotificationType.shipment:
        return _IconStyle(Icons.local_shipping_outlined, Appcolors.primaryBlue);
      case NotificationType.broker:
        return _IconStyle(
          Icons.interpreter_mode_outlined,
          Appcolors.secondaryPurple,
        );
      case NotificationType.driver:
        return _IconStyle(Icons.badge_outlined, Appcolors.tertiaryGreen);
      case NotificationType.system:
        return _IconStyle(Icons.notifications_none_rounded, Colors.grey[700]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
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
                color: style.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 22),
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
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            color: Appcolors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.time,
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
  }
}

class _IconStyle {
  final IconData icon;
  final Color color;
  _IconStyle(this.icon, this.color);
}

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

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
                color: Appcolors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Appcolors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "You're all caught up",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? "No notifications right now. We'll let you know when something new comes in.",
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