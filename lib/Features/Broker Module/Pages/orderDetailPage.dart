import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Request Details",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Request ID
                      const Text(
                        "REQ12345",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "12 May, 2025, 10:00 AM",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Customer Information
                      const Text(
                        "Customer Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "John Doe",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "+91 9876543210",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Route
                      const Text(
                        "Route",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.deepPurple,
                            size: 10,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Delhi, Delhi ➜ Mumbai, Maharashtra",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      /// Item Details
                      const Text(
                        "Item Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Electronics, 100kg, 5 Units",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Handle with care",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      /// Quote
                      const Text(
                        "Your Quote (Pkr)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 1),
                        ),
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Your Amount",
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      ContinueButton(
                        text: "Submit Quote",
                        clr: Appcolors.secondaryPurple,
                        onTap: () {},
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
