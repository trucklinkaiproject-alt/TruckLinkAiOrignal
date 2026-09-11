import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';
import 'package:trucklinkai_orignal/Core/Services/reviewService.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/Pages/brokerAssignDriverPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteStates.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderReqData;

  const OrderDetailsPage({super.key, required this.orderReqData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final TextEditingController quoteController = TextEditingController();

  @override
  void dispose() {
    quoteController.dispose();
    super.dispose();
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

  void submitQuote() {
    final quote = quoteController.text.trim();

    if (quote.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your quote.")));
      return;
    }

    final amount = double.tryParse(quote);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount.")));
      return;
    }

    context.read<BrokerQuoteCubit>().submitQuote(
      userUid: widget.orderReqData["userUid"] ?? widget.orderReqData["user_uid"],
      orderId: widget.orderReqData["orderId"] ?? widget.orderReqData["id"],
      brokerId: widget.orderReqData["brokerId"] ?? FirebaseAuth.instance.currentUser?.uid,
      amount: amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderReqData;

    final String orderNo = (data["orderNo"] ?? data["order_no"] ?? data["orderId"] ?? "N/A").toString();
    final requestId = "Order No # $orderNo";
    final createdAt = (data["createdAt"] ?? data["date"] ?? "Time not available").toString();

    final String userUid = (data["userUid"] ?? data["userId"] ?? data["user_uid"] ?? data["shipperId"] ?? "").toString();

    final pickupCity = (data["pickupCity"] ?? data["pickup_city"] ?? "").toString();
    final pickupAddress = (data["pickupComp"] ?? data["pickup_comp"] ?? data["pickupAddress"] ?? data["pickup_address"] ?? data["pickupLocation"] ?? "").toString();
    final pickup = pickupAddress.isNotEmpty
        ? (pickupCity.isNotEmpty && !pickupAddress.toLowerCase().contains(pickupCity.toLowerCase())
            ? "$pickupAddress, $pickupCity"
            : pickupAddress)
        : (pickupCity.isNotEmpty ? pickupCity : "Pickup address not specified");

    final dropCity = (data["dropCity"] ?? data["drop_city"] ?? "").toString();
    final dropAddress = (data["dropComp"] ?? data["drop_comp"] ?? data["dropAddress"] ?? data["drop_address"] ?? data["dropLocation"] ?? "").toString();
    final drop = dropAddress.isNotEmpty
        ? (dropCity.isNotEmpty && !dropAddress.toLowerCase().contains(dropCity.toLowerCase())
            ? "$dropAddress, $dropCity"
            : dropAddress)
        : (dropCity.isNotEmpty ? dropCity : "Drop address not specified");

    final itemType = (data["itemType"] ?? data["item_type"] ?? "Unknown").toString();
    final weight = (data["weight"] ?? "0").toString();
    final quantity = (data["quantity"] ?? "0").toString();
    final description = (data["additionalInfo"] ?? data["additional_info"] ?? "No description available.").toString();

    final String orderId = (data["orderId"] ?? data["id"] ?? data["orderNo"] ?? "").toString();
    final String brokerId = (data["brokerId"] ?? FirebaseAuth.instance.currentUser?.uid ?? "").toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 22 : width * 0.12;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // -------- Order # + time --------
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
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                  ),

                  SizedBox(height: isMobile ? 24 : 30),

                  // -------- Customer Information (REAL USER PROFILE FETCH) --------
                  const _SectionLabel("Customer Information"),
                  const SizedBox(height: 10),
                  FutureBuilder<DocumentSnapshot?>(
                    future: userUid.isNotEmpty
                        ? FirebaseFirestore.instance.collection("User").doc(userUid).get()
                        : Future<DocumentSnapshot?>.value(null),
                    builder: (context, snapshot) {
                      String customerName = "Loading...";
                      String phone = "Loading...";

                      if (snapshot.connectionState == ConnectionState.done) {
                        final userDoc = snapshot.data;
                        if (userDoc != null && userDoc.exists) {
                          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
                          customerName = (userData['name'] ?? userData['user_name'] ?? userData['userName'] ?? data['userName'] ?? data['name'] ?? 'Customer').toString();
                          phone = (userData['phone'] ?? userData['phone_number'] ?? userData['phoneNumber'] ?? data['phone'] ?? 'Not Available').toString();
                        } else {
                          customerName = (data['userName'] ?? data['name'] ?? (userUid.isNotEmpty ? 'Customer' : 'Not specified')).toString();
                          phone = (data['phone'] ?? 'Not Available').toString();
                        }
                      }

                      return _InfoCard(
                        icon: Icons.person_pin_circle_outlined,
                        iconColor: Appcolors.primaryBlue,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Customer Name",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Phone Number",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (userUid.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Appcolors.primaryBlue,
                                    side: BorderSide(
                                      color: Appcolors.primaryBlue.withOpacity(0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(21),
                                    ),
                                  ),
                                  onPressed: () {
                                    final String chatId = getDeterministicChatId(brokerId, userUid);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BrokerChatPage(
                                          chatId: chatId,
                                          receiverId: userUid,
                                          receiverName: customerName,
                                          receiverRole: 'User',
                                          orderId: orderNo,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                                  label: const Text(
                                    "Chat with User",
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
                      );
                    },
                  ),

                  SizedBox(height: isMobile ? 22 : 26),

                  // -------- Route (Full Addresses) --------
                  const _SectionLabel("Complete Route"),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.alt_route_rounded,
                    iconColor: Appcolors.secondaryPurple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Appcolors.tertiaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "PICKUP LOCATION",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pickup,
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 3.5, top: 4, bottom: 4),
                          child: Container(
                            width: 1.5,
                            height: 16,
                            color: Colors.grey.withOpacity(0.35),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "DROP LOCATION",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    drop,
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
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 22 : 26),

                  // -------- Item Details --------
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

                  SizedBox(height: isMobile ? 26 : 32),

                  // -------- Real-Time Stream for Status & Actions --------
                  StreamBuilder<DocumentSnapshot>(
                    stream: (brokerId.isNotEmpty && orderId.isNotEmpty)
                        ? FirebaseFirestore.instance
                            .collection("Broker")
                            .doc(brokerId)
                            .collection("IncomingRequests")
                            .doc(orderId)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, streamSnapshot) {
                      final Map<String, dynamic> docData = (streamSnapshot.hasData && streamSnapshot.data?.data() != null)
                          ? (streamSnapshot.data!.data() as Map<String, dynamic>)
                          : data;

                      final String rawStatus = (docData["status"] ?? "pending").toString().toLowerCase();
                      final bool isPending = rawStatus == "pending";

                      final String? assignedDriverId = docData["assigned_driver_id"] ?? docData["assignedDriverId"] ?? docData["driverId"];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------- "Your Quote" section - ONLY shown when status == pending --------
                          if (isPending) ...[
                            const _SectionLabel("Your Quote (PKR)"),
                            const SizedBox(height: 10),
                            TextField(
                              controller: quoteController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter Your Quote",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Appcolors.secondaryPurple,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: isMobile ? 22 : 26),

                            BlocListener<BrokerQuoteCubit, BrokerQuoteState>(
                              listener: (context, state) {
                                if (state is BrokerQuoteSuccess) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Quote Submitted: PKR ${state.amount.toStringAsFixed(0)}",
                                      ),
                                    ),
                                  );
                                } else if (state is BrokerQuoteError) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(state.error)));
                                }
                              },
                              child: BlocBuilder<BrokerQuoteCubit, BrokerQuoteState>(
                                builder: (context, state) {
                                  final bool loading = state is BrokerQuoteLoading;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Appcolors.secondaryPurple,
                                        disabledBackgroundColor: Appcolors.secondaryPurple
                                            .withOpacity(0.6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                      onPressed: loading ? null : submitQuote,
                                      child: loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              "Submit Quote",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: isMobile ? 20 : 24),
                          ],                          // -------- BROKER REQUEST STATUS SECTION --------
                          const _SectionLabel("Order & Shipment Status"),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final statusConfig = StatusColors.getStatusConfig(rawStatus);
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: statusConfig.backgroundColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: statusConfig.borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusConfig.color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        statusConfig.icon,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            statusConfig.label,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: statusConfig.color,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (rawStatus == 'rejected' || rawStatus == 'cancelled')
                                                ? "This request was declined."
                                                : isPending
                                                    ? "Submit a quote or accept the request to proceed."
                                                    : rawStatus == 'fare_offered'
                                                        ? "Quote has been sent to customer. Waiting for customer approval."
                                                        : "Order is confirmed and active under your management.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isMobile ? 22 : 26),

                          // -------- SHIPMENT FINANCIALS (CUSTOMER FARE & DRIVER PAYMENT) --------
                          if (!isPending) ...[
                            const _SectionLabel("Shipment Financials"),
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
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.person_outline_rounded, size: 18, color: Appcolors.secondaryPurple),
                                          SizedBox(width: 8),
                                          Text(
                                            "Customer Agreed Fare",
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "PKR ${_formatCurrency(_parseAmount(docData["customer_fare"] ?? docData["customerFare"] ?? docData["accepted_fare"] ?? docData["quoteAmount"] ?? docData["brokerOffer"] ?? docData["fare"]))}",
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: Appcolors.secondaryPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (docData["driver_fare"] != null || docData["driverFare"] != null || docData["assigned_fare"] != null) ...[
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.badge_outlined, size: 18, color: Appcolors.tertiaryGreen),
                                            SizedBox(width: 8),
                                            Text(
                                              "Driver Payment / Fare",
                                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "PKR ${_formatCurrency(_parseAmount(docData["driver_fare"] ?? docData["driverFare"] ?? docData["assigned_fare"]))}",
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: Appcolors.tertiaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: isMobile ? 22 : 26),
                          ],

                          // -------- DRIVER ASSIGNMENT & LIFECYCLE STATUS SECTION --------
                          const _SectionLabel("Driver Assignment & Status"),
                          const SizedBox(height: 10),
                          _buildDriverLifecycleCard(
                            rawStatus: rawStatus,
                            assignedDriverId: assignedDriverId,
                            assignedDriverName: docData["assigned_driver_name"] ?? docData["driverName"] ?? docData["assignedDriverName"],
                            driverOfferedFare: docData["assigned_fare"] ?? docData["brokerOffer"] ?? docData["fare"],
                            driverAcceptedFare: docData["driver_accepted_fare"] ?? docData["driver_fare"] ?? docData["assigned_fare"] ?? docData["brokerOffer"],
                          ),

                          SizedBox(height: isMobile ? 22 : 26),

                          // -------- DRIVER DETAILS CARD (If Driver Assigned) --------
                          if (assignedDriverId != null && assignedDriverId.toString().isNotEmpty) ...[
                            const _SectionLabel("Assigned Driver Details"),
                            const SizedBox(height: 10),
                            _buildDriverInfoCard(
                              context: context,
                              driverId: assignedDriverId.toString(),
                              fallbackName: (docData["assigned_driver_name"] ?? docData["driverName"] ?? "Driver").toString(),
                              fallbackPhone: (docData["assigned_driver_phone"] ?? docData["driverPhone"] ?? "").toString(),
                              fare: docData["driver_accepted_fare"] ?? docData["driver_fare"] ?? docData["assigned_fare"] ?? docData["brokerOffer"],
                              orderNo: orderNo,
                              brokerId: brokerId,
                            ),
                            SizedBox(height: isMobile ? 22 : 26),
                          ],

                          // -------- LIVE DRIVER GPS TRACKING (Active rides only - NOT completed) --------
                          if (assignedDriverId != null &&
                              assignedDriverId.toString().isNotEmpty &&
                              rawStatus != 'completed' &&
                              rawStatus != 'delivered' &&
                              (rawStatus == 'in_transit' || rawStatus == 'in_progress' || rawStatus == 'accepted_by_driver')) ...[
                            const _SectionLabel("Live Driver GPS Tracking"),
                            const SizedBox(height: 10),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("Driver")
                                  .doc(assignedDriverId.toString())
                                  .snapshots(),
                              builder: (context, locSnapshot) {
                                double? lat;
                                double? lng;

                                if (locSnapshot.hasData && locSnapshot.data != null && locSnapshot.data!.exists) {
                                  final lData = locSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                                  final numRawLat = lData['driver_latitude'] ?? lData['latitude'] ?? lData['lat'];
                                  final numRawLng = lData['driver_longitude'] ?? lData['longitude'] ?? lData['lng'];
                                  if (numRawLat != null && numRawLng != null) {
                                    lat = (numRawLat as num).toDouble();
                                    lng = (numRawLng as num).toDouble();
                                  }
                                }

                                final bool hasLocation = lat != null && lng != null && (lat != 0.0 || lng != 0.0);

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
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: hasLocation
                                              ? Appcolors.tertiaryGreen.withOpacity(0.12)
                                              : Colors.grey.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          hasLocation ? Icons.my_location_rounded : Icons.location_off_outlined,
                                          color: hasLocation ? Appcolors.tertiaryGreen : Colors.grey[600],
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  hasLocation ? "Live Driver GPS Active" : "Location Unavailable",
                                                  style: TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: hasLocation ? Colors.black87 : Colors.grey[700],
                                                  ),
                                                ),
                                                if (hasLocation) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Appcolors.tertiaryGreen,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              hasLocation
                                                  ? "Latitude: ${lat.toStringAsFixed(5)}°, Longitude: ${lng.toStringAsFixed(5)}°"
                                                  : "Driver location not yet received / GPS disabled",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: hasLocation ? Colors.grey[800] : Colors.grey[500],
                                                fontWeight: hasLocation ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 38,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Appcolors.primaryBlue,
                                                  side: BorderSide(
                                                    color: Appcolors.primaryBlue.withOpacity(0.35),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(19),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => OrderTrackingPage(
                                                        orderStatusDetail: docData,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.map_outlined, size: 16),
                                                label: const Text(
                                                  "Live Map Tracking",
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: isMobile ? 22 : 26),
                          ],

                          // -------- Reject / Assign Driver Action Buttons --------
                          if (rawStatus == "pending")
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[700],
                                  side: BorderSide(color: Colors.red.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: () async {
                                  await context.read<BrokerCubit>().rejectRequest(docData);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Request Rejected"),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text(
                                  "Reject",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                            )
                          else if (rawStatus == "accepted" && (assignedDriverId == null || assignedDriverId.toString().isEmpty))
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Appcolors.tertiaryGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BrokerAssignDriverPage(
                                        orderData: docData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  "Assign Driver to Order",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else if (rawStatus == "accepted_by_driver" || rawStatus == "in_progress")
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
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      title: const Text(
                                        "Mark Order as Completed?",
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                      content: const Text(
                                        "This will mark the order as successfully completed and update all records. This action cannot be undone.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1565C0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text(
                                            "Confirm",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await context.read<BrokerCubit>().completeOrder(docData);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Order marked as Completed ✓"),
                                          backgroundColor: Color(0xFF1565C0),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  "Mark as Completed",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else if (rawStatus == "completed" || rawStatus == "delivered") ...[
                            // Delivery Duration Summary
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
                                          docData["delivery_duration_seconds"] != null
                                              ? _formatDurationSeconds((docData["delivery_duration_seconds"] as num).toInt())
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
                            ),
                            const SizedBox(height: 14),

                            // Rate Driver Button
                            if (assignedDriverId != null &&
                                assignedDriverId.toString().isNotEmpty &&
                                docData['broker_reviewed_driver'] != true) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Appcolors.secondaryPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    final String dName = (docData["assigned_driver_name"] ??
                                            docData["driverName"] ??
                                            docData["driver_name"] ??
                                            'Driver')
                                        .toString();
                                    _showRateDriverDialog(
                                      context: context,
                                      orderId: orderId,
                                      driverId: assignedDriverId.toString(),
                                      driverName: dName,
                                      brokerId: brokerId,
                                    );
                                  },
                                  icon: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  label: const Text(
                                    "Rate Driver",
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (docData['broker_reviewed_driver'] == true) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Appcolors.secondaryPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Appcolors.secondaryPurple, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "You have submitted a review for this driver. Thank you!",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Appcolors.secondaryPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],

                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverLifecycleCard({
    required String rawStatus,
    required String? assignedDriverId,
    required dynamic assignedDriverName,
    required dynamic driverOfferedFare,
    required dynamic driverAcceptedFare,
  }) {
    final bool hasDriver = assignedDriverId != null && assignedDriverId.toString().isNotEmpty;

    // 1. Not assigned
    if (!hasDriver) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Driver Not Assigned",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Assign an eligible driver from your network to handle transit.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Offer Sent
    if (rawStatus == 'driver_offer_sent') {
      final fareStr = driverOfferedFare != null ? "PKR $driverOfferedFare" : "Fare Pending";
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Waiting for Driver Acceptance",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Offer sent to $assignedDriverName. Offered Fare: $fareStr",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Driver Rejected
    if (rawStatus == 'driver_rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Driver Declined Offer",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$assignedDriverName declined this offer. You can re-assign another driver.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. Accepted by Driver
    if (rawStatus == 'accepted_by_driver') {
      final fareStr = driverAcceptedFare != null ? "PKR $driverAcceptedFare" : "Agreed Fare";
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Appcolors.tertiaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Appcolors.tertiaryGreen.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Appcolors.tertiaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Driver Confirmed / Accepted",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.tertiaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$assignedDriverName confirmed. Driver Fare: $fareStr",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 5. In Transit
    if (rawStatus == 'in_transit' || rawStatus == 'in_progress') {
      final fareStr = driverAcceptedFare != null ? "PKR $driverAcceptedFare" : "Agreed Fare";
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Appcolors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Appcolors.primaryBlue.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Appcolors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "In Transit",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Goods are currently in transit with $assignedDriverName ($fareStr).",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 6. Completed
    if (rawStatus == 'completed' || rawStatus == 'delivered') {
      final fareStr = driverAcceptedFare != null ? "PKR $driverAcceptedFare" : "Agreed Fare";
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Appcolors.tertiaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Appcolors.tertiaryGreen.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Appcolors.tertiaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Completed",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.tertiaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Completed by $assignedDriverName. Final Driver Fare: $fareStr",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDriverInfoCard({
    required BuildContext context,
    required String driverId,
    required String fallbackName,
    required String fallbackPhone,
    required dynamic fare,
    required String orderNo,
    required String brokerId,
  }) {
    return FutureBuilder<DocumentSnapshot?>(
      future: driverId.isNotEmpty
          ? FirebaseFirestore.instance.collection("Driver").doc(driverId).get()
          : Future<DocumentSnapshot?>.value(null),
      builder: (context, snapshot) {
        String driverName = fallbackName;
        String phone = fallbackPhone;
        String vehicle = "Not specified";
        String plate = "Not specified";

        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null && snapshot.data!.exists) {
          final dData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          driverName = (dData['name'] ?? dData['driver_name'] ?? fallbackName).toString();
          phone = (dData['phone'] ?? dData['driver_phone'] ?? fallbackPhone).toString();
          vehicle = (dData['vehicle_type'] ?? dData['vehicleType'] ?? 'Not specified').toString();
          plate = (dData['vehicle_number'] ?? dData['vehicleNumber'] ?? 'Not specified').toString();
        }

        final fareDisplay = fare != null ? "PKR $fare" : "Not specified";

        return _InfoCard(
          icon: Icons.badge_outlined,
          iconColor: Appcolors.primaryBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driverName,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Phone: $phone",
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
              Text(
                "Vehicle: $vehicle ($plate)",
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
              Text(
                "Driver Fare: $fareDisplay",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.tertiaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Appcolors.primaryBlue,
                    side: BorderSide(
                      color: Appcolors.primaryBlue.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    final String chatId = getDeterministicChatId(brokerId, driverId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrokerChatPage(
                          chatId: chatId,
                          receiverId: driverId,
                          receiverName: driverName,
                          receiverRole: 'Driver',
                          orderId: orderNo,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text(
                    "Chat with Driver",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDurationSeconds(int seconds) {
    if (seconds < 60) return "$seconds seconds";
    final int minutes = seconds ~/ 60;
    if (minutes < 60) return "$minutes min${minutes > 1 ? 's' : ''}";
    final int hours = minutes ~/ 60;
    final int remMin = minutes % 60;
    if (remMin == 0) return "$hours hr${hours > 1 ? 's' : ''}";
    return "$hours hr $remMin min";
  }

  void _showRateDriverDialog({
    required BuildContext context,
    required String orderId,
    required String driverId,
    required String driverName,
    required String brokerId,
  }) {
    double rating = 5.0;
    final TextEditingController commentCtrl = TextEditingController();
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
                  Text(
                    "Rate Driver: $driverName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rate the driver's performance on Order #$orderId",
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          starVal <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber[600],
                          size: 34,
                        ),
                        onPressed: () => setModalState(() => rating = starVal),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add feedback on driving, punctuality, and communication...",
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.secondaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final currentUser = FirebaseAuth.instance.currentUser;
                              final brokerUid = currentUser?.uid ?? brokerId;
                              final brokerName = currentUser?.displayName ?? 'Broker';

                              final ok = await ReviewService().submitDriverReview(
                                orderId: orderId,
                                driverId: driverId,
                                reviewerId: brokerUid,
                                reviewerName: brokerName,
                                reviewerRole: 'broker',
                                rating: rating,
                                comment: commentCtrl.text,
                                brokerId: brokerId,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? "Driver rated successfully ✓"
                                        : "Review already recorded for this order."),
                                    backgroundColor: ok ? Appcolors.tertiaryGreen : Colors.grey[700],
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Driver Rating",
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
