import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';

class OrderTrackingPage extends StatelessWidget {
  final Map<String, dynamic> orderStatusDetail;
   const OrderTrackingPage({super.key, required this.orderStatusDetail});

  @override
  Widget build(BuildContext context) {
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
                  // -------- Header --------
                  Row(
                    children: [
                      BackArrowButton(onTap: () => Navigator.pop(context),),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Order Tracking",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _RoundIconButton(
                        icon: Icons.search,
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 26 : 32),

                  // -------- Order ID --------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: Appcolors.primaryBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Order ID: TL - ${orderStatusDetail["orderNo"]}",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 30 : 38),

                  // -------- Timeline --------
                  const _SectionLabel("Shipment Progress"),
                  const SizedBox(height: 18),

                   TimelineTileWidget(
                    title: "Pending",
                    subtitle: "12 May 2024, 09:30 AM",
                    isCompleted: orderStatusDetail["status"]=="pending"?true:false,
                    isLast: false,
                  ),

                  TimelineTileWidget(
                    title: "Accepted by Broker",
                    subtitle: "12 May 2024, 11:55 AM",
                    isCompleted:orderStatusDetail["status"]=="accepted"?true:false,
                    isLast: false,
                  ),

                   TimelineTileWidget(
                    title: "In Transit",
                    subtitle: "13 May 2024, 08:20 AM",
                    isCompleted: orderStatusDetail["status"]=="assignDriver"?true:false,
                    isLast: false,
                    highlight: true,
                  ),

                   TimelineTileWidget(
                    title: "Out for Delivery",
                    subtitle: "",
                    isCompleted: orderStatusDetail["status"]=="outForDelivery"?true:false,
                    isLast: false,
                  ),

                   TimelineTileWidget(
                    title: "Delivered",
                    subtitle: "",
                    isCompleted:orderStatusDetail["status"]=="delivered"?true:false,
                    isLast: true,
                  ),

                  const SizedBox(height: 10),

                  // -------- Current Location card --------
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Current Location",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Near Vadodara, Gujarat",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "View on Map",
                                      style: TextStyle(
                                        color: Appcolors.primaryBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Appcolors.primaryBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {},
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Appcolors.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.call_outlined,
                              color: Appcolors.primaryBlue,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 20 : 30),
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
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
        child: Icon(icon, color: Colors.black87, size: 19),
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

class TimelineTileWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;
  final bool highlight;

  const TimelineTileWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Appcolors.primaryBlue;
    final Color inactiveColor = Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Timeline dot + connector --------
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted ? activeColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? activeColor : inactiveColor,
                    width: 2,
                  ),
                  boxShadow: highlight
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // -------- Text --------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          highlight ? FontWeight.w800 : FontWeight.w600,
                      color: highlight
                          ? activeColor
                          : isCompleted
                              ? Colors.black87
                              : Colors.grey[500],
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}