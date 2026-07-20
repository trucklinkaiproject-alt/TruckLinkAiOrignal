
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/getBrokerOrderDetail/getBrokerOrderDetailCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/getBrokerOrderDetail/getBrokerOrderDetailStates.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/ordercontainer.dart';

class BrokerOrderPage extends StatefulWidget {
  const BrokerOrderPage({super.key});

  @override
  State<BrokerOrderPage> createState() => _BrokerOrderPageState();
}

class _BrokerOrderPageState extends State<BrokerOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GetBrokerOrderDetailCubit _getBrokerOrderDetailCubit;

  final List<String?> _tabStatusFilters = [
    null,
    "Pending",
    "accepted",
    "delivered",
    "cancelled",
  ];
  final List<String> _tabLabels = [
    "All",
    "Pending",
    "In Transit",
    "Delivered",
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _getBrokerOrderDetailCubit = GetBrokerOrderDetailCubit();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchForCurrentTab();
      }
    });

    _fetchForCurrentTab();
  }

  void _fetchForCurrentTab() {
    _getBrokerOrderDetailCubit.fetchAllBrokerOrderDetails(
      context.read<BrokerCubit>().brokerId,
      _tabStatusFilters[_tabController.index], // no more force-unwrap
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _getBrokerOrderDetailCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _getBrokerOrderDetailCubit,
      child: Scaffold(
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
                children: List.generate(_tabLabels.length, (index) {
                  return _buildOrderListForTab();
                }),
              ),
            ),
          ],
        ),
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
        "Order History",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () {
            // TODO: implement search
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(1),
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
        indicator: BoxDecoration(
          color: Appcolors.secondaryPurple,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Appcolors.secondaryPurple.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(30),
        tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }

  Widget _buildOrderListForTab() {
    return BlocBuilder<GetBrokerOrderDetailCubit, GetBrokerOrderDetailState>(
      builder: (context, state) {
        if (state is GetBrokerOrderDetailLoadingState) {
          return _buildLoadingState();
        }

        if (state is GetBrokerOrderDetailErrorState) {
          return _buildErrorState(state.error);
        }

        if (state is GetBrokerOrderDetailLoadedState) {
          final orders = state.orderDetails;

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: Colors.blue.shade600,
            onRefresh: () async => _fetchForCurrentTab(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final reversedIndex = orders.length - 1 - index;
                return OrderCard(order: orders[reversedIndex]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
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
              "Couldn't load your orders",
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
              onPressed: _fetchForCurrentTab,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
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

  Widget _buildEmptyState() {
    final currentLabel = _tabLabels[_tabController.index];
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
                      color: Appcolors.secondaryPurple.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: Appcolors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentLabel == "All"
                        ? "No orders yet"
                        : "No $currentLabel orders",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your orders will show up here",
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

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrderContainer(
      onTap: (){},
      orderNumber: order["orderNo"] ?? "",
      pickupLocation: order["pickupCity"] ?? "",
      dropLocation: order["dropCity"] ?? "",
      date: order["date"] ?? "not specified",
      status: order["status"] ?? "",
    );
  }
}