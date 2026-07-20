import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Core/Widgets/builtyPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';
// ^ Adjust this import path to wherever OrderTrackingPage actually lives
// in your project structure.

/// Simple mock data holder for this screen.
/// Swap this out for your real order/broker data whenever this gets wired
/// up — the UI below only depends on these fields.
class ShipperOrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderDetails;
  const ShipperOrderDetailPage({super.key, required this.orderDetails});

  @override
  Widget build(BuildContext context) {
    // -------- Mock data for now — replace with real order data --------
    final String requestId =
        "Order No #  TL - ${orderDetails["orderNo"] ?? "Not Available"}";
    final String createdAt = orderDetails["date"] ?? "Not Available";

    final String brokerName = orderDetails["brokerId"] ?? "Not Available";
    final String brokerLocation = orderDetails["brokerLoc"] ?? "Not Available";
    final brokerRating = 4.8;

    final String status = orderDetails["status"];

    final String pickup = orderDetails["pickupComp"] ?? "Not Available";
    final String drop = orderDetails["dropComp"] ?? "Not Available";

    final String itemType = orderDetails["itemType"] ?? "Not Available";
    final weight = orderDetails["weight"] ?? "Not Available";
    final quantity = orderDetails["quantity"] ?? "Not Available";
    final String description =
        orderDetails["additionalInfo"] ?? "Not Available";

    final acceptedAmount = orderDetails["brokerOffer"] ?? "Pending";

    final String builtyNumber = "BLT-88214";
    final String builtyStatus = "Generated";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
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

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requestId,
                              style: TextStyle(
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

                  status != "rejected"
                      ? SizedBox(
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
                                Icon(
                                  Icons.local_shipping_outlined,
                                  color: Appcolors.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Track Order Status",
                                  style: TextStyle(
                                    color: Appcolors.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Appcolors.primaryBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),

                  SizedBox(height: isMobile ? 24 : 30),

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
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Appcolors.secondaryPurple.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            brokerName
                                .trim()
                                .split(RegExp(r"\s+"))
                                .map((e) => e.isNotEmpty ? e[0] : "")
                                .take(2)
                                .join()
                                .toUpperCase(),
                            style: TextStyle(
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
                                brokerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    brokerLocation,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: Colors.amber[600],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    "$brokerRating",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {},
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Appcolors.secondaryPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.call_outlined,
                              color: Appcolors.secondaryPurple,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 22 : 26),

                  const _SectionLabel("Route"),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    iconColor: Appcolors.primaryBlue,
                    child: Text(
                      "$pickup  ➜  $drop",
                      style: TextStyle(
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
                          style: TextStyle(
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

                  const _SectionLabel("Accepted Amount"),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: status != "rejected"
                          ? Appcolors.tertiaryGreen.withOpacity(0.08)
                          : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: status != "rejected"
                            ? Appcolors.tertiaryGreen.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              status != "rejected"
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline_sharp,
                              color: status != "rejected"
                                  ? Appcolors.tertiaryGreen
                                  : Colors.red,

                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status != "rejected"
                                  ? "Broker accepted your quote at"
                                  : "Broker rejected Your quote",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        status != "rejected"
                            ? Text(
                                "PKR ${acceptedAmount.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Appcolors.tertiaryGreen,
                                ),
                              )
                            : Text(""),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 30 : 36),

                  status != "rejected" ? _SectionLabel("Builty") : Container(),
                  const SizedBox(height: 10),
                  status != "rejected"
                      ? Container(
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
                                child: Icon(
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
                                      style: TextStyle(
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
                                          decoration: BoxDecoration(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuiltyPage(
                                        driverName: "Not Assigned yet",
                                        transportName: "Not Assigned yet",
                                        orderId: orderDetails["orderNo"],
                                        brokerName: orderDetails["brokerId"],
                                        date: orderDetails["date"],
                                        docNo: "1234",
                                        fromLocation:
                                            orderDetails["pickupComp"],
                                        itemType: orderDetails["itemType"],
                                        price: orderDetails["brokerOffer"],
                                        toLocation: orderDetails["dropComp"],
                                        userName: orderDetails["userUid"],
                                        weight: orderDetails["weight"],
                                        quantity: orderDetails["quantity"],
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
                        )
                      : Container(),

                  SizedBox(height: isMobile ? 20 : 26),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =====================================================================
// UI-only helper widgets below, matching the rest of the app's theme.
// =====================================================================

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
