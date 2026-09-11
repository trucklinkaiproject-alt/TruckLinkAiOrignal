import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/statusColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverOffersBloc/driverOffersCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverOffersBloc/driverOffersState.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';

class DriverOfferDetailPage extends StatelessWidget {
  final Map<String, dynamic> offer;

  const DriverOfferDetailPage({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final String orderNo = (offer['order_no'] ?? offer['orderNo'] ?? offer['order_id'] ?? '').toString();
    final String orderId = (offer['order_id'] ?? offer['orderId'] ?? orderNo).toString();
    final String currentDriverUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: (currentDriverUid.isNotEmpty && orderId.isNotEmpty)
              ? FirebaseFirestore.instance
                  .collection("Driver")
                  .doc(currentDriverUid)
                  .collection("ReceivedOffers")
                  .doc(orderId)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            Map<String, dynamic> liveOffer = Map.from(offer);
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
              liveOffer.addAll(snapshot.data!.data() as Map<String, dynamic>);
            }

            final String brokerName = (liveOffer['broker_name'] ?? 'Broker').toString();
            final String brokerId = (liveOffer['broker_id'] ?? '').toString();
            final String pickupCity = (liveOffer['pickup_city'] ?? liveOffer['pickupCity'] ?? '').toString();
            final String pickupAddress = (liveOffer['pickup_comp'] ?? liveOffer['pickupComp'] ?? liveOffer['pickup_address'] ?? liveOffer['pickupAddress'] ?? '').toString();
            final String pickup = pickupAddress.isNotEmpty
                ? (pickupCity.isNotEmpty && !pickupAddress.toLowerCase().contains(pickupCity.toLowerCase())
                    ? "$pickupAddress, $pickupCity"
                    : pickupAddress)
                : (pickupCity.isNotEmpty ? pickupCity : "Pickup address not specified");

            final String dropCity = (liveOffer['drop_city'] ?? liveOffer['dropCity'] ?? '').toString();
            final String dropAddress = (liveOffer['drop_comp'] ?? liveOffer['dropComp'] ?? liveOffer['drop_address'] ?? liveOffer['dropAddress'] ?? '').toString();
            final String drop = dropAddress.isNotEmpty
                ? (dropCity.isNotEmpty && !dropAddress.toLowerCase().contains(dropCity.toLowerCase())
                    ? "$dropAddress, $dropCity"
                    : dropAddress)
                : (dropCity.isNotEmpty ? dropCity : "Drop address not specified");

            final String itemType = (liveOffer['item_type'] ?? 'General Cargo').toString();
            final String weight = (liveOffer['weight'] ?? 0).toString();
            final String quantity = (liveOffer['quantity'] ?? 0).toString();
            final String vehicleType = (liveOffer['vehicle_type'] ?? 'Truck').toString();
            final String additionalInfo = (liveOffer['additional_info'] ?? 'No additional instructions.').toString();
            final double fare = (liveOffer['fare'] as num?)?.toDouble() ?? 0.0;
            final String date = (liveOffer['date'] ?? 'Recent').toString();
            final String rawStatus = (liveOffer['status'] ?? 'pending').toString().toLowerCase();
            final String ridePhase = (liveOffer['ride_phase'] ?? '').toString();

            final bool isPending = rawStatus == 'pending' || rawStatus == 'driver_offer_sent' || rawStatus == 'incoming';
            final bool isAccepted = rawStatus == 'accepted_by_driver' || rawStatus == 'accepted';
            final bool isInTransit = rawStatus == 'in_transit' || rawStatus == 'in_progress' || rawStatus == 'arrived_at_pickup' || rawStatus == 'heading_to_drop';
            final bool isCompleted = rawStatus == 'completed' || rawStatus == 'delivered';
            final bool isCancelled = rawStatus == 'rejected_by_driver' || rawStatus == 'cancelled' || rawStatus == 'rejected';

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 18 : width * 0.12;

                return BlocConsumer<DriverOffersCubit, DriverOffersState>(
                  listener: (context, state) {
                    if (state is DriverOffersActionSuccessState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Appcolors.tertiaryGreen,
                        ),
                      );
                    }

                    if (state is DriverOffersErrorState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
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
                              BackArrowButton(onTap: () => Navigator.pop(context)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Order #$orderNo",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final cfg = StatusColors.getStatusConfig(rawStatus);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cfg.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cfg.borderColor, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(cfg.icon, size: 12, color: cfg.color),
                                        const SizedBox(width: 4),
                                        Text(
                                          cfg.label.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: cfg.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // -------- Fare Card --------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Appcolors.tertiaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Appcolors.tertiaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Appcolors.tertiaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Agreed Fare",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "PKR ${fare.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Appcolors.tertiaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // -------- Broker Info --------
                          const _SectionLabel("Broker Information"),
                          const SizedBox(height: 8),
                          _detailCard(
                            icon: Icons.business_outlined,
                            iconColor: Appcolors.secondaryPurple,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brokerName,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Broker ID: $brokerId",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                if (brokerId.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Appcolors.secondaryPurple,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        final String chatId = getDeterministicChatId(currentDriverUid, brokerId);
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
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                                      label: const Text(
                                        "Chat with Broker",
                                        style: TextStyle(
                                          fontSize: 13,
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

                          const SizedBox(height: 18),

                          // -------- Route Details --------
                          const _SectionLabel("Complete Route"),
                          const SizedBox(height: 8),
                          _detailCard(
                            icon: Icons.alt_route_rounded,
                            iconColor: Appcolors.primaryBlue,
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

                          const SizedBox(height: 18),

                          // -------- Cargo & Vehicle Details --------
                          const _SectionLabel("Cargo & Vehicle Requirements"),
                          const SizedBox(height: 8),
                          _detailCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: Colors.amber[700]!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow("Item Type", itemType),
                                const SizedBox(height: 6),
                                _infoRow("Required Vehicle", vehicleType),
                                const SizedBox(height: 6),
                                _infoRow("Weight", "$weight kg"),
                                const SizedBox(height: 6),
                                _infoRow("Quantity", quantity),
                                if (additionalInfo.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    "Additional Info: $additionalInfo",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // =======================================================
                          // STATE-SPECIFIC ACTIONS
                          // =======================================================
                          if (isPending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[700],
                                        side: BorderSide(color: Colors.red.withOpacity(0.4), width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      onPressed: state is DriverOffersLoadingState
                                          ? null
                                          : () async {
                                              await context.read<DriverOffersCubit>().rejectOffer(offer: liveOffer);
                                              if (context.mounted && Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              }
                                            },
                                      child: const Text(
                                        "REJECT",
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Appcolors.tertiaryGreen,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      onPressed: state is DriverOffersLoadingState
                                          ? null
                                          : () {
                                              context.read<DriverOffersCubit>().acceptOffer(offer: liveOffer);
                                            },
                                      child: state is DriverOffersLoadingState
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              "ACCEPT",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                          else if (isAccepted) ...[
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
                                  context.read<DriverOffersCubit>().startRide(offer: liveOffer);
                                },
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                label: const Text(
                                  "START RIDE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (isInTransit) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Appcolors.primaryBlue,
                                  side: BorderSide(color: Appcolors.primaryBlue.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderTrackingPage(orderStatusDetail: liveOffer),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text(
                                  "View Live Map Tracking",
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (ridePhase != 'heading_to_drop')
                              SizedBox(
                                width: double.infinity,
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
                                    context.read<DriverOffersCubit>().confirmCargoPickedUp(offer: liveOffer);
                                  },
                                  icon: const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                                  label: const Text(
                                    "Confirm Cargo Loaded",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
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
                                  _showCompleteConfirmation(context, liveOffer);
                                },
                                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                label: const Text(
                                  "Complete Delivery",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ] else if (isCompleted) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Appcolors.tertiaryGreen.withOpacity(0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Appcolors.tertiaryGreen),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "This order has been successfully delivered and completed.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Appcolors.tertiaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isCancelled) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined, color: Colors.red[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "This request has been cancelled or rejected.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCompleteConfirmation(BuildContext context, Map<String, dynamic> liveOffer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Complete Delivery?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          "Confirm that you have completed this delivery. GPS tracking will stop and the broker/user will be notified.",
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
              context.read<DriverOffersCubit>().completeRide(offer: liveOffer);
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _detailCard({required IconData icon, required Color iconColor, required Widget child}) {
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
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
