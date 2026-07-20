
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/offerCard.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerListPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/createorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperOrderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/ordercontainer.dart';
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
    super.initState();
    context.read<UserCubit>().fetchUserData().then((_) {
      if (!mounted) return;
      context.read<OrderDetailCubit>().fetchOrderDetails(
        context.read<UserCubit>().userId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: BlocListener<UserCubit, UserState>(
        listener: (context, state) async {
          if (state is BrokerOfferState && !_dialogShowing) {
            if (!context.mounted) return;
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

            if (mounted) {
              _dialogShowing = false;
            }
          }
        },
        child: SafeArea(
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
                    
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_outline_sharp,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<UserCubit, UserState>(
                                builder: (context, state) {
                                  return Text(
                                    state is UserLoadedState
                                        ? "Hello, ${state.userName} !"
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
                                "User Dashboard",
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

                    SizedBox(height: isMobile ? 26 : 34),

                   
                    const Text(
                      "Book Your Shipment\nwith ease",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 18),

                    
                    Row(
                      children: [
                        Expanded(
                          child: _HeroActionCard(
                            title1: "Create",
                            title2: "Shipment",
                            icon: Icons.add_circle_outline,
                            filled: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateOrderPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _HeroActionCard(
                            title1: "Track",
                            title2: "Order",
                            icon: Icons.track_changes_outlined,
                            filled: false,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 28 : 34),

                 
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                           onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BrokerListPage(),
                                ),
                              );
                            },
                            label: "All Brokers",
                            icon: Icons.people_alt_rounded,
                            color: Colors.grey[700]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            onTap: () {
                              // Navigate to Saved Address page
                            },
                            label: "Saved Address",
                            icon: Icons.bookmark_outline_rounded,
                            color: Appcolors.primaryBlue,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 28 : 34),

                    
                    const Text(
                      "Recent Orders",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    BlocBuilder<OrderDetailCubit, OrderDetailState>(
                      builder: (context, state) {
                        if (state is OrderDetailLoadedState) {
                          final orders = state.orderDetails;

                          if (orders.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 30,
                              ),
                              child: Center(
                                child: Text(
                                  "No Orders Available",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
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

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: OrderContainer(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShipperOrderDetailPage(
                                         orderDetails:order,
                                        ),
                                      ),
                                    );
                                  },
                                  orderNumber: order["orderNo"] ?? "",
                                  pickupLocation: order["pickupCity"] ?? "",
                                  dropLocation: order["dropCity"] ?? "",
                                  date: order["date"] ?? "not specified",
                                  status: order["status"] ?? "",
                                ),
                              );
                            },
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _HeroActionCard extends StatelessWidget {
  final String title1;
  final String title2;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _HeroActionCard({
    required this.title1,
    required this.title2,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: filled ? Appcolors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (filled ? Appcolors.primaryBlue : Colors.black)
                  .withOpacity(filled ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white.withOpacity(0.18)
                    : Appcolors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: filled ? Colors.white : Appcolors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title1,
              style: TextStyle(
                color: filled ? Colors.white : Colors.black87,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title2,
              style: TextStyle(
                color: filled ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
