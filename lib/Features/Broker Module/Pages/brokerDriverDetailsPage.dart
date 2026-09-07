import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';

class BrokerDriverDetailsPage extends StatelessWidget {
  final Map<String, dynamic> driverData;

  const BrokerDriverDetailsPage({super.key, required this.driverData});

  void _callDriver(String phoneNumber, BuildContext context) {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver phone number not available.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Contact Driver", style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Driver Phone Number:"),
            const SizedBox(height: 8),
            SelectableText(
              phoneNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Appcolors.secondaryPurple,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.secondaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Phone number copied to clipboard!"),
                  backgroundColor: Appcolors.tertiaryGreen,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
            label: const Text("Copy Number", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String driverId = (driverData['driver_id'] ?? driverData['driverId'] ?? driverData['id'] ?? '').toString();
    final String currentBrokerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection("Driver").doc(driverId).snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic> liveData = Map<String, dynamic>.from(driverData);
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              liveData = snapshot.data!.data() as Map<String, dynamic>? ?? driverData;
            }

            final String name = (liveData['name'] ?? liveData['driver_name'] ?? 'Driver').toString();
            final String email = (liveData['email'] ?? 'Not provided').toString();
            final String phone = (liveData['phone'] ?? liveData['phone_number'] ?? 'N/A').toString();
            final String rawAvail = (liveData['availability_status'] ?? (liveData['vehicle_available'] == false ? 'offline' : 'online')).toString().toLowerCase();
            final vehicleMap = (liveData['vehicle'] is Map) ? liveData['vehicle'] as Map : null;
            final truckMap = (liveData['truckDetails'] is Map) ? liveData['truckDetails'] as Map : null;

            final rawType = (liveData['vehicle_type'] ??
                    liveData['vehicleType'] ??
                    liveData['truck_type'] ??
                    liveData['truckType'] ??
                    liveData['vehicle'] ??
                    vehicleMap?['type'] ??
                    vehicleMap?['vehicle_type'] ??
                    truckMap?['vehicleType'] ??
                    truckMap?['type'])
                ?.toString()
                .trim();

            final rawNumber = (liveData['vehicle_number'] ??
                    liveData['vehicleNumber'] ??
                    liveData['truck_id'] ??
                    liveData['truckId'] ??
                    liveData['license_plate'] ??
                    liveData['licensePlate'] ??
                    liveData['plate_number'] ??
                    liveData['plateNumber'] ??
                    vehicleMap?['number'] ??
                    vehicleMap?['vehicle_number'] ??
                    truckMap?['vehicleNumber'] ??
                    truckMap?['number'])
                ?.toString()
                .trim();

            final String vehicleType = (rawType != null && rawType.isNotEmpty && rawType.toLowerCase() != 'null') ? rawType : 'Not specified';
            final String vehicleNumber = (rawNumber != null && rawNumber.isNotEmpty && rawNumber.toLowerCase() != 'null') ? rawNumber : 'Not specified';
            final String trailerCapacity = (liveData['capacity'] ?? liveData['vehicle_capacity'] ?? '').toString();

            final double rating = (liveData['rating'] as num?)?.toDouble() ?? (liveData['driver_rating'] as num?)?.toDouble() ?? 5.0;
            final int totalTrips = (liveData['total_trips'] as num?)?.toInt() ?? 0;
            final int completedTrips = (liveData['completed_trips'] as num?)?.toInt() ?? 0;
            final int reviewsCount = (liveData['total_reviews'] as num?)?.toInt() ?? (liveData['reviews'] as num?)?.toInt() ?? 0;

            String statusLabel = "Online";
            Color statusColor = Appcolors.tertiaryGreen;
            if (rawAvail == 'on_ride' || rawAvail == 'onride') {
              statusLabel = "On Ride";
              statusColor = Colors.orange;
            } else if (rawAvail == 'offline') {
              statusLabel = "Offline";
              statusColor = Colors.grey;
            }

            final initials = name
                .trim()
                .split(RegExp(r"\s+"))
                .map((e) => e.isNotEmpty ? e[0] : "")
                .take(2)
                .join()
                .toUpperCase();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 20 : width * 0.12;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 15, horizontalPadding, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Header --------
                      Row(
                        children: [
                          BackArrowButton(onTap: () => Navigator.pop(context)),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "Driver Profile",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // -------- Profile Identity Card --------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Appcolors.secondaryPurple.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials.isNotEmpty ? initials : "D",
                                style: const TextStyle(
                                  color: Appcolors.secondaryPurple,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Action Buttons (Call & Chat)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Appcolors.primaryBlue,
                                        side: BorderSide(color: Appcolors.primaryBlue.withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                      onPressed: () => _callDriver(phone, context),
                                      icon: const Icon(Icons.call_rounded, size: 18),
                                      label: const Text(
                                        "Call",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Appcolors.secondaryPurple,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                      onPressed: () {
                                        final String chatId = getDeterministicChatId(currentBrokerId, driverId);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BrokerChatPage(
                                              chatId: chatId,
                                              receiverId: driverId,
                                              receiverName: name,
                                              receiverRole: 'Driver',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 17),
                                      label: const Text(
                                        "Chat",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // -------- Stats Strip --------
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber[700]!,
                              value: rating > 0 ? rating.toStringAsFixed(1) : "5.0",
                              label: "Rating ($reviewsCount)",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              iconColor: Appcolors.tertiaryGreen,
                              value: completedTrips.toString(),
                              label: "Completed",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_shipping_rounded,
                              iconColor: Appcolors.primaryBlue,
                              value: totalTrips.toString(),
                              label: "Total Trips",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // -------- Vehicle Information Card --------
                      const Text(
                        "Vehicle Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _vehicleInfoRow(Icons.directions_bus_rounded, "Vehicle Type", vehicleType),
                            const Divider(height: 22, thickness: 0.8),
                            _vehicleInfoRow(Icons.pin_rounded, "Vehicle Registration #", vehicleNumber),
                            if (trailerCapacity.isNotEmpty) ...[
                              const Divider(height: 22, thickness: 0.8),
                              _vehicleInfoRow(Icons.scale_rounded, "Load Capacity", "$trailerCapacity kg"),
                            ],
                            const Divider(height: 22, thickness: 0.8),
                            _vehicleInfoRow(Icons.badge_outlined, "Driver ID", driverId.isNotEmpty ? driverId : "N/A"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -------- Driver Reviews Stream --------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Customer & Broker Reviews",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("Driver")
                                .doc(driverId)
                                .collection("Reviews")
                                .snapshots(),
                            builder: (context, revSnap) {
                              final count = revSnap.data?.docs.length ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Appcolors.secondaryPurple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$count Total",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Appcolors.secondaryPurple,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("Driver")
                            .doc(driverId)
                            .collection("Reviews")
                            .orderBy('created_at', descending: true)
                            .snapshots(),
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
                              ),
                            );
                          }

                          final docs = reviewSnapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
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
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 36, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No reviews yet for this driver",
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Reviews submitted after completed deliveries will appear here.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final rData = docs[index].data() as Map<String, dynamic>;
                              final String reviewerName = (rData['reviewer_name'] ?? 'Verified Shipper').toString();
                              final String reviewerRole = (rData['reviewer_role'] ?? 'User').toString().toUpperCase();
                              final double revRating = (rData['rating'] as num?)?.toDouble() ?? 5.0;
                              final String comment = (rData['comment'] ?? '').toString();
                              final String orderId = (rData['order_id'] ?? '').toString();

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Appcolors.secondaryPurple.withOpacity(0.12),
                                          child: Text(
                                            reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : "U",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Appcolors.secondaryPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reviewerName,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                "$reviewerRole${orderId.isNotEmpty ? ' • Order #$orderId' : ''}",
                                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(5, (sIdx) {
                                            return Icon(
                                              sIdx < revRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                              size: 16,
                                              color: Colors.amber[700],
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        comment,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.grey[800],
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _vehicleInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Appcolors.secondaryPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
