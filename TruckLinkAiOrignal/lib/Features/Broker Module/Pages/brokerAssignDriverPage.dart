import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/bloc/brokerAssignDriverBloc/brokerAssignDriverCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/bloc/brokerAssignDriverBloc/brokerAssignDriverState.dart';

class BrokerAssignDriverPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const BrokerAssignDriverPage({super.key, required this.orderData});

  @override
  State<BrokerAssignDriverPage> createState() => _BrokerAssignDriverPageState();
}

class _BrokerAssignDriverPageState extends State<BrokerAssignDriverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brokerId = context.read<BrokerCubit>().brokerId;
      final requiredVehicleType =
          (widget.orderData['vehicleType'] ?? widget.orderData['vehicle_type'] ?? '')
              .toString();
      context.read<BrokerAssignDriverCubit>().fetchEligibleDrivers(
            brokerId: brokerId,
            requiredVehicleType: requiredVehicleType,
          );
    });
  }

  void _showFareOfferSheet(
    BuildContext context,
    Map<String, dynamic> driver,
  ) {
    final TextEditingController fareController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    final String driverName = (driver['name'] ?? driver['driver_name'] ?? 'Driver').toString();
    final String vehicleType = (driver['vehicle_type'] ?? 'Truck').toString();
    final String vehicleNumber = (driver['vehicle_number'] ?? 'Not specified').toString();
    final String brokerId = context.read<BrokerCubit>().brokerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
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
          child: Form(
            key: _formKey,
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
                Text(
                  "Assign Driver Offer",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Enter the fare offer to send to $driverName",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Driver Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Appcolors.secondaryPurple.withValues(alpha: 0.12),
                        child: Text(
                          driverName.isNotEmpty ? driverName[0].toUpperCase() : "D",
                          style: const TextStyle(
                            color: Appcolors.secondaryPurple,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$vehicleType • $vehicleNumber",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Fare Input Field
                const Text(
                  "Offered Fare (PKR)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fareController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter a fare amount";
                    }
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) {
                      return "Please enter a valid positive fare amount";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "e.g. 8000",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.payments_outlined, color: Appcolors.tertiaryGreen),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Appcolors.secondaryPurple, width: 1.6),
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
                      if (!_formKey.currentState!.validate()) return;
                      final fare = double.parse(fareController.text.trim());

                      Navigator.pop(sheetContext);
                      context.read<BrokerAssignDriverCubit>().sendDriverOffer(
                            brokerId: brokerId,
                            orderData: widget.orderData,
                            driverData: driver,
                            fareAmount: fare,
                          );
                    },
                    child: const Text(
                      "Send Driver Offer",
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

  @override
  Widget build(BuildContext context) {
    final String requiredVehicle = (widget.orderData['vehicleType'] ??
            widget.orderData['vehicle_type'] ??
            'Any')
        .toString();
    final String orderNo = (widget.orderData['orderNo'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 20 : width * 0.12;

            return BlocConsumer<BrokerAssignDriverCubit, BrokerAssignDriverState>(
              listener: (context, state) {
                if (state is BrokerAssignDriverSuccessState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Appcolors.tertiaryGreen,
                    ),
                  );
                  Navigator.pop(context);
                }

                if (state is BrokerAssignDriverErrorState) {
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderNo.isNotEmpty ? "Assign Driver (Order #$orderNo)" : "Assign Driver",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Select eligible Driver from your network",
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

                    // -------- Required Vehicle Badge --------
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 6,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Appcolors.secondaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Appcolors.secondaryPurple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fire_truck_sharp, color: Appcolors.secondaryPurple, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Required Vehicle: ",
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                            Text(
                              requiredVehicle,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Appcolors.secondaryPurple),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // -------- Driver List --------
                    Expanded(
                      child: _buildDriverList(
                        context: context,
                        state: state,
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

  Widget _buildDriverList({
    required BuildContext context,
    required BrokerAssignDriverState state,
    required double horizontalPadding,
  }) {
    if (state is BrokerAssignDriverLoadingState) {
      return const Center(
        child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
      );
    }

    if (state is BrokerAssignDriverLoadedState) {
      final drivers = state.eligibleDrivers;

      if (drivers.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.no_transfer_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  "No Matching Network Drivers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "No driver in your network matches the required vehicle type '${state.requiredVehicleType}'.",
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
        itemCount: drivers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final String name = (driver['name'] ?? driver['driver_name'] ?? 'Driver').toString();

          final vehicleMap = (driver['vehicle'] is Map) ? driver['vehicle'] as Map : null;
          final truckMap = (driver['truckDetails'] is Map) ? driver['truckDetails'] as Map : null;

          final rawType = (driver['vehicle_type'] ??
                  driver['vehicleType'] ??
                  driver['truck_type'] ??
                  driver['truckType'] ??
                  driver['vehicle'] ??
                  vehicleMap?['type'] ??
                  vehicleMap?['vehicle_type'] ??
                  truckMap?['vehicleType'] ??
                  truckMap?['type'])
              ?.toString()
              .trim();

          final rawNumber = (driver['vehicle_number'] ??
                  driver['vehicleNumber'] ??
                  driver['truck_id'] ??
                  driver['truckId'] ??
                  driver['license_plate'] ??
                  driver['licensePlate'] ??
                  driver['plate_number'] ??
                  driver['plateNumber'] ??
                  vehicleMap?['number'] ??
                  vehicleMap?['vehicle_number'] ??
                  truckMap?['vehicleNumber'] ??
                  truckMap?['number'])
              ?.toString()
              .trim();

          final String vehicleType = (rawType != null && rawType.isNotEmpty && rawType.toLowerCase() != 'null') ? rawType : 'Not specified';
          final String vehicleNumber = (rawNumber != null && rawNumber.isNotEmpty && rawNumber.toLowerCase() != 'null') ? rawNumber : 'Not specified';
          final double rating = (driver['driver_rating'] as num?)?.toDouble() ?? 0.0;
          final int completedTrips = (driver['completed_trips'] as num?)?.toInt() ?? 0;

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
                      backgroundColor: Appcolors.tertiaryGreen.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "D",
                        style: const TextStyle(
                          color: Appcolors.tertiaryGreen,
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (driver['is_online'] == true)
                                      ? Appcolors.tertiaryGreen.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: (driver['is_online'] == true)
                                            ? Appcolors.tertiaryGreen
                                            : Colors.grey[600],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (driver['is_online'] == true) ? "Online" : "Offline",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: (driver['is_online'] == true)
                                            ? Appcolors.tertiaryGreen
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$vehicleType • $vehicleNumber",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
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
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 3),
                    Text(
                      rating > 0 ? "$rating ★" : "No rating yet",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: rating > 0 ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.route_outlined, size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      "$completedTrips trips",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.secondaryPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () {
                        _showFareOfferSheet(context, driver);
                      },
                      child: const Text(
                        "Select & Offer",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
