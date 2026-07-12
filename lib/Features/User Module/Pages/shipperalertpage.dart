

import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/selectionLabel.dart';

/// Simple model for a single notification item.
/// Swap this out for your real model / bloc state whenever you wire this
/// page up to actual data — the UI below only depends on these fields.
class NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType { shipment, broker, driver, system }

class ShipperAlertPage extends StatefulWidget {
  const ShipperAlertPage({super.key});

  @override
  State<ShipperAlertPage> createState() => _ShipperAlertPageState();
}

class _ShipperAlertPageState extends State<ShipperAlertPage> {
  // -------- Mock data for now — replace with real data source --------
  final List<NotificationItem> _todayNotifications = [
    const NotificationItem(
      title: "Shipment Picked Up",
      subtitle: "Your shipment #TL-1042 has been picked up by the driver.",
      time: "10m ago",
      type: NotificationType.shipment,
      isRead: false,
    ),
    const NotificationItem(
      title: "New Broker Offer",
      subtitle: "A broker sent a new quote for your Lahore → Karachi load.",
      time: "1h ago",
      type: NotificationType.broker,
      isRead: false,
    ),
    const NotificationItem(
      title: "Driver Assigned",
      subtitle: "Ali Raza has been assigned as the driver for shipment #TL-1039.",
      time: "3h ago",
      type: NotificationType.driver,
      isRead: true,
    ),
  ];

  final List<NotificationItem> _earlierNotifications = [
    const NotificationItem(
      title: "Delivery Completed",
      subtitle: "Shipment #TL-1021 was delivered and marked complete.",
      time: "Yesterday",
      type: NotificationType.shipment,
      isRead: true,
    ),
    const NotificationItem(
      title: "Account Verified",
      subtitle: "Your account has been successfully verified.",
      time: "2 days ago",
      type: NotificationType.system,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      _todayNotifications.replaceRange(
        0,
        _todayNotifications.length,
        _todayNotifications.map(
          (n) => NotificationItem(
            title: n.title,
            subtitle: n.subtitle,
            time: n.time,
            type: n.type,
            isRead: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAnyUnread =
        _todayNotifications.any((n) => !n.isRead) ||
        _earlierNotifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
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
                    
                      const SizedBox(width: 14),
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
                      if (hasAnyUnread)
                        TextButton(
                          style: TextButton.styleFrom(
                            overlayColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _markAllAsRead,
                          child: Text(
                            "Mark all read",
                            style: TextStyle(
                              color: Appcolors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // -------- List --------
                Expanded(
                  child: (_todayNotifications.isEmpty &&
                          _earlierNotifications.isEmpty)
                      ? const _EmptyState()
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            5,
                            horizontalPadding,
                            24,
                          ),
                          children: [
                            if (_todayNotifications.isNotEmpty) ...[
                              const SectionLabel("Today"),
                              const SizedBox(height: 10),
                              ..._todayNotifications.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationCard(item: n),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_earlierNotifications.isNotEmpty) ...[
                              const SectionLabel("Earlier"),
                              const SizedBox(height: 10),
                              ..._earlierNotifications.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationCard(item: n),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =====================================================================
// UI-only helper widgets below, matching the rest of the app's theme
// (LogInPage, RoleSelectionPage, SignUpPage, Advantages pages, etc).
// =====================================================================


class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const _NotificationCard({required this.item});

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
        return _IconStyle(Icons.person_outline_sharp, Appcolors.tertiaryGreen);
      case NotificationType.system:
        return _IconStyle(Icons.notifications_none_rounded, Colors.grey[700]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
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
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: BoxDecoration(
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
  const _EmptyState();

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
              child: Icon(
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
              "No notifications right now. We'll let you know when something new comes in.",
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