// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/widgets/brokerincomingreqcontainer.dart';

// class BrokerHomePage extends StatefulWidget {
//   const BrokerHomePage({super.key});

//   @override
//   State<BrokerHomePage> createState() => _BrokerHomePageState();
// }

// class _BrokerHomePageState extends State<BrokerHomePage> {
//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<BrokerCubit>().fetchUserData();
//       context.read<BrokerCubit>().fetchIncomingReq();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Container(
//               width: double.infinity,
//               height: 70,
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               decoration: BoxDecoration(color: Appcolors.secondaryPurple),
//               child: Row(
//                 //mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   BlocBuilder<BrokerCubit, BrokerState>(
//                     builder: (context, state) {
//                       return Text(
//                         state is BrokerLoadedState
//                             ? "Hello, ${state.userData} !"
//                             : "Hello, Unknown !",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       );
//                     },
//                   ),
//                   Spacer(),
//                   IconButton(
//                     onPressed: () {},
//                     icon: Icon(
//                       Icons.notifications_none_rounded,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               width: double.infinity,
//               height: double.infinity,
//               margin: EdgeInsets.only(top: 60),
//               decoration: BoxDecoration(
//                 color: const Color.fromARGB(255, 255, 255, 255),
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Broker, Dashboard",
//                       style: TextStyle(
//                         fontSize: 19,
//                         fontWeight: FontWeight.bold,
//                         color: Appcolors.secondaryPurple,
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         brokerHomeContainer(
//                           "18",
//                           "New Request",
//                           const Color.fromARGB(255, 239, 233, 250),
//                           Appcolors.secondaryPurple,
//                           const Color.fromARGB(255, 154, 137, 192),
//                         ),
//                         brokerHomeContainer(
//                           "20",
//                           "Active Orders",
//                           const Color.fromARGB(255, 255, 252, 224),
//                           Colors.black,
//                           Colors.black,
//                         ),
//                         brokerHomeContainer(
//                           "56",
//                           "Completed",
//                           const Color.fromARGB(255, 217, 252, 235),
//                           Colors.black,
//                           Colors.black,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 35),
//                     Row(
//                       children: [
//                         Text(
//                           "Incoming Orders",
//                           style: TextStyle(
//                             color: Appcolors.secondaryPurple,
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Spacer(),
//                         Text(
//                           "View All",
//                           style: TextStyle(
//                             color: Color.fromARGB(255, 143, 133, 168),
//                             fontSize: 13,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 15),
//                     BlocBuilder<BrokerCubit, BrokerState>(
//                       builder: (context, state) {
//                         state is BrokerLoadingState
//                             ? CircularProgressIndicator()
//                             : Container();
//                         return state is BrokerLoadedState
//                             ? ListView.builder(
//                                 shrinkWrap: true,
//                                 physics: NeverScrollableScrollPhysics(),
//                                 itemCount: state.incomingRequests!.length,
//                                 itemBuilder: (context, index) {
//                                   index = state.incomingRequests!.length-1-index;
//                                   final request = state.incomingRequests![index];
//                                   return BrokerIcomingReqContainer(
//                                     orderNumber: request["orderNo"] ?? "",
//                                     pickupLocation: request["pickupCity"] ?? "",
//                                     dropLocation: request["dropCity"] ?? "",
//                                     date: request["createdAt"] ?? "",
//                                     status: request["status"] ?? "",
//                                     weight: request["weight"] ?? 0,
//                                     itemType: request["itemType"] ?? "",
//                                     orderId: request["orderId"],
//                                     onTap: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               OrderDetailsPage(
//                                                 orderReqData: state
//                                                     .incomingRequests![index],
//                                               ),
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 },
//                               )
//                             : Center(child: Text("No Request yet"));
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget brokerHomeContainer(
//     String quantity,
//     String text,
//     Color clr,
//     Color? noClr,
//     Color? txtClr,
//   ) {
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.28,
//       height: 100,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         color: clr,
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             quantity,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//               color: noClr ?? Colors.black,
//             ),
//           ),
//           SizedBox(height: 10),
//           Text(
//             text,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//               color: txtClr ?? Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/widgets/brokerincomingreqcontainer.dart';

class BrokerHomePage extends StatefulWidget {
  const BrokerHomePage({super.key});

  @override
  State<BrokerHomePage> createState() => _BrokerHomePageState();
}

class _BrokerHomePageState extends State<BrokerHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokerCubit>().fetchUserData();
      context.read<BrokerCubit>().fetchIncomingReq();
    });
  }

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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Appcolors.secondaryPurple,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.interpreter_mode_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocBuilder<BrokerCubit, BrokerState>(
                              builder: (context, state) {
                                return Text(
                                  state is BrokerLoadedState
                                      ? "Hello, ${state.userData} !"
                                      : "Hello, Unknown !",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Broker Dashboard",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {},
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue.withOpacity(0.2),
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
                            Icons.message_outlined,
                            color: Appcolors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 26 : 34),

                  // -------- Stat cards (same 18 / 20 / 56 values) --------
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: "18",
                          label: "New Request",
                          icon: Icons.mark_email_unread_outlined,
                          color: Appcolors.secondaryPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: "20",
                          label: "Active Orders",
                          icon: Icons.local_shipping_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: "56",
                          label: "Completed",
                          icon: Icons.check_circle_outline,
                          color: Appcolors.tertiaryGreen,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 30 : 38),

                  // -------- Incoming Orders header --------
                  Row(
                    children: [
                      Text(
                        "Incoming Orders",
                        style: TextStyle(
                          color: Appcolors.secondaryPurple,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "View All",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // -------- Incoming requests list (same logic) --------
                  BlocBuilder<BrokerCubit, BrokerState>(
                    builder: (context, state) {
                      state is BrokerLoadingState
                          ? CircularProgressIndicator()
                          : Container();
                      return state is BrokerLoadedState
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.incomingRequests!.length,
                              itemBuilder: (context, index) {
                                index =
                                    state.incomingRequests!.length - 1 - index;
                                final request = state.incomingRequests![index];
                                return BrokerIcomingReqContainer(
                                  orderNumber: request["orderNo"] ?? "",
                                  pickupLocation: request["pickupCity"] ?? "",
                                  dropLocation: request["dropCity"] ?? "",
                                  date: request["createdAt"] ?? "",
                                  status: request["status"] ?? "",
                                  weight: request["weight"] ?? 0,
                                  itemType: request["itemType"] ?? "",
                                  orderId: request["orderId"],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          orderReqData:
                                              state.incomingRequests![index],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  "No Request yet",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            );
                    },
                  ),
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
// UI-only helper widget, matching the app's theme. No business logic
// lives here — same static values (18 / 20 / 56) as before.
// =====================================================================

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
