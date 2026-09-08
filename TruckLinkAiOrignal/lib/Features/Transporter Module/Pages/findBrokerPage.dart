import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Models/driverModel.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverTruckDetailsPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverState.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/findBrokerBloc/findBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/findBrokerBloc/findBrokerState.dart';

class FindBrokerPage extends StatefulWidget {
  const FindBrokerPage({super.key});

  @override
  State<FindBrokerPage> createState() => _FindBrokerPageState();
}

class _FindBrokerPageState extends State<FindBrokerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverState = context.read<DriverCubit>().state;
      String driverId = '';
      if (driverState is DriverLoadedState) {
        driverId = driverState.driver.uid;
      }
      context.read<FindBrokerCubit>().fetchBrokers(driverId: driverId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showConfirmJoinSheet(
    BuildContext context,
    DriverModel driver,
    Map<String, dynamic> broker,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final String brokerName = (broker['name'] ?? 'Broker').toString();
        final String brokerEmail = (broker['email'] ?? 'No email').toString();
        final String brokerPhone = (broker['phone'] ?? 'No phone').toString();
        final String brokerId = (broker['id'] ?? broker['uid'] ?? '').toString();

        // Dynamic Broker Reputation from Firestore
        final double? overallRating = (broker['rating'] as num?)?.toDouble() ??
            (broker['overall_rating'] as num?)?.toDouble();
        final double? completionRate = (broker['completion_rate'] as num?)?.toDouble() ??
            (broker['completionRate'] as num?)?.toDouble();
        final int totalReviews = (broker['total_reviews'] as num?)?.toInt() ??
            (broker['totalReviews'] as num?)?.toInt() ??
            0;
        final int star5 = (broker['star_5_count'] as num?)?.toInt() ??
            (broker['5_star_count'] as num?)?.toInt() ??
            0;
        final int star4 = (broker['star_4_count'] as num?)?.toInt() ??
            (broker['4_star_count'] as num?)?.toInt() ??
            0;
        final int star3 = (broker['star_3_count'] as num?)?.toInt() ??
            (broker['3_star_count'] as num?)?.toInt() ??
            0;
        final int star2 = (broker['star_2_count'] as num?)?.toInt() ??
            (broker['2_star_count'] as num?)?.toInt() ??
            0;
        final int star1 = (broker['star_1_count'] as num?)?.toInt() ??
            (broker['1_star_count'] as num?)?.toInt() ??
            0;

        final bool hasReviews = overallRating != null && overallRating > 0 && totalReviews > 0;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Broker Details & Reputation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Review broker reputation before sending join request",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Broker Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Appcolors.secondaryPurple.withValues(alpha: 0.12),
                            child: Text(
                              brokerName.isNotEmpty
                                  ? brokerName[0].toUpperCase()
                                  : "B",
                              style: const TextStyle(
                                color: Appcolors.secondaryPurple,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brokerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Broker ID: $brokerId",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _sheetInfoRow(Icons.email_outlined, "Email", brokerEmail),
                      const SizedBox(height: 8),
                      _sheetInfoRow(Icons.phone_outlined, "Phone", brokerPhone),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dynamic Broker Reputation Section
                const Text(
                  "Reputation & Feedback",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: hasReviews
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 28, color: Colors.amber[700]),
                                const SizedBox(width: 6),
                                Text(
                                  overallRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  " / 5.0 ($totalReviews reviews)",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                const Spacer(),
                                if (completionRate != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Appcolors.tertiaryGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${completionRate.toStringAsFixed(0)}% Completion",
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Appcolors.tertiaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            _starRow("5 Stars", star5, totalReviews),
                            _starRow("4 Stars", star4, totalReviews),
                            _starRow("3 Stars", star3, totalReviews),
                            _starRow("2 Stars", star2, totalReviews),
                            _starRow("1 Star", star1, totalReviews),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.rate_review_outlined, color: Colors.grey[400], size: 22),
                              const SizedBox(width: 10),
                              Text(
                                "No reviews yet.",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolors.secondaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      if (!driver.isTruckDetailsComplete) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please complete your truck details before joining a Broker."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverTruckDetailsPage(),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(sheetContext);
                      context.read<FindBrokerCubit>().sendJoinRequest(
                            driver: driver,
                            broker: broker,
                          );
                    },
                    child: const Text(
                      "Confirm & Send Request",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _starRow(String label, int count, int total) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$count",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _sheetInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverCubit>().state;
    DriverModel? currentDriver;
    if (driverState is DriverLoadedState) {
      currentDriver = driverState.driver;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 20 : width * 0.12;

            return BlocConsumer<FindBrokerCubit, FindBrokerState>(
              listener: (context, state) {
                if (state is FindBrokerSuccessState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage),
                      backgroundColor: Appcolors.tertiaryGreen,
                    ),
                  );
                }

                if (state is FindBrokerErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    // -------- Header --------
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        15,
                        horizontalPadding,
                        12,
                      ),
                      child: Row(
                        children: [
                          BackArrowButton(onTap: () => Navigator.pop(context)),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Find a Broker",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Discover registered Brokers to join network",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -------- Search Bar --------
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          context.read<FindBrokerCubit>().searchBrokers(query);
                        },
                        style: const TextStyle(fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: "Search broker by name...",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<FindBrokerCubit>()
                                        .searchBrokers('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Appcolors.secondaryPurple,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // -------- Broker List --------
                    Expanded(
                      child: _buildBrokerList(
                        context: context,
                        state: state,
                        driver: currentDriver,
                        horizontalPadding: horizontalPadding,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrokerList({
    required BuildContext context,
    required FindBrokerState state,
    required DriverModel? driver,
    required double horizontalPadding,
  }) {
    if (state is FindBrokerLoadingState) {
      return const Center(
        child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
      );
    }

    if (state is FindBrokerLoadedState) {
      final brokers = state.filteredBrokers;
      final requestedIds = state.requestedBrokerIds;

      if (brokers.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  "No Brokers Found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Try a different search term or clear the filter.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          24,
        ),
        itemCount: brokers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final broker = brokers[index];
          final String brokerId = (broker['id'] ?? broker['uid'] ?? '').toString();
          final String brokerName = (broker['name'] ?? 'Broker').toString();
          final String brokerEmail = (broker['email'] ?? '').toString();
          final String brokerPhone = (broker['phone'] ?? '').toString();

          final bool isRequested = requestedIds.contains(brokerId);
          final bool isConnectedToThis =
              driver != null && driver.brokerId == brokerId;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          Appcolors.secondaryPurple.withValues(alpha: 0.12),
                      child: Text(
                        brokerName.isNotEmpty ? brokerName[0].toUpperCase() : "B",
                        style: const TextStyle(
                          color: Appcolors.secondaryPurple,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brokerName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          if (brokerEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              brokerEmail,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (brokerPhone.isNotEmpty) ...[
                      Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        brokerPhone,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const Spacer(),

                    // Join Request Action Button
                    if (isConnectedToThis) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Appcolors.tertiaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Connected",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Appcolors.tertiaryGreen,
                          ),
                        ),
                      ),
                    ] else if (isRequested) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Request Pending",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.secondaryPurple,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: driver == null
                            ? null
                            : () {
                                _showConfirmJoinSheet(context, driver, broker);
                              },
                        child: const Text(
                          "Send Request",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
