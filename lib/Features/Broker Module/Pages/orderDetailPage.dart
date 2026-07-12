// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> orderReqData;
//   const OrderDetailsPage({super.key, required this.orderReqData});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: SafeArea(
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       /// Header
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: () => Navigator.pop(context),
//                             icon: const Icon(Icons.arrow_back_ios_new),
//                           ),
//                           const Expanded(
//                             child: Center(
//                               child: Text(
//                                 "Request Details",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           IconButton(
//                             onPressed: () {},
//                             icon: const Icon(Icons.notifications_none),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),

//                       /// Request ID
//                       const Text(
//                         "REQ12345",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),

//                       const SizedBox(height: 4),

//                       Text(
//                         widget.orderReqData["createdAt"]??"Not Entered",
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 12,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       /// Customer Information
//                       const Text(
//                         "Customer Information",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,

//                         children: [
//                           const Icon(
//                             Icons.location_on,
//                             color: Colors.blue,
//                             size: 22,
//                           ),
//                           const SizedBox(width: 12),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children:  [
//                               Text(
//                              widget.orderReqData["name"]??"Not Entered",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 widget.orderReqData["phone"]??"Not Entered",
//                                 style: TextStyle(fontSize: 14),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),

//                       /// Route
//                       const Text(
//                         "Route",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       Row(
//                         children: [
//                           Icon(
//                             Icons.circle,
//                             color: Colors.deepPurple,
//                             size: 10,
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               "${widget.orderReqData["pickupCity"]??"Not Entered"} ➜ ${widget.orderReqData["dropCity"]??"Not Entered"}",
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 36),

//                       /// Item Details
//                       const Text(
//                         "Item Details",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Icon(
//                             Icons.inventory_2,
//                             color: Colors.green,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "${widget.orderReqData["itemType"]??"Null"}, ${widget.orderReqData["weight"]??0}, ${widget.orderReqData["quantity"]??0} Units",
//                                   style: TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   widget.orderReqData["description"],
//                                   style: TextStyle(fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 26),

//                       /// Quote
//                       const Text(
//                         "Your Quote (Pkr)",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 10),

//                       Container(
//                         width: double.infinity,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(width: 1),
//                         ),
//                         child: TextField(
//                           textAlign: TextAlign.center,
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Enter Your Amount",
//                             contentPadding: EdgeInsets.symmetric(vertical: 15),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),

//                       ContinueButton(
//                         text: "Submit Quote",
//                         clr: Appcolors.secondaryPurple,
//                         onTap: () {},
//                       ),

//                       const SizedBox(height: 10),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

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

  void submitQuote() async {
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

    /// TODO :
    /// Upload amount to Firestore here.
    ///
    await FirebaseFirestore.instance
        .collection("User")
        .doc(widget.orderReqData["userUid"])
        .collection("Requests")
        .doc(widget.orderReqData["orderId"])
        .update({"brokerOffer": amount, "status": "fare_offered"});

    await FirebaseFirestore.instance
        .collection("Broker")
        .doc(widget.orderReqData["brokerId"])
        .collection("IncomingRequests")
        .doc(widget.orderReqData["orderId"])
        .update({"brokerOffer": amount, "status": "fare_offered"});

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Quote Submitted: PKR ${amount.toStringAsFixed(0)}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderReqData;

    final requestId = "Order No # " + data["orderNo"];
    
    final createdAt = data["createdAt"] ?? "Time not available";

    final customerName = data["userUid"] ?? "userId not available";
    final phone = data["phone"] ?? "Phone not available";

    final pickup = data["pickupCity"] ?? "Pickup city not available";
    final drop = data["dropCity"] ?? "Drop city not available";

    final itemType = data["itemType"] ?? "Unknown";
    final weight = data["weight"] ?? "0";
    final quantity = data["quantity"] ?? "0";
    final description = data["additionalInfo"] ?? "No description available.";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  const SizedBox(height: 25),

                  Text(
                    requestId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    createdAt.toString(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Customer Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(phone, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Route",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "$pickup  ➜  $drop",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Item Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Weight : $weight kg",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Quantity : $quantity",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "Your Quote (PKR)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: quoteController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Enter Your Quote",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ContinueButton(
                    text: "Submit Quote",
                    clr: Appcolors.secondaryPurple,
                    onTap: submitQuote,
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
