// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/heading.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';

// class BrokerDetailPage extends StatefulWidget {
//   const BrokerDetailPage({super.key, required this.brokerData});
//   final Map<String, dynamic> brokerData;

//   @override
//   State<BrokerDetailPage> createState() => _BrokerDetailPageState();
// }

// class _BrokerDetailPageState extends State<BrokerDetailPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: BouncingScrollPhysics(),
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 35),
//             color: Appcolors.background,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 AppBarContainer(
//                   title: widget.brokerData["name"],
//                   backArrow: true,
//                 ),

//                 SizedBox(height: 20),
//                 Heading(text: "Broker Details"),
//                 SizedBox(height: 10),
//                 Container(
//                   width: double.infinity,

//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             "Broker ID #  ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["uid"],
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Text(
//                             "Location: ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["location"] ??
//                                 "Not specify by broker",
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Text(
//                             "Contact No: ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["phone"],
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Text(
//                             "Email: ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["email"],
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Text(
//                             "Rattings: ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["rating"] ?? "4.5 (200 reviews)",
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Text(
//                             "Estimated Time: ",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             widget.brokerData["estimatedTime"] ?? "2 hours",
//                             style: TextStyle(
//                               color: const Color.fromARGB(255, 45, 45, 45),
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),

//                 // Container(
//                 //   child: Row(
//                 //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 //     children: [
//                 //       Text(
//                 //         "Fare Demanded: ",
//                 //         style: TextStyle(
//                 //           color: Colors.black,
//                 //           fontSize: 12,
//                 //           fontWeight: FontWeight.bold,
//                 //         ),
//                 //       ),
//                 //       Container(
//                 //         width: 150,
//                 //         padding: EdgeInsets.all(15),
//                 //         decoration: BoxDecoration(
//                 //           color: Colors.white,
//                 //           borderRadius: BorderRadius.circular(5),
//                 //         ),
//                 //         child: Center(
//                 //           child: Text(
//                 //             " Not Accepted yet",
//                 //             style: TextStyle(
//                 //               color: Colors.black,
//                 //               fontSize: 12,
//                 //               fontWeight: FontWeight.bold,
//                 //             ),
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//                 // SizedBox(height: 20),
//                 // Container(
//                 //   child: Row(
//                 //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 //     children: [
//                 //       Text(
//                 //         "Your Offer: ",
//                 //         style: TextStyle(
//                 //           color: Colors.black,
//                 //           fontSize: 12,
//                 //           fontWeight: FontWeight.bold,
//                 //         ),
//                 //       ),
//                 //       Container(
//                 //         width: 150,
//                 //         height: 50,

//                 //         decoration: BoxDecoration(
//                 //           color: Colors.white,

//                 //           borderRadius: BorderRadius.circular(5),
//                 //         ),
//                 //         child: TextField(
//                 //           textAlign: TextAlign.center,
//                 //           decoration: InputDecoration(
//                 //             hintText: "Enter your offer",
//                 //             hintStyle: TextStyle(
//                 //               color: Colors.grey,
//                 //               fontSize: 13,
//                 //             ),
//                 //             border: InputBorder.none,
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//                 SizedBox(height: 20),
//                 InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => BrokerChatPage(
//                           brokerId: widget.brokerData["uid"],
//                           brokerName: widget.brokerData["name"],
//                           chatId: "12345678",
//                         ),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color.fromARGB(255, 209, 190, 255),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: ListTile(
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Appcolors.secondaryPurple,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(Icons.chat, color: Colors.white, size: 20),
//                       ),
//                       title: Text(
//                         "Chat with Broker",
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text(
//                         "Discuss your requirements and negotiate terms",
//                         style: TextStyle(
//                           color: const Color.fromARGB(255, 45, 45, 45),
//                           fontSize: 10,
//                         ),
//                       ),
//                       trailing: Icon(
//                         Icons.arrow_forward_ios,
//                         color: Appcolors.secondaryPurple,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 30),

//                 BlocBuilder<CreateReqCubit, CreateReqState>(
//                   builder: (context, state) {
//                     return ContinueButton(
//                       text: state is CreateReqLoadingState
//                           ? "Sending ..."
//                           : "Send Request",
//                       clr: Appcolors.primaryBlue,
//                       onTap: () {
//                         context.read<CreateReqCubit>().createRequestToBroker(
//                           widget.brokerData["uid"],
//                         );
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ShipperBottomNavBar(),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 Heading(text: "Reviews"),
//                 SizedBox(height: 10),
//                 Container(
//                   width: double.infinity,
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             "Jane Smith",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Icon(Icons.star, color: Colors.amber, size: 15),
//                           SizedBox(width: 5),
//                           Text(
//                             "5/5",
//                             style: TextStyle(color: Colors.grey, fontSize: 10),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
//                         style: TextStyle(
//                           color: const Color.fromARGB(255, 45, 45, 45),
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   width: double.infinity,
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             "Jane Smith",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Icon(Icons.star, color: Colors.amber, size: 15),
//                           SizedBox(width: 5),
//                           Text(
//                             "5/5",
//                             style: TextStyle(color: Colors.grey, fontSize: 10),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
//                         style: TextStyle(
//                           color: const Color.fromARGB(255, 45, 45, 45),
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   width: double.infinity,
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             "Jane Smith",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Icon(Icons.star, color: Colors.amber, size: 15),
//                           SizedBox(width: 5),
//                           Text(
//                             "5/5",
//                             style: TextStyle(color: Colors.grey, fontSize: 10),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
//                         style: TextStyle(
//                           color: const Color.fromARGB(255, 45, 45, 45),
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';

class BrokerDetailPage extends StatefulWidget {
  const BrokerDetailPage({super.key, required this.brokerData});
  final Map<String, dynamic> brokerData;

  @override
  State<BrokerDetailPage> createState() => _BrokerDetailPageState();
}

class _BrokerDetailPageState extends State<BrokerDetailPage> {
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
              physics: const BouncingScrollPhysics(),
              child: Padding(
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.brokerData["name"] ?? "Broker",
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 22 : 28),

                    // -------- Broker Details --------
                    const _SectionLabel("Broker Details"),
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
                          _DetailRow(
                            icon: Icons.badge_outlined,
                            label: "Broker ID",
                            value: widget.brokerData["uid"],
                          ),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: "Location",
                            value:
                                widget.brokerData["location"] ??
                                "Not specify by broker",
                          ),
                          _DetailRow(
                            icon: Icons.call_outlined,
                            label: "Contact No",
                            value: widget.brokerData["phone"],
                          ),
                          _DetailRow(
                            icon: Icons.email_outlined,
                            label: "Email",
                            value: widget.brokerData["email"],
                          ),
                          _DetailRow(
                            icon: Icons.star_border_rounded,
                            label: "Ratings",
                            value:
                                widget.brokerData["rating"] ??
                                "4.5 (200 reviews)",
                          ),
                          _DetailRow(
                            icon: Icons.schedule_outlined,
                            label: "Estimated Time",
                            value:
                                widget.brokerData["estimatedTime"] ?? "2 hours",
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 22 : 28),

                    // -------- Chat with broker (same navigation) --------
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrokerChatPage(
                              brokerId: widget.brokerData["uid"],
                              brokerName: widget.brokerData["name"],
                              chatId: "12345678",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Appcolors.secondaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Appcolors.secondaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Chat with Broker",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Discuss your requirements and negotiate terms",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Appcolors.secondaryPurple,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 26 : 32),

                    BlocBuilder<CreateReqCubit, CreateReqState>(
                      builder: (context, state) {
                        final bool loading = state is CreateReqLoadingState;

                        return ContinueButton(
                          text: "Send Request",
                          clr: Appcolors.primaryBlue,
                          isLoading: loading,
                          onTap: loading
                              ? null
                              : () async {
                                  await context
                                      .read<CreateReqCubit>()
                                      .createRequestToBroker(
                                        widget.brokerData["uid"],
                                      );

                                  if (!mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ShipperBottomNavBar(),
                                    ),
                                  );
                                },
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 26 : 32),

                    const _SectionLabel("Reviews"),
                    const SizedBox(height: 10),
                    const _ReviewCard(
                      name: "Jane Smith",
                      rating: "5/5",
                      review:
                          "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
                    ),
                    const SizedBox(height: 12),
                    const _ReviewCard(
                      name: "Jane Smith",
                      rating: "5/5",
                      review:
                          "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
                    ),
                    const SizedBox(height: 12),
                    const _ReviewCard(
                      name: "Jane Smith",
                      rating: "5/5",
                      review:
                          "Great experience! The broker was responsive and helped me find the right truck for my shipment.",
                    ),

                    SizedBox(height: isMobile ? 20 : 30),
                  ],
                ),
              ),
            );
          },
        ),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Appcolors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: Appcolors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$value",
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String rating;
  final String review;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.review,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 17),
              const SizedBox(width: 3),
              Text(
                rating,
                style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
