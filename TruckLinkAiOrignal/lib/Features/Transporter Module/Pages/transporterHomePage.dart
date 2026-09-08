import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverOrdersPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverSettingsPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverTruckDetailsPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/findBrokerPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Services/driverLocationService.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverState.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverOffersBloc/driverOffersCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverOffersBloc/driverOffersState.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/userChatInboxPage.dart';

class TransporterHomePage extends StatefulWidget {
  const TransporterHomePage({super.key});

  @override
  State<TransporterHomePage> createState() => _TransporterHomePageState();
}

class _TransporterHomePageState extends State<TransporterHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverCubit>().fetchDriverData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentDriverUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: currentDriverUid.isNotEmpty
            ? FirebaseFirestore.instance
                .collection("chats")
                .where("participants", arrayContains: currentDriverUid)
                .snapshots()
            : const Stream.empty(),
        builder: (context, chatSnap) {
          int totalUnreadChats = 0;
          if (chatSnap.hasData && chatSnap.data != null) {
            for (var doc in chatSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final int unread =
                  (data['unreadCount_$currentDriverUid'] as num?)?.toInt() ?? 0;
              if (unread > 0) {
                totalUnreadChats += unread;
              }
            }
          }

          return FloatingActionButton.extended(
            backgroundColor: Appcolors.tertiaryGreen,
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserChatInboxPage(),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                if (totalUnreadChats > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalUnreadChats > 99 ? '99+' : '$totalUnreadChats',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: Text(
              totalUnreadChats > 0 ? "Chats ($totalUnreadChats)" : "Chats",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
      body: BlocListener<DriverCubit, DriverState>(
        listener: (context, state) {
          if (state is DriverLoadedState) {
            final driver = state.driver;
            if (!driver.isTruckDetailsComplete) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverTruckDetailsPage(isFirstLogin: true),
                ),
              );
            }
          }
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeDashboard(context),
            const DriverOrdersPage(),
            const DriverSettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Appcolors.tertiaryGreen,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isMobile = width < 600;
          final double horizontalPadding = isMobile ? 18 : width * 0.12;

          return BlocBuilder<DriverCubit, DriverState>(
            builder: (context, state) {
              if (state is DriverLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Appcolors.tertiaryGreen,
                  ),
                );
              }

              if (state is DriverErrorState) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                        const SizedBox(height: 12),
                        Text(
                          "Error: ${state.errorMessage}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DriverLoadedState) {
                final driver = state.driver;

                return BlocListener<DriverCubit, DriverState>(
                  listenWhen: (previous, current) => current is DriverLoadedState,
                  listener: (context, driverState) {
                    if (driverState is DriverLoadedState) {
                      context.read<DriverOffersCubit>().listenToOffers(
                        driverId: driverState.driver.driverId,
                      );
                    }
                  },
                  child: BlocConsumer<DriverOffersCubit, DriverOffersState>(
                    listener: (context, offersState) {
                      if (offersState is DriverOffersActionSuccessState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(offersState.message),
                            backgroundColor: Appcolors.tertiaryGreen,
                          ),
                        );
                      }
                      if (offersState is DriverOffersErrorState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(offersState.errorMessage),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    },
                    builder: (context, offersState) {
                      final activeRide = context.read<DriverOffersCubit>().activeRide;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          15,
                          horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // -------- Header --------
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Appcolors.tertiaryGreen,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driver.name.isNotEmpty
                                            ? "Hello, ${driver.name} !"
                                            : "Hello, Driver !",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        activeRide != null ? "Active Ride in Progress" : "Driver Dashboard",
                                        style: TextStyle(
                                          color: activeRide != null ? Appcolors.tertiaryGreen : Colors.grey[600],
                                          fontSize: 12.5,
                                          fontWeight: activeRide != null ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Driver Availability Toggle / Status Badge
                                Builder(
                                  builder: (context) {
                                    if (activeRide != null) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.directions_bus, size: 13, color: Colors.orange),
                                            SizedBox(width: 4),
                                            Text(
                                              "On Ride",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final bool isOnline = driver.isOnline;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          final newStatus = isOnline ? 'offline' : 'online';
                                          context.read<DriverCubit>().updateDriverAvailability(newStatus);
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isOnline
                                                ? Appcolors.tertiaryGreen.withOpacity(0.12)
                                                : Colors.grey.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isOnline
                                                  ? Appcolors.tertiaryGreen.withOpacity(0.4)
                                                  : Colors.grey.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isOnline ? Appcolors.tertiaryGreen : Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                isOnline ? "Online" : "Offline",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: isOnline ? Appcolors.tertiaryGreen : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: isMobile ? 18 : 24),

                            // =======================================================
                            // 1. ACTIVE RIDE SECTION (Primary Focus when Ride Active)
                            // =======================================================
                            if (activeRide != null) ...[
                              _ActiveRideCard(
                                ride: activeRide,
                                driver: driver,
                              ),
                              SizedBox(height: isMobile ? 22 : 28),
                            ],

                            // =======================================================
                            // 2. DRIVER PROFILE & BROKER NETWORK SECTION
                            // =======================================================
                            if (activeRide == null) ...[
                              _DriverProfileCard(
                                driver: driver,
                                locationStatus: state.locationStatus,
                              ),
                              SizedBox(height: isMobile ? 20 : 26),

                              const Text(
                                "Broker Network Status",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Builder(
                                builder: (_) {
                                  switch (state.relationshipStatus) {
                                    case DriverBrokerRelationshipStatus.noBroker:
                                      return _NoBrokerStateWidget(
                                        isTruckDetailsComplete: driver.isTruckDetailsComplete,
                                        onFindBroker: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const FindBrokerPage(),
                                            ),
                                          );
                                        },
                                        onAddTruckDetails: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const DriverTruckDetailsPage(),
                                            ),
                                          );
                                        },
                                      );
                                    case DriverBrokerRelationshipStatus.requestPending:
                                      return _RequestPendingStateWidget(
                                        brokerId: state.targetBrokerId ?? "Pending",
                                        brokerName: state.targetBrokerName,
                                      );
                                    case DriverBrokerRelationshipStatus.requestRejected:
                                      return _RequestRejectedStateWidget(
                                        brokerName: state.targetBrokerName,
                                        onFindBroker: () {
                                          if (!driver.isTruckDetailsComplete) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Please complete your truck details before joining a Broker."),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const DriverTruckDetailsPage(),
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const FindBrokerPage(),
                                            ),
                                          );
                                        },
                                      );
                                    case DriverBrokerRelationshipStatus.connected:
                                      return _ConnectedBrokerStateWidget(
                                        brokerId: driver.brokerId ?? state.targetBrokerId ?? "",
                                        brokerName: state.brokerName ?? state.targetBrokerName,
                                      );
                                  }
                                },
                              ),

                              SizedBox(height: isMobile ? 22 : 28),

                              // =======================================================
                              // 3. INCOMING REQUESTS SECTION (With Accept & Reject)
                              // =======================================================
                              _IncomingRequestsSection(
                                offers: offersState is DriverOffersLoadedState ? offersState.offers : [],
                                driverId: driver.driverId,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              }

              return const Center(
                child: CircularProgressIndicator(
                  color: Appcolors.tertiaryGreen,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================================
// Active Ride Card (Displayed prominently on Driver Home after Accept)
// =====================================================================
class _ActiveRideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final dynamic driver;

  const _ActiveRideCard({required this.ride, required this.driver});

  @override
  Widget build(BuildContext context) {
    final String orderNo = (ride['order_no'] ?? ride['order_id'] ?? '').toString();
    // ignore: unused_local_variable
    final String orderId = (ride['order_id'] ?? ride['orderNo'] ?? '').toString();
    final String brokerName = (ride['broker_name'] ?? 'Broker').toString();
    final String brokerId = (ride['broker_id'] ?? '').toString();
    final String pickupCity = (ride['pickup_city'] ?? 'Pickup City').toString();
    final String dropCity = (ride['drop_city'] ?? 'Drop City').toString();
    final String pickupComp = (ride['pickup_comp'] ?? '').toString();
    final String dropComp = (ride['drop_comp'] ?? '').toString();
    final String itemType = (ride['item_type'] ?? 'General Cargo').toString();
    final String weight = (ride['weight'] ?? 0).toString();
    final String fare = (ride['fare'] ?? '0').toString();
    final String rawStatus = (ride['status'] ?? 'accepted_by_driver').toString().toLowerCase();
    final String ridePhase = (ride['ride_phase'] ?? '').toString();

    final bool isAcceptedAwaitingStart = rawStatus == 'accepted_by_driver' || rawStatus == 'accepted';
    final bool isTracking = DriverLocationService().isTracking;

    String statusTitle = "RIDE ACCEPTED";
    Color statusColor = Appcolors.tertiaryGreen;
    if (rawStatus == 'in_transit' || rawStatus == 'in_progress') {
      if (ridePhase == 'at_pickup') {
        statusTitle = "ARRIVED AT PICKUP";
        statusColor = Colors.orange;
      } else if (ridePhase == 'heading_to_drop') {
        statusTitle = "IN TRANSIT TO DESTINATION";
        statusColor = Appcolors.primaryBlue;
      } else if (ridePhase == 'at_drop') {
        statusTitle = "ARRIVED AT DROP DESTINATION";
        statusColor = Colors.purple;
      } else {
        statusTitle = "IN TRANSIT TO PICKUP";
        statusColor = Appcolors.primaryBlue;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Top Row: Order # + Live Tag --------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Active Ride #$orderNo",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "PKR $fare • Broker: $brokerName",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
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
                      statusTitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          const SizedBox(height: 14),

          // -------- Route Details --------
          Row(
            children: [
              const Icon(Icons.circle, size: 12, color: Appcolors.tertiaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Pickup: $pickupCity ${pickupComp.isNotEmpty ? '($pickupComp)' : ''}",
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(thickness: 1.5, color: Colors.grey[300]),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Drop: $dropCity ${dropComp.isNotEmpty ? '($dropComp)' : ''}",
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -------- Cargo Info Chips --------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(Icons.inventory_2_outlined, "Cargo", itemType),
                _infoChip(Icons.fitness_center_outlined, "Weight", "$weight kg"),
                _infoChip(
                  Icons.gps_fixed_rounded,
                  "GPS Tracking",
                  isTracking ? "Active" : (isAcceptedAwaitingStart ? "Ready" : "Active"),
                  color: isTracking ? Appcolors.tertiaryGreen : Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // -------- Chat & Live Map Tracking Actions --------
          Row(
            children: [
              if (brokerId.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Appcolors.secondaryPurple,
                        side: BorderSide(color: Appcolors.secondaryPurple.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () {
                        final String driverUid = driver.driverId;
                        final String chatId = getDeterministicChatId(driverUid, brokerId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BrokerChatPage(
                              chatId: chatId,
                              receiverId: brokerId,
                              receiverName: brokerName,
                              receiverRole: 'Broker',
                              orderId: orderNo,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text(
                        "Chat Broker",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              if (brokerId.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Appcolors.primaryBlue,
                      side: BorderSide(color: Appcolors.primaryBlue.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingPage(orderStatusDetail: ride),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: const Text(
                      "Live Map",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -------- Primary Flow Action Button --------
          if (isAcceptedAwaitingStart)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: () {
                  context.read<DriverOffersCubit>().startRide(offer: ride);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                label: const Text(
                  "START RIDE",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (ridePhase != 'heading_to_drop')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.tertiaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        context.read<DriverOffersCubit>().confirmCargoPickedUp(offer: ride);
                      },
                      icon: const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        "Cargo Loaded",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        _showCompleteDialog(context, ride);
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        "COMPLETE",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: () {
                  _showCompleteDialog(context, ride);
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                label: const Text(
                  "COMPLETE DELIVERY",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Complete Delivery?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "Are you sure you have completed the drop-off? This will finalize the shipment, stop GPS tracking, and notify both the broker and user.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DriverOffersCubit>().completeRide(offer: ride);
            },
            child: const Text("Confirm Complete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String title, String val, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 17, color: color ?? Colors.grey[700]),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Incoming Requests Section Widget (With Accept / Reject on Home Card)
// =====================================================================
class _IncomingRequestsSection extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final String driverId;

  const _IncomingRequestsSection({required this.offers, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final incomingList = offers.where((offer) {
      final status = (offer['status'] ?? 'pending').toString().toLowerCase();
      return status == 'pending' || status == 'driver_offer_sent' || status == 'incoming';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Incoming Shipment Requests",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            if (incomingList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Appcolors.tertiaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${incomingList.length} New",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.tertiaryGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (incomingList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text(
                  "No pending shipment requests",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "When brokers assign shipments to you, they will appear here with Accept & Reject actions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incomingList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final offer = incomingList[index];
              return _IncomingOfferCard(offer: offer);
            },
          ),
      ],
    );
  }
}

// =====================================================================
// Incoming Offer Card with full details + Direct Accept & Reject
// =====================================================================
class _IncomingOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _IncomingOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final String orderNo = (offer['order_no'] ?? offer['order_id'] ?? '').toString();
    final String brokerName = (offer['broker_name'] ?? 'Broker').toString();
    final String pickupCity = (offer['pickup_city'] ?? 'N/A').toString();
    final String dropCity = (offer['drop_city'] ?? 'N/A').toString();
    final String itemType = (offer['item_type'] ?? 'Cargo').toString();
    final String weight = (offer['weight'] ?? 0).toString();
    final String vehicleType = (offer['vehicle_type'] ?? 'Truck').toString();
    final String fare = (offer['fare'] ?? '0').toString();
    final String date = (offer['date'] ?? 'Recent').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #$orderNo",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                "PKR $fare",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Appcolors.tertiaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Broker: $brokerName • $date",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          const SizedBox(height: 12),

          // Route (Responsive flexible layout to prevent RenderFlex overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.circle, size: 10, color: Appcolors.tertiaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickupCity,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              ),
              const Icon(Icons.location_on, size: 13, color: Colors.redAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dropCity,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Item + Vehicle Spec
          Text(
            "$itemType • $weight kg • Required: $vehicleType",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),

          const SizedBox(height: 16),

          // Accept / Reject Actions on Card
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      context.read<DriverOffersCubit>().rejectOffer(offer: offer);
                    },
                    child: const Text(
                      "Reject",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolors.tertiaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      context.read<DriverOffersCubit>().acceptOffer(offer: offer);
                    },
                    child: const Text(
                      "Accept",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Driver Profile Card
// =====================================================================
class _DriverProfileCard extends StatelessWidget {
  final dynamic driver;
  final String? locationStatus;
  const _DriverProfileCard({required this.driver, this.locationStatus});

  @override
  Widget build(BuildContext context) {
    final bool isComplete = driver.isTruckDetailsComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: Appcolors.tertiaryGreen.withOpacity(0.12),
                child: const Icon(
                  Icons.person,
                  color: Appcolors.tertiaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name.isNotEmpty ? driver.name : "Driver",
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.email,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      driver.phone,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detailItem("Driver ID", driver.driverId),
              _detailItem(
                "GPS Location",
                driver.driverLatitude != null && driver.driverLongitude != null
                    ? "${driver.driverLatitude!.toStringAsFixed(3)}, ${driver.driverLongitude!.toStringAsFixed(3)}"
                    : (locationStatus ?? "Active"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detailItem("Truck Number", driver.vehicleNumber ?? "Not specified"),
              _detailItem("Vehicle Type", driver.vehicleType ?? "Not specified"),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Truck details incomplete! Please complete your vehicle details.",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : "N/A",
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Broker Network Connection State Widgets
// =====================================================================
class _NoBrokerStateWidget extends StatelessWidget {
  final bool isTruckDetailsComplete;
  final VoidCallback onFindBroker;
  final VoidCallback onAddTruckDetails;

  const _NoBrokerStateWidget({
    required this.isTruckDetailsComplete,
    required this.onFindBroker,
    required this.onAddTruckDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isTruckDetailsComplete ? const Color(0xFFFFF8E1) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTruckDetailsComplete ? Colors.amber.withOpacity(0.4) : Colors.red.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isTruckDetailsComplete ? Colors.amber.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTruckDetailsComplete ? Icons.warning_amber_rounded : Icons.local_shipping_outlined,
                  color: isTruckDetailsComplete ? Colors.amber : Colors.red[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isTruckDetailsComplete ? "No Connected Broker" : "Complete Your Truck Details",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isTruckDetailsComplete
                ? "You are currently not connected to any Broker network. Connect with a Broker to receive direct job assignments."
                : "Please complete your truck details before joining a Broker network.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTruckDetailsComplete ? Appcolors.primaryBlue : Appcolors.tertiaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              onPressed: isTruckDetailsComplete ? onFindBroker : onAddTruckDetails,
              icon: Icon(
                isTruckDetailsComplete ? Icons.search_rounded : Icons.add_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isTruckDetailsComplete ? "Find a Broker" : "Add Truck Details",
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestPendingStateWidget extends StatelessWidget {
  final String brokerId;
  final String? brokerName;

  const _RequestPendingStateWidget({required this.brokerId, this.brokerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Text(
                  "Join Request Pending",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.amber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            brokerName != null && brokerName!.isNotEmpty ? brokerName! : "Broker ($brokerId)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "Waiting for broker approval before you can receive job dispatches.",
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _RequestRejectedStateWidget extends StatelessWidget {
  final String? brokerName;
  final VoidCallback onFindBroker;

  const _RequestRejectedStateWidget({this.brokerName, required this.onFindBroker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red[700], size: 16),
                const SizedBox(width: 6),
                Text(
                  "Request Rejected",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            brokerName != null && brokerName!.isNotEmpty ? brokerName! : "Broker",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: onFindBroker,
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
              label: const Text(
                "Find Another Broker",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedBrokerStateWidget extends StatelessWidget {
  final String brokerId;
  final String? brokerName;

  const _ConnectedBrokerStateWidget({required this.brokerId, this.brokerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Appcolors.tertiaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Appcolors.tertiaryGreen, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Connected to Broker",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Appcolors.tertiaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            brokerName != null && brokerName!.isNotEmpty ? brokerName! : "Broker ($brokerId)",
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "Authorized Partner • Receiving direct shipment requests",
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
