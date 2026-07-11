// // import 'package:flutter/material.dart';
// // import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

// // class BrokerIcomingReqContainer extends StatelessWidget {
// //   const BrokerIcomingReqContainer({
// //     super.key,
// //     required this.orderNumber,
// //     required this.pickupLocation,
// //     required this.dropLocation,
// //     required this.date,
// //     required this.status,
// //     required this.weight,
// //     required this.itemType,
// //     this.onTap, required this.orderId,
// //   });
// //   final String orderNumber;
// //   final String pickupLocation;
// //   final String dropLocation;
// //   final String date;
// //   final int weight;
// //   final String itemType;
// //   final String status;
// //   final String orderId;
// //   final VoidCallback? onTap;

// //   @override
// //   Widget build(BuildContext context) {
// //     return InkWell(
// //       onTap: onTap,
// //       child: Container(
// //         margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
// //         decoration: BoxDecoration(
// //           color: const Color.fromARGB(255, 252, 253, 255),
// //           borderRadius: BorderRadius.circular(10),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.grey.withOpacity(0.3),
// //               spreadRadius: 1,
// //               blurRadius: 1,
// //               offset: Offset(0, 1), // changes position of shadow
// //             ),
// //           ],
// //         ),
// //         width: double.infinity,
// //         //height: 80,
// //         padding: EdgeInsets.symmetric(horizontal: 10),

// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           crossAxisAlignment: CrossAxisAlignment.start,

// //           children: [
// //             Text(
// //               "Order #$orderNumber",
// //               style: TextStyle(
// //                 color: Colors.black,
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             Flexible(

// //               child: Row(
// //                 children: [
// //                   Text(
// //                     pickupLocation,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: TextStyle(
// //                       color: const Color.fromARGB(255, 123, 123, 123),
// //                       fontSize: 11,
// //                     ),
// //                   ),
// //                   Icon(
// //                     Icons.arrow_forward,
// //                     size: 11,
// //                     color: const Color.fromARGB(255, 123, 123, 123),
// //                   ),
// //                   Text(
// //                     dropLocation,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: TextStyle(
// //                       color: const Color.fromARGB(255, 123, 123, 123),
// //                       fontSize: 11,
// //                     ),
// //                   ),
// //                   Spacer(),
// //                   Container(
// //                     padding: EdgeInsets.all(4),
// //                     decoration: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(5),
// //                       color: const Color.fromARGB(255, 224, 215, 245),
// //                     ),
// //                     child: Text(
// //                       "New",
// //                       style: TextStyle(
// //                         color: Appcolors.secondaryPurple,
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 11,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Row(
// //               children: [
// //                 Text(
// //                   weight.toString(),
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.black,
// //                     fontSize: 11,
// //                   ),
// //                 ),
// //                 Icon(
// //                   Icons.linear_scale_sharp,
// //                   size: 11,
// //                   color: const Color.fromARGB(255, 51, 51, 51),
// //                 ),
// //                 Text(
// //                   itemType,
// //                   style: TextStyle(
// //                     color: Colors.black,
// //                     fontSize: 11,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             Text(
// //               date,
// //               style: TextStyle(
// //                 color: const Color.fromARGB(255, 123, 123, 123),
// //                 fontSize: 11,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

// class BrokerIcomingReqContainer extends StatelessWidget {
//   const BrokerIcomingReqContainer({
//     super.key,
//     required this.orderNumber,
//     required this.pickupLocation,
//     required this.dropLocation,
//     required this.date,
//     required this.status,
//     required this.weight,
//     required this.itemType,
//     this.onTap,
//     required this.orderId,
//   });
//   final String orderNumber;
//   final String pickupLocation;
//   final String dropLocation;
//   final String date;
//   final int weight;
//   final String itemType;
//   final String status;
//   final String orderId;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 252, 253, 255),
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 1,
//               blurRadius: 1,
//               offset: const Offset(0, 1),
//             ),
//           ],
//         ),
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Order #$orderNumber",
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Row(
//               children: [
//                 Flexible(
//                   child: Text(
//                     pickupLocation,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       color: Color.fromARGB(255, 123, 123, 123),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//                 const Icon(
//                   Icons.arrow_forward,
//                   size: 11,
//                   color: Color.fromARGB(255, 123, 123, 123),
//                 ),
//                 Flexible(
//                   child: Text(
//                     dropLocation,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       color: Color.fromARGB(255, 123, 123, 123),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(5),
//                     color: const Color.fromARGB(255, 224, 215, 245),
//                   ),
//                   child: Text(
//                     "New",
//                     style: TextStyle(
//                       color: Appcolors.secondaryPurple,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Text(
//                   weight.toString(),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                     fontSize: 11,
//                   ),
//                 ),
//                 const Icon(
//                   Icons.linear_scale_sharp,
//                   size: 11,
//                   color: Color.fromARGB(255, 51, 51, 51),
//                 ),
//                 const SizedBox(width: 4),
//                 Flexible(
//                   child: Text(
//                     itemType,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               date,
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//               style: const TextStyle(
//                 color: Color.fromARGB(255, 123, 123, 123),
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class BrokerIcomingReqContainer extends StatelessWidget {
  const BrokerIcomingReqContainer({
    super.key,
    required this.orderNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.status,
    required this.weight,
    required this.itemType,
    this.onTap,
    required this.orderId,
  });
  final String orderNumber;
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final int weight;
  final String itemType;
  final String status;
  final String orderId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 252, 253, 255),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #$orderNumber",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                // Everything before the badge shares this fixed space,
                // so the badge always lands at the far right edge.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          pickupLocation,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 123, 123, 123),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        
                        color: Color.fromARGB(255, 30, 30, 30),
                      ),
                      Flexible(
                        child: Text(
                          dropLocation,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 123, 123, 123),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color.fromARGB(255, 224, 215, 245),
                  ),
                  child: Text(
                    "New",
                    style: TextStyle(
                      color: Appcolors.secondaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  weight.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
                const Icon(
                  Icons.linear_scale_sharp,
                  size: 11,
                  color: Color.fromARGB(255, 51, 51, 51),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    itemType,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color.fromARGB(255, 123, 123, 123),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}