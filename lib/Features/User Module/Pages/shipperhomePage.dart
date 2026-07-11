import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/offerCard.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/createorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/homequickcontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/ordercontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperhomebox.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetailState.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetialCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/userstate.dart';

class ShipperHomePage extends StatefulWidget {
  const ShipperHomePage({super.key});

  @override
  State<ShipperHomePage> createState() => _ShipperHomePageState();
}

class _ShipperHomePageState extends State<ShipperHomePage> {
  bool _dialogShowing = false;

  @override
  void initState() {
    context.read<UserCubit>().fetchUserData();
    context.read<OrderDetailCubit>().fetchOrderDetails(
      context.read<UserCubit>().userId,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: BlocListener<UserCubit, UserState>(
      //   listener: (context, state) {
      //     if (state is BrokerOfferState) {
            // showDialog(
            //   context: context,
            //   barrierDismissible: false,
            //   builder: (_) {
            //     return AlertDialog(
            //       title: const Text("Broker Offer"),

            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             "Broker offered PKR ${state.requestData["brokerOffer"]}",
            //           ),

            //           const SizedBox(height: 10),

            //           Text("Do you want to accept this offer?"),
            //         ],
            //       ),

            //       actions: [
            //         TextButton(
            //           onPressed: () {
            //             context.read<UserCubit>().acceptOffer(
            //               state.requestData["requestId"],
            //             );

            //             Navigator.pop(context);
            //           },

            //           child: const Text("Accept"),
            //         ),

            //         TextButton(
            //           onPressed: () {
            //             context.read<UserCubit>().rejectOffer(
            //               state.requestData["requestId"],
            //             );

            //             Navigator.pop(context);
            //           },

            //           child: const Text("Reject"),
            //         ),
            //       ],
            //     );
            //   },
            // );
            body: BlocListener<UserCubit, UserState>(
  listener: (context, state) async {
    if (state is BrokerOfferState && !_dialogShowing) {
      _dialogShowing = true;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: OfferCard(
              brokerName: "Ali",
              fare: "${state.requestData["brokerOffer"]}",
              eta: "1 hour",
              rating: 4.5,
              onAccept: () {
                context.read<UserCubit>().acceptOffer(
                  state.requestData["requestId"],
                );
                Navigator.of(dialogContext).pop();
              },
              onReject: () {
                context.read<UserCubit>().rejectOffer(
                  state.requestData["requestId"],
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
      );

      _dialogShowing = false;
    }
  },
  child: SafeArea(
          //   @override
          // void initState() {
          //   super.initState();

          //   context.read<UserCubit>().fetchUserData();
          // }

          // @override
          // Widget build(BuildContext context) {
          //   return Scaffold(
          //     body: BlocListener<UserCubit, UserState>(
          //       listener: (context, state) async {
          //         // Fetch orders after user data is loaded
          //         if (state is UserLoadedState) {
          //           context.read<OrderDetailCubit>().fetchOrderDetails(state.uid);
          //         }

          //         // Show broker offer dialog
          //         if (state is BrokerOfferState &&
          //             !_dialogShowing &&
          //             mounted) {
          //           _dialogShowing = true;

          //           await showDialog(
          //             context: context,
          //             barrierDismissible: false,
          //             builder: (dialogContext) {
          //               return AlertDialog(
          //                 title: const Text("Broker Offer"),
          //                 content: Column(
          //                   mainAxisSize: MainAxisSize.min,
          //                   children: [
          //                     Text(
          //                       "Broker offered PKR ${state.requestData["brokerOffer"]}",
          //                     ),
          //                     const SizedBox(height: 10),
          //                     const Text("Do you want to accept this offer?"),
          //                   ],
          //                 ),
          //                 actions: [
          //                   TextButton(
          //                     onPressed: () async {
          //                       await context.read<UserCubit>().acceptOffer(
          //                             state.requestData["requestId"],
          //                           );

          //                       if (dialogContext.mounted) {
          //                         Navigator.of(dialogContext).pop();
          //                       }
          //                     },
          //                     child: const Text("Accept"),
          //                   ),
          //                   TextButton(
          //                     onPressed: () async {
          //                       await context.read<UserCubit>().rejectOffer(
          //                             state.requestData["requestId"],
          //                           );

          //                       if (dialogContext.mounted) {
          //                         Navigator.of(dialogContext).pop();
          //                       }
          //                     },
          //                     child: const Text("Reject"),
          //                   ),
          //                 ],
          //               );
          //             },
          //           );

          //           if (mounted) {
          //             _dialogShowing = false;
          //           }
          //         }
          //       },
          //       child: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Appcolors.primaryBlue),
                child: Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) {
                        return Text(
                          state is UserLoadedState
                              ? "Hello, ${state.userName} !"
                              : "Hello, Unknown !",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: double.infinity,
                height: double.infinity,
                margin: EdgeInsets.only(top: 60),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        "Book Your Shipment with ease",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 118, 118, 118),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShipperHomeBox(
                            text1: "Create",
                            text2: "Shipment",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateOrderPage(),
                                ),
                              );
                            },
                            icn: Icon(Icons.add_circle, color: Colors.white),
                            clr: Colors.white,
                            ctnclr: Appcolors.primaryBlue,
                          ),
                          SizedBox(width: 30),
                          ShipperHomeBox(
                            text1: "Track",
                            text2: "Order",
                            icn: Icon(
                              Icons.track_changes,
                              color: Appcolors.primaryBlue,
                            ),
                            clr: Colors.black,
                            ctnclr: Color.fromARGB(255, 238, 245, 255),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          HomeQuickContainer(
                            text1: "My Orders",
                            icn: Icon(Icons.list_outlined),
                          ),
                          HomeQuickContainer(
                            text1: "Saved Address",
                            icn: Icon(
                              Icons.bookmark,
                              color: Appcolors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Recent Orders",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      BlocBuilder<OrderDetailCubit, OrderDetailState>(
                        builder: (context, state) {
                          if (state is OrderDetailLoadedState) {
                            final orders = state.orderDetails;

                            if (orders.isEmpty) {
                              return const Center(
                                child: Text("No Orders Available"),
                              );
                            }

                            final lastOrders = orders.length > 2
                                ? orders
                                      .sublist(orders.length - 2)
                                      .reversed
                                      .toList()
                                : orders.reversed.toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: lastOrders.length,
                              itemBuilder: (context, index) {
                                final order = lastOrders[index];

                                return OrderContainer(
                                  orderNumber: order["orderNo"] ?? "",
                                  pickupLocation: order["pickupCity"] ?? "",
                                  dropLocation: order["dropCity"] ?? "",
                                  date: order["date"] ?? "not specified",
                                  status: order["status"] ?? "",
                                );
                              },
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
