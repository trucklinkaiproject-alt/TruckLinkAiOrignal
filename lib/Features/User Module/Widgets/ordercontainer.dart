
import 'package:flutter/material.dart';


class OrderContainer extends StatelessWidget {
  const OrderContainer({
    super.key,
    required this.orderNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.status,
  });

  final String orderNumber;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final String status;
  

  @override
  Widget build(BuildContext context) {
    Color clr;

    switch (status.toLowerCase()) {
      case "pending":
        clr = Colors.amber;
        break;
      case "in transit":
        clr = Colors.blue;
        break;
      case "cancelled":
        clr = Colors.red;
        break;
      case "rejected":
        clr = Colors.red;
        break;
      case "delivered":
        clr = Colors.green;
        break;
      case "accepted":
        clr = Colors.green;
        break;
      default:
        clr = Colors.grey;
    }
    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    final double containerHeight = isMobile
        ? 90
        : isTablet
        ? 100
        : 115;

    final double titleSize = isMobile
        ? 14
        : isTablet
        ? 16
        : 18;

    final double textSize = isMobile
        ? 12
        : isTablet
        ? 14
        : 16;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: double.infinity,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 252, 253, 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #$orderNumber",
            style: TextStyle(
              color: Colors.black,
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  "$pickupLocation → $dropLocation",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 123, 123, 123),
                    fontSize: textSize,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: clr.withOpacity(0.1),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: clr,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 11 : 13,
                  ),
                ),
              ),
            ],
          ),

          Text(
            date,
            style: TextStyle(
              color: const Color.fromARGB(255, 123, 123, 123),
              fontSize: textSize,
            ),
          ),
        ],
      ),
    );
  }
}
