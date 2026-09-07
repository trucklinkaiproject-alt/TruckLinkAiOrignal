import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerAlertPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerChatInboxPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerDriverNetworkPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerOrderPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/widgets/brokerincomingreqcontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';

class BrokerHomePage extends StatefulWidget {
  const BrokerHomePage({super.key});

  @override
  State<BrokerHomePage> createState() => _BrokerHomePageState();
}

class _BrokerHomePageState extends State<BrokerHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokerCubit>().fetchUserData();
      context.read<BrokerCubit>().fetchIncomingReq();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentBrokerId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: currentBrokerId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection("chats")
                .where("participants", arrayContains: currentBrokerId)
                .snapshots()
            : const Stream.empty(),
        builder: (context, chatSnap) {
          int totalUnreadChats = 0;
          if (chatSnap.hasData && chatSnap.data != null) {
            for (var doc in chatSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final int unread =
                  (data['unreadCount_$currentBrokerId'] as num?)?.toInt() ?? 0;
              if (unread > 0) {
                totalUnreadChats += unread;
              }
            }
          }

          return FloatingActionButton.extended(
            backgroundColor: Appcolors.secondaryPurple,
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BrokerChatInboxPage(),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white, size: 20),
                if (totalUnreadChats > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 14),
                      child: Text(
                        totalUnreadChats > 99 ? '99+' : '$totalUnreadChats',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: Text(
              totalUnreadChats > 0 ? "Chat ($totalUnreadChats)" : "Messages",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 20 : width * 0.12;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Dashboard Top Header --------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Appcolors.secondaryPurple,
                          Appcolors.secondaryPurple.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Appcolors.secondaryPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<BrokerCubit, BrokerState>(
                                builder: (context, state) {
                                  final name = state is BrokerLoadedState
                                      ? state.userData
                                      : "Broker";
                                  return Text(
                                    "Hello, $name 👋",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                "Broker Command Center",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification Bell with Real Unread Badge
                        StreamBuilder<QuerySnapshot>(
                          stream: currentBrokerId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection("Broker")
                                  .doc(currentBrokerId)
                                  .collection("Notifications")
                                  .where("is_read", isEqualTo: false)
                                  .snapshots()
                              : const Stream.empty(),
                          builder: (context, notifSnap) {
                            final unreadCount =
                                notifSnap.data?.docs.length ?? 0;
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const BrokerAlertPage()),
                                );
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                              minWidth: 16, minHeight: 16),
                                          child: Text(
                                            unreadCount > 9
                                                ? '9+'
                                                : '$unreadCount',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Real-Time Broker Availability Control (Online / Offline)
                        StreamBuilder<DocumentSnapshot>(
                          stream: currentBrokerId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection("Broker")
                                  .doc(currentBrokerId)
                                  .snapshots()
                              : const Stream.empty(),
                          builder: (context, bSnap) {
                            final bData = bSnap.data?.data() as Map<String, dynamic>? ?? {};
                            final String currentStatus = (bData['availability_status'] ?? bData['status'] ?? 'online')
                                .toString()
                                .toLowerCase();
                            final bool isOnline = currentStatus != 'offline';

                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final newStatus = isOnline ? 'offline' : 'online';
                                await context.read<BrokerCubit>().updateBrokerAvailability(newStatus);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newStatus == 'online'
                                            ? "You are now Online & Active ✓"
                                            : "You are now Offline",
                                      ),
                                      backgroundColor: newStatus == 'online'
                                          ? Appcolors.tertiaryGreen
                                          : Colors.grey[800],
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? Appcolors.tertiaryGreen
                                      : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isOnline
                                              ? Appcolors.tertiaryGreen
                                              : Colors.black)
                                          .withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.white : Colors.grey[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOnline ? "Online" : "Offline",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 22 : 28),

                  // -------- Live Real-Time Firebase Metrics --------
                  StreamBuilder<QuerySnapshot>(
                    stream: currentBrokerId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection("Broker")
                            .doc(currentBrokerId)
                            .collection("IncomingRequests")
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      int newRequestsCount = 0;
                      int activeOrdersCount = 0;
                      int completedOrdersCount = 0;
                      List<Map<String, dynamic>> pendingList = [];

                      if (snapshot.hasData && snapshot.data != null) {
                        final docs = snapshot.data!.docs;

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final item = {
                            "orderId": doc.id,
                            ...data,
                          };
                          final status = (data["status"] ?? "pending")
                              .toString()
                              .toLowerCase();

                          if (status == "pending") {
                            newRequestsCount++;
                            pendingList.add(item);
                          } else if ([
                            "accepted",
                            "accepted_by_driver",
                            "driver_offer_sent",
                            "in_progress",
                            "in_transit",
                          ].contains(status)) {
                            activeOrdersCount++;
                          } else if (["completed", "delivered"]
                              .contains(status)) {
                            completedOrdersCount++;
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stat Cards Row with fixed flexible layout (0 pixel overflow)
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: newRequestsCount.toString(),
                                  label: "New Requests",
                                  icon: Icons.mark_email_unread_rounded,
                                  color: Appcolors.secondaryPurple,
                                  isLoading:
                                      snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !snapshot.hasData,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  value: activeOrdersCount.toString(),
                                  label: "Active Orders",
                                  icon: Icons.local_shipping_rounded,
                                  color: Colors.orange,
                                  isLoading:
                                      snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !snapshot.hasData,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  value: completedOrdersCount.toString(),
                                  label: "Completed",
                                  icon: Icons.check_circle_rounded,
                                  color: Appcolors.tertiaryGreen,
                                  isLoading:
                                      snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !snapshot.hasData,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isMobile ? 24 : 30),

                          // -------- Incoming Requests Feed --------
                          Row(
                            children: [
                              const Text(
                                "New Requests",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Appcolors.secondaryPurple
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${pendingList.length} Pending",
                                  style: TextStyle(
                                    color: Appcolors.secondaryPurple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BrokerOrderPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    color: Appcolors.secondaryPurple,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                              !snapshot.hasData)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (pendingList.isEmpty)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 36),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Appcolors.secondaryPurple
                                          .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inbox_outlined,
                                      size: 36,
                                      color: Appcolors.secondaryPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "No Pending Requests",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Incoming requests from shippers will appear here in real time",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingList.length,
                              itemBuilder: (context, index) {
                                final reversedIndex =
                                    pendingList.length - 1 - index;
                                final request = pendingList[reversedIndex];

                                return BrokerIcomingReqContainer(
                                  orderNumber:
                                      (request["orderNo"] ?? "").toString(),
                                  pickupLocation:
                                      (request["pickupCity"] ?? "").toString(),
                                  dropLocation:
                                      (request["dropCity"] ?? "").toString(),
                                  date: (request["createdAt"] ??
                                          request["date"] ??
                                          "")
                                      .toString(),
                                  status: (request["status"] ?? "pending")
                                      .toString(),
                                  weight: request["weight"] is int
                                      ? request["weight"]
                                      : int.tryParse(
                                              request["weight"].toString()) ??
                                          0,
                                  itemType:
                                      (request["itemType"] ?? "").toString(),
                                  orderId:
                                      (request["orderId"] ?? "").toString(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          orderReqData: request,
                                        ),
                                      ),
                                    );
                                  },
                                  onSubmitQuote: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          orderReqData: request,
                                        ),
                                      ),
                                    );
                                  },
                                  onReject: () async {
                                    await context
                                        .read<BrokerCubit>()
                                        .rejectRequest(request);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Request #${request['orderNo'] ?? ''} Rejected"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}


