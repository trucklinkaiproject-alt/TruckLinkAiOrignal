import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerDetailpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerListPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/brokerdetailcontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerState.dart';

class BrokerSelectionPage extends StatefulWidget {
  final String? requiredVehicleType;

  const BrokerSelectionPage({super.key, this.requiredVehicleType});

  @override
  State<BrokerSelectionPage> createState() => _BrokerSelectionPageState();
}

class _BrokerSelectionPageState extends State<BrokerSelectionPage> {
  String _effectiveVehicleType = '';

  @override
  void initState() {
    super.initState();
    _effectiveVehicleType = widget.requiredVehicleType ??
        context.read<CreateReqCubit>().currentRequest?.vehicleType ??
        '';

    if (_effectiveVehicleType.isNotEmpty) {
      context
          .read<GetBrokerCubit>()
          .listenToEligibleBrokers(_effectiveVehicleType);
    } else {
      context.read<GetBrokerCubit>().fetchAllBroker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: Appcolors.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContainer(title: "Choose Broker", backArrow: true),
                const SizedBox(height: 16),

                // ── Vehicle Requirement Badge ─────────────────────────
                if (_effectiveVehicleType.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Appcolors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Appcolors.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 18,
                            color: Appcolors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Filtering Online Brokers with:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                "$_effectiveVehicleType Drivers Available",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Appcolors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: Colors.green,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Online Only",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text(
                  "Recommended Brokers",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Real-Time Filtered Brokers Stream/State ─────────────
                BlocBuilder<GetBrokerCubit, GetBrokerState>(
                  builder: (context, state) {
                    if (state is GetBrokerLoadingState) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Appcolors.primaryBlue,
                          ),
                        ),
                      );
                    }

                    if (state is GetBrokerErrorState) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            "Error: ${state.error}",
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    final brokers = context.read<GetBrokerCubit>().brokers;

                    if (brokers.isEmpty) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.no_accounts_outlined,
                                color: Colors.orange,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No Suitable Brokers Available",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _effectiveVehicleType.isNotEmpty
                                  ? "No online brokers currently have an active '$_effectiveVehicleType' driver in their network. Brokers must be online and possess matching vehicle capacity."
                                  : "No active online brokers are available at this moment.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: brokers.length,
                      itemBuilder: (context, index) {
                        final broker = brokers[index];

                        return Brokerdetailcontainer(
                          name: broker["name"] ?? broker["broker_name"] ?? "Broker",
                          Location:
                              broker["location"] ?? broker["address"] ?? broker["city"] ?? "Location not specified",
                          rating: broker["rating"]?.toString() ?? "0.0",
                          reviews: broker["reviews"]?.toString() ?? broker["total_reviews"]?.toString() ?? "0",
                          estTime: broker["estimatedTime"] ?? "15-30 mins",
                          brokerUid: broker["uid"] ?? broker["brokerId"] ?? broker["id"],
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrokerDetailPage(
                                  brokerData: broker,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Browse More Link ───────────────────────────────────
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrokerListPage(
                          requiredVehicleType: _effectiveVehicleType,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Browse All Brokers Directory",
                        style: TextStyle(
                          color: Appcolors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded, color: Appcolors.primaryBlue, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
