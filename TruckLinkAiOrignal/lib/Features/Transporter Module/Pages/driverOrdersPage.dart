import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverOfferDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverState.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverOffersBloc/driverOffersCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverOffersBloc/driverOffersState.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/ordercontainer.dart';

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabLabels = [
    "Pending",
    "Accepted",
    "In Transit",
    "Completed",
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverState = context.read<DriverCubit>().state;
      if (driverState is DriverLoadedState) {
        context.read<DriverOffersCubit>().listenToOffers(
          driverId: driverState.driver.driverId,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOffers(
    List<Map<String, dynamic>> allOffers,
    String category,
  ) {
    switch (category) {
      case 'Pending':
        return allOffers.where((offer) {
          final status = (offer['status'] ?? 'pending').toString().toLowerCase();
          return status == 'pending' ||
              status == 'driver_offer_sent' ||
              status == 'incoming';
        }).toList();
      case 'Accepted':
        return allOffers.where((offer) {
          final status = (offer['status'] ?? '').toString().toLowerCase();
          return status == 'accepted_by_driver' || status == 'accepted';
        }).toList();
      case 'In Transit':
        return allOffers.where((offer) {
          final status = (offer['status'] ?? '').toString().toLowerCase();
          return status == 'in_transit' ||
              status == 'in_progress' ||
              status == 'arrived_at_pickup' ||
              status == 'heading_to_drop';
        }).toList();
      case 'Completed':
        return allOffers.where((offer) {
          final status = (offer['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status == 'delivered';
        }).toList();
      case 'Cancelled':
        return allOffers.where((offer) {
          final status = (offer['status'] ?? '').toString().toLowerCase();
          return status == 'rejected_by_driver' ||
              status == 'cancelled' ||
              status == 'rejected';
        }).toList();
      default:
        return allOffers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildTabBar(),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabLabels.map((label) => _buildOrdersTab(label)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: Colors.white,
      title: const Text(
        "Driver Orders",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          onPressed: () {
            final driverState = context.read<DriverCubit>().state;
            if (driverState is DriverLoadedState) {
              context.read<DriverOffersCubit>().listenToOffers(
                driverId: driverState.driver.driverId,
              );
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildTabBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;
        final double horizontalMargin = isMobile ? 12 : (width < 1000 ? width * 0.05 : width * 0.08);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: isMobile,
            tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
            indicator: BoxDecoration(
              color: Appcolors.tertiaryGreen,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.tertiaryGreen.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(30),
            tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab(String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;
        final double horizontalPadding = isMobile ? 16 : (width < 1000 ? width * 0.05 : width * 0.08);

        return BlocBuilder<DriverOffersCubit, DriverOffersState>(
          builder: (context, state) {
            if (state is DriverOffersLoadingState) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Appcolors.tertiaryGreen,
                ),
              );
            }

            if (state is DriverOffersErrorState) {
              return _buildErrorState(state.errorMessage);
            }

            if (state is DriverOffersLoadedState) {
              final filtered = _filterOffers(state.offers, category);

              if (filtered.isEmpty) {
                return _buildEmptyState(category);
              }

              return RefreshIndicator(
                color: Appcolors.tertiaryGreen,
                onRefresh: () async {
                  final driverState = context.read<DriverCubit>().state;
                  if (driverState is DriverLoadedState) {
                    context.read<DriverOffersCubit>().listenToOffers(
                      driverId: driverState.driver.driverId,
                    );
                  }
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = filtered.length - 1 - index;
                    final offer = filtered[reversedIndex];
                    return _buildOrderCard(offer);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> offer) {
    final String orderNo = (offer["order_no"] ?? offer["orderNo"] ?? offer["order_id"] ?? offer["orderId"] ?? "").toString();
    
    final String pickupCity = (offer["pickup_city"] ?? offer["pickupCity"] ?? "N/A").toString();
    final String dropCity = (offer["drop_city"] ?? offer["dropCity"] ?? "N/A").toString();
    final String date = (offer["date"] ?? offer["created_at"] ?? "Recent").toString();
    final String rawStatus = (offer["status"] ?? "pending").toString().toLowerCase();

    return OrderContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverOfferDetailPage(offer: offer),
          ),
        );
      },
      orderNumber: orderNo,
      pickupLocation: pickupCity,
      dropLocation: dropCity,
      date: date,
      status: rawStatus,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load driver orders",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final driverState = context.read<DriverCubit>().state;
                if (driverState is DriverLoadedState) {
                  context.read<DriverOffersCubit>().listenToOffers(
                    driverId: driverState.driver.driverId,
                  );
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.tertiaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Appcolors.tertiaryGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: Appcolors.tertiaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No $category orders",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your $category orders will appear here",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
