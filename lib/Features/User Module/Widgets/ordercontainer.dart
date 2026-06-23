import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class OrderContainer extends StatelessWidget {
  const OrderContainer({super.key, required this.orderNumber, required this.pickupLocation, required this.dropLocation, required this.date, required this.status});
  final String orderNumber;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10,left: 5,right: 5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 252, 253, 255),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      width: double.infinity,
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 10),
      
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Order #$orderNumber",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                "$pickupLocation",
                style: TextStyle(
                  color: const Color.fromARGB(255, 123, 123, 123),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: const Color.fromARGB(255, 123, 123, 123),
              ),
              Text(
                "$dropLocation",
                style: TextStyle(
                  color: const Color.fromARGB(255, 123, 123, 123),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color.fromARGB(255, 226, 255, 245),
                ),
                child: Text(
                  "$status",
                  style: TextStyle(
                    color: Appcolors.tertiaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            "$date",
            style: TextStyle(color: const Color.fromARGB(255, 123, 123, 123)),
          ),
        ],
      ),
    );
  }
}

