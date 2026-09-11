import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';
import 'package:trucklinkai_orignal/Core/Services/reviewService.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Core/Widgets/builtyPage.dart';
import 'package:trucklinkai_orignal/Features/User Module/Pages/orderTrackingPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';

class ShipperOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  const ShipperOrderDetailPage({super.key, required this.orderDetails});

  @override
  State<ShipperOrderDetailPage> createState() => _ShipperOrderDetailPageState();
}

class _ShipperOrderDetailPageState extends State<ShipperOrderDetailPage> {
  late Future<Map<String, dynamic>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _fetchProfiles(widget.orderDetails);
  }

  Future<Map<String, dynamic>> _fetchProfiles(Map<String, dynamic> currentOrderDetails) async {
    final String? brokerId = currentOrderDetails["brokerId"] ?? currentOrderDetails["broker_id"];
    final String? userUid = currentOrderDetails["userUid"] ?? currentOrderDetails["user_uid"] ?? FirebaseAuth.instance.currentUser?.uid;
    final String? driverUid = currentOrderDetails["assigned_driver_id"] ??
        currentOrderDetails["driver_id"] ??
        currentOrderDetails["driverUid"] ??
        currentOrderDetails["driver_uid"];

    Map<String, dynamic> data = {
      'brokerName': currentOrderDetails["brokerName"] ?? 'Broker',
      'brokerPhone': currentOrderDetails["brokerPhone"] ?? 'N/A',
      'brokerId': brokerId ?? 'N/A',
      'brokerRating': 0.0,
      'userName': 'User',
      'userId': userUid ?? 'N/A',
      'driverName': currentOrderDetails["assigned_driver_name"] ?? currentOrderDetails["driver_name"] ?? '',
      'driverUid': driverUid ?? '',
      'driverPhone': currentOrderDetails["assigned_driver_phone"] ?? currentOrderDetails["driver_phone"] ?? '',
      'driverRating': 0.0,
      'vehicleType': currentOrderDetails["vehicle_type"] ?? currentOrderDetails["truck_type"] ?? 'Truck',
      'vehicleNumber': currentOrderDetails["vehicle_number"] ?? currentOrderDetails["truck_no"] ?? '',
    };

    if (brokerId != null && brokerId.isNotEmpty) {
      try {
        final brokerDoc = await FirebaseFirestore.instance.collection("Broker").doc(brokerId).get();
        if (brokerDoc.exists && brokerDoc.data() != null) {
          final bData = brokerDoc.data()!;
          data['brokerName'] = bData['name'] ?? bData['broker_name'] ?? data['brokerName'];
          data['brokerPhone'] = bData['phone'] ?? bData['phone_number'] ?? data['brokerPhone'];
          data['brokerId'] = bData['brokerId'] ?? bData['broker_id'] ?? brokerId;
          data['brokerRating'] = (bData['rating'] as num?)?.toDouble() ?? (bData['overall_rating'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    if (userUid != null && userUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection("User").doc(userUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final uData = userDoc.data()!;
          data['userName'] = uData['name'] ?? uData['user_name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Shipper';
          data['userId'] = uData['userId'] ?? uData['user_id'] ?? userUid;
        }
      } catch (_) {}
    }

    if (driverUid != null && driverUid.isNotEmpty) {
      try {
        final driverDoc = await FirebaseFirestore.instance.collection("Driver").doc(driverUid).get();
        if (driverDoc.exists && driverDoc.data() != null) {
          final dData = driverDoc.data()!;
          data['driverName'] = dData['name'] ?? dData['driver_name'] ?? data['driverName'];
          data['driverPhone'] = dData['phone'] ?? dData['driver_phone'] ?? data['driverPhone'];
          data['driverUid'] = dData['driverId'] ?? dData['driver_id'] ?? driverUid;
          data['vehicleType'] = dData['vehicle_type'] ?? dData['truck_type'] ?? dData['vehicleType'] ?? data['vehicleType'];
          data['vehicleNumber'] = dData['vehicle_number'] ?? dData['truck_no'] ?? dData['vehicleNumber'] ?? data['vehicleNumber'];
        }
      } catch (_) {}
    }

    return data;
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  String _formatCurrency(double amount) {
    final String str = amount.toStringAsFixed(0);
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = (widget.orderDetails['orderId'] ?? widget.orderDetails['id'] ?? widget.orderDetails['orderNo'] ?? '').toString();
    final String userUid = (widget.orderDetails['userUid'] ?? widget.orderDetails['user_uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: (userUid.isNotEmpty && orderId.isNotEmpty)
              ? FirebaseFirestore.instance
                  .collection("User")
                  .doc(userUid)
                  .collection("Requests")
                  .doc(orderId)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            Map<String, dynamic> orderDetails = Map.from(widget.orderDetails);
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
              orderDetails.addAll(snapshot.data!.data() as Map<String, dynamic>);
            }

            final String requestId = "Order No # TL - ${orderDetails["orderNo"] ?? "Not Available"}";
            final String createdAt = (orderDetails["date"] ?? orderDetails["createdAt"] ?? "Not Available").toString();
            final String status = (orderDetails["status"] ?? "pending").toString();

            final String pickup = orderDetails["pickupComp"] ?? orderDetails["pickupCity"] ?? "Not Available";
            final String drop = orderDetails["dropComp"] ?? orderDetails["dropCity"] ?? "Not Available";

            final String itemType = orderDetails["itemType"] ?? "Not Available";
            final weight = orderDetails["weight"] ?? "Not Available";
            final quantity = orderDetails["quantity"] ?? "Not Available";
            final String description = orderDetails["additionalInfo"] ?? "Not Available";

            final dynamic rawAmount = orderDetails["customer_fare"] ??
                orderDetails["customerFare"] ??
                orderDetails["accepted_fare"] ??
                orderDetails["acceptedFare"] ??
                orderDetails["quoteAmount"] ??
                orderDetails["quote_amount"] ??
                orderDetails["brokerOffer"] ??
                orderDetails["fare"] ??
                orderDetails["amount"] ??
                orderDetails["price"];
            final double acceptedAmount = _parseAmount(rawAmount);

            final String builtyNumber = (orderDetails["builtyNumber"] ?? orderDetails["orderNo"] ?? "BL-992").toString();
            final String builtyStatus = (orderDetails["builtyStatus"] ?? "Issued & Verified").toString();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 22 : width * 0.12;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Header --------
                      Row(
                        children: [
                          BackArrowButton(onTap: () => Navigator.pop(context)),
                          const Spacer(),
                          const Text(
                            "Request Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {},
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 24 : 30),

                      // -------- Request ID & Status --------
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  requestId,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status != "rejected"
                                  ? Appcolors.tertiaryGreen.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status != "rejected"
                                      ? Icons.check_circle
                                      : Icons.remove_circle_outline_sharp,
                                  size: 14,
                                  color: status != "rejected"
                                      ? Appcolors.tertiaryGreen
                                      : Colors.red,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: status != "rejected"
                                        ? Appcolors.tertiaryGreen
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 18 : 22),

                      if (status != "rejected")
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Appcolors.primaryBlue.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderTrackingPage(
                                    orderStatusDetail: orderDetails,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  color: Appcolors.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Track Driver & Live Map",
                                  style: TextStyle(
                                    color: Appcolors.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Appcolors.primaryBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: isMobile ? 24 : 30),

                      // -------- FutureBuilder for Profiles --------
                      FutureBuilder<Map<String, dynamic>>(
                        future: _fetchProfiles(orderDetails),
                        builder: (context, profileSnapshot) {
                          final p = profileSnapshot.data ?? {};
                          final String brokerRealName = p['brokerName'] ?? 'Broker';
                          final String brokerPhone = p['brokerPhone'] ?? 'N/A';
                          final String brokerId = p['brokerId'] ?? 'N/A';
                          final double brokerRating = p['brokerRating'] ?? 4.8;

                          final String userName = p['userName'] ?? 'Shipper';
                          final String userId = p['userId'] ?? 'N/A';

                          final String driverName = p['driverName'] ?? '';
                          final String driverUid = p['driverUid'] ?? '';
                          final String driverPhone = p['driverPhone'] ?? '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------- BROKER INFORMATION --------
                              const _SectionLabel("Broker Information"),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
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
                                          radius: 24,
                                          backgroundColor: Appcolors.secondaryPurple.withOpacity(0.12),
                                          child: Text(
                                            brokerRealName
                                                .trim()
                                                .split(RegExp(r"\s+"))
                                                .map((e) => e.isNotEmpty ? e[0] : "")
                                                .take(2)
                                                .join()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Appcolors.secondaryPurple,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                brokerRealName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Phone: $brokerPhone",
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _miniDetail("Broker ID", brokerId),
                                        Row(
                                          children: [
                                            Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              brokerRating.toStringAsFixed(1),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (brokerId != 'N/A' && brokerId.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Appcolors.secondaryPurple,
                                            side: BorderSide(
                                              color: Appcolors.secondaryPurple.withOpacity(0.4),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(21),
                                            ),
                                          ),
                                          onPressed: () {
                                            final String orderNoStr = (orderDetails["orderNo"] ?? orderId).toString();
                                            final String chatId = getDeterministicChatId(userUid, brokerId);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BrokerChatPage(
                                                  chatId: chatId,
                                                  receiverId: brokerId,
                                                  receiverName: brokerRealName,
                                                  receiverRole: 'Broker',
                                                  orderId: orderNoStr,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                                          label: const Text(
                                            "Chat with Broker",
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(height: isMobile ? 20 : 24),

                              // -------- USER INFORMATION --------
                              const _SectionLabel("User Information"),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
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
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Appcolors.primaryBlue.withOpacity(0.12),
                                      child: const Icon(Icons.person, color: Appcolors.primaryBlue, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "User ID: $userId",
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
                              ),

                              // -------- DRIVER INFORMATION (WHEN ASSIGNED) --------
                              if (driverUid.isNotEmpty || driverName.isNotEmpty) ...[
                                SizedBox(height: isMobile ? 20 : 24),
                                const _SectionLabel("Driver Information"),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
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
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Appcolors.tertiaryGreen.withOpacity(0.12),
                                        child: const Icon(Icons.badge_outlined, color: Appcolors.tertiaryGreen, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              driverName.isNotEmpty ? driverName : 'Driver',
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Driver UID: $driverUid",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Phone: ${driverPhone.isNotEmpty ? driverPhone : 'N/A'}",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (driverUid.isNotEmpty && driverUid != 'N/A') ...[
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 42,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Appcolors.tertiaryGreen,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(21),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    final String orderNoStr = (orderDetails["orderNo"] ?? orderId).toString();
                                                    final String chatId = getDeterministicChatId(userUid, driverUid);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => BrokerChatPage(
                                                          chatId: chatId,
                                                          receiverId: driverUid,
                                                          receiverName: driverName.isNotEmpty ? driverName : 'Driver',
                                                          receiverRole: 'Driver',
                                                          orderId: orderNoStr,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: Colors.white),
                                                  label: const Text(
                                                    "Chat with Driver",
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              SizedBox(height: isMobile ? 22 : 26),

                      const _SectionLabel("Route"),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.location_on_outlined,
                        iconColor: Appcolors.primaryBlue,
                        child: Text(
                          "$pickup  ➜  $drop",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 22 : 26),

                      const _SectionLabel("Item Details"),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: Appcolors.tertiaryGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Weight: $weight kg",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              "Quantity: $quantity",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 30 : 36),

                      const _SectionLabel("Shipment Quote & Status"),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final String rawStatusLower = status.toLowerCase();
                          final bool isPending = rawStatusLower == "pending" || rawStatusLower == "waiting";
                          final bool isQuoteOffered = rawStatusLower == "fare_offered" || rawStatusLower == "counter_quote";
                          final bool isAccepted = rawStatusLower == "accepted" ||
                              rawStatusLower == "accepted_by_user" ||
                              rawStatusLower == "driver_assigned" ||
                              rawStatusLower == "driver_offer_sent" ||
                              rawStatusLower == "accepted_by_driver" ||
                              rawStatusLower == "in_transit" ||
                              rawStatusLower == "completed";
                          final bool isRejected = rawStatusLower == "rejected" || rawStatusLower == "cancelled";

                          if (isPending) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: StatusColors.amberWarning.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: StatusColors.amberWarning.withOpacity(0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.hourglass_top_rounded,
                                        color: StatusColors.amberDark,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Waiting for broker response",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "The broker has received your shipment request and will submit a quote shortly.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (isQuoteOffered) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Appcolors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Appcolors.primaryBlue.withOpacity(0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.local_offer_rounded,
                                        color: Appcolors.primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Broker sent a quote",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Appcolors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Quoted Amount: PKR ${_formatCurrency(acceptedAmount)}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Appcolors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red[700],
                                            side: BorderSide(color: Colors.red.withOpacity(0.4)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            context.read<UserCubit>().rejectOffer(orderId);
                                          },
                                          child: const Text(
                                            "Decline",
                                            style: TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Appcolors.tertiaryGreen,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            context.read<UserCubit>().acceptOffer(orderId);
                                          },
                                          child: const Text(
                                            "Accept Quote",
                                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          if (isAccepted && acceptedAmount > 0) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 22,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Appcolors.tertiaryGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Appcolors.tertiaryGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Appcolors.tertiaryGreen,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Broker accepted your shipment at",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "PKR ${_formatCurrency(acceptedAmount)}",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Appcolors.tertiaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Rejected / cancelled fallback
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.remove_circle_outline_sharp,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isRejected ? "Request Declined" : "Waiting for Quote",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isRejected ? Colors.red[800] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isMobile ? 30 : 36),

                      // -------- BUILTY SECTION (STRICT RULE: ONLY DISPLAYED AFTER DRIVER IS ASSIGNED) --------
                      if (status != "rejected" && driverUid.isNotEmpty && driverUid != 'N/A') ...[
                        const _SectionLabel("Builty / Consignment Note"),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
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
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Appcolors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Appcolors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Builty No. $builtyNumber",
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Appcolors.tertiaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          builtyStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  final String effectiveDriver = driverName.isNotEmpty ? driverName : "Assigned Driver";
                                  final String transportStr = (p['vehicleNumber'] != null && (p['vehicleNumber'] as String).isNotEmpty)
                                      ? "${p['vehicleType'] ?? 'Truck'} (${p['vehicleNumber']})"
                                      : (p['vehicleType'] ?? "Truck / Transport");

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuiltyPage(
                                        driverName: effectiveDriver,
                                        transportName: transportStr,
                                        orderId: (orderDetails["orderNo"] ?? orderId).toString(),
                                        brokerName: brokerRealName,
                                        date: createdAt != "Not Available" ? createdAt : "Official Record",
                                        docNo: builtyNumber,
                                        fromLocation: pickup,
                                        itemType: itemType,
                                        price: acceptedAmount > 0 ? acceptedAmount.toStringAsFixed(0) : (orderDetails["brokerOffer"] ?? "0").toString(),
                                        toLocation: drop,
                                        userName: userName,
                                        weight: weight,
                                        quantity: quantity,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Appcolors.primaryBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.download_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "View",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 30 : 36),
                      ],

                      // -------- DELIVERY DURATION & TIMESTAMPS (WHEN COMPLETED) --------
                      if (status == "completed" || status == "delivered") ...[
                        const _SectionLabel("Delivery & Journey Summary"),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
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
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.timer_outlined, color: Appcolors.tertiaryGreen, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Actual Delivery Time",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          orderDetails["delivery_duration_seconds"] != null
                                              ? _formatDuration((orderDetails["delivery_duration_seconds"] as num).toInt())
                                              : "Delivered successfully",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Completed",
                                      style: TextStyle(
                                        color: Appcolors.tertiaryGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rate & Review Button
                        if (orderDetails['user_reviewed_broker'] != true || orderDetails['user_reviewed_driver'] != true) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final String bId = (orderDetails["brokerId"] ?? orderDetails["broker_id"] ?? "").toString();
                                final String bName = (orderDetails["brokerName"] ?? orderDetails["broker_name"] ?? "Broker").toString();
                                final String dUid = (orderDetails["assigned_driver_id"] ?? orderDetails["driver_id"] ?? orderDetails["driverUid"] ?? "").toString();
                                final String dName = (orderDetails["assigned_driver_name"] ?? orderDetails["driver_name"] ?? "Driver").toString();

                                _showReviewBottomSheet(
                                  context: context,
                                  orderId: orderId,
                                  brokerId: bId,
                                  brokerName: bName,
                                  driverId: dUid,
                                  driverName: dName,
                                  userReviewedBroker: orderDetails['user_reviewed_broker'] == true,
                                  userReviewedDriver: orderDetails['user_reviewed_driver'] == true,
                                );
                              },
                              icon: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                              label: const Text(
                                "Rate & Review",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Appcolors.tertiaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Appcolors.tertiaryGreen, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "You have submitted feedback for this completed trip. Thank you!",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Appcolors.tertiaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      SizedBox(height: isMobile ? 20 : 26),
                            ],
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

  String _formatDuration(int seconds) {
    if (seconds < 60) return "$seconds seconds";
    final int minutes = seconds ~/ 60;
    if (minutes < 60) return "$minutes min${minutes > 1 ? 's' : ''}";
    final int hours = minutes ~/ 60;
    final int remMin = minutes % 60;
    if (remMin == 0) return "$hours hr${hours > 1 ? 's' : ''}";
    return "$hours hr $remMin min";
  }

  void _showReviewBottomSheet({
    required BuildContext context,
    required String orderId,
    required String brokerId,
    required String brokerName,
    required String driverId,
    required String driverName,
    required bool userReviewedBroker,
    required bool userReviewedDriver,
  }) {
    double brokerRating = 5.0;
    double driverRating = 5.0;
    final TextEditingController brokerCommentCtrl = TextEditingController();
    final TextEditingController driverCommentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate & Review Your Experience",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Share your feedback to help us keep TruckLink AI reliable.",
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 18),

                  // Broker Review Section
                  if (!userReviewedBroker && brokerId.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Appcolors.secondaryPurple.withOpacity(0.12),
                                child: const Icon(Icons.business_rounded, color: Appcolors.secondaryPurple, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Rate Broker: $brokerName",
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starVal = index + 1.0;
                              return IconButton(
                                icon: Icon(
                                  starVal <= brokerRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber[600],
                                  size: 32,
                                ),
                                onPressed: () => setModalState(() => brokerRating = starVal),
                              );
                            }),
                          ),
                          TextField(
                            controller: brokerCommentCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Write a brief review for the broker...",
                              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Driver Review Section
                  if (!userReviewedDriver && driverId.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Appcolors.tertiaryGreen.withOpacity(0.12),
                                child: const Icon(Icons.badge_outlined, color: Appcolors.tertiaryGreen, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Rate Driver: $driverName",
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starVal = index + 1.0;
                              return IconButton(
                                icon: Icon(
                                  starVal <= driverRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber[600],
                                  size: 32,
                                ),
                                onPressed: () => setModalState(() => driverRating = starVal),
                              );
                            }),
                          ),
                          TextField(
                            controller: driverCommentCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Write a brief review for the driver...",
                              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final currentUser = FirebaseAuth.instance.currentUser;
                              final userId = currentUser?.uid ?? '';
                              final userName = currentUser?.displayName ?? 'Verified Shipper';

                              if (!userReviewedBroker && brokerId.isNotEmpty) {
                                await ReviewService().submitBrokerReview(
                                  orderId: orderId,
                                  brokerId: brokerId,
                                  userId: userId,
                                  userName: userName,
                                  rating: brokerRating,
                                  comment: brokerCommentCtrl.text,
                                );
                              }

                              if (!userReviewedDriver && driverId.isNotEmpty) {
                                await ReviewService().submitDriverReview(
                                  orderId: orderId,
                                  driverId: driverId,
                                  reviewerId: userId,
                                  reviewerName: userName,
                                  reviewerRole: 'user',
                                  rating: driverRating,
                                  comment: driverCommentCtrl.text,
                                  brokerId: brokerId,
                                );
                              }

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Thank you! Your reviews have been submitted."),
                                    backgroundColor: Appcolors.tertiaryGreen,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Reviews",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

Widget _miniDetail(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    ],
  );
}
