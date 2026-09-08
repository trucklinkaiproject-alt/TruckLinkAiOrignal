import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverState.dart';

const List<String> kVehicleTypes = [
  "Truck",
  "Van",
  "Trailer",
  "Container",
  "PickUp Truck",
  "Shahzore",
  "Loader Rickshaw",
  "Other",
];

class DriverTruckDetailsPage extends StatefulWidget {
  final bool isFirstLogin;

  const DriverTruckDetailsPage({
    super.key,
    this.isFirstLogin = false,
  });

  @override
  State<DriverTruckDetailsPage> createState() => _DriverTruckDetailsPageState();
}

class _DriverTruckDetailsPageState extends State<DriverTruckDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNumberController = TextEditingController();
  String? _selectedVehicleType;
  bool _isSaving = false;
  String? _cachedBrokerName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final driverState = context.read<DriverCubit>().state;
    if (driverState is DriverLoadedState) {
      final driver = driverState.driver;
      if (driver.vehicleNumber != null && driver.vehicleNumber!.isNotEmpty) {
        _vehicleNumberController.text = driver.vehicleNumber!;
      }
      if (driver.vehicleType != null &&
          driver.vehicleType!.isNotEmpty &&
          kVehicleTypes.contains(driver.vehicleType)) {
        _selectedVehicleType = driver.vehicleType;
      }
      if (driverState.brokerName != null && driverState.brokerName!.isNotEmpty) {
        _cachedBrokerName = driverState.brokerName;
      } else if (driver.brokerName != null && driver.brokerName!.isNotEmpty) {
        _cachedBrokerName = driver.brokerName;
      } else if (driver.brokerId != null && driver.brokerId!.isNotEmpty) {
        _fetchBrokerName(driver.brokerId!);
      }
    }
  }

  Future<void> _fetchBrokerName(String brokerId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection("Broker").doc(brokerId).get();
      if (doc.exists && mounted) {
        setState(() {
          _cachedBrokerName = doc.data()?['name'] as String? ?? 'Assigned Broker';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleType == null || _selectedVehicleType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a vehicle type."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await context.read<DriverCubit>().saveTruckDetails(
          vehicleNumber: _vehicleNumberController.text,
          vehicleType: _selectedVehicleType!,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Truck details saved successfully!"),
          backgroundColor: Appcolors.tertiaryGreen,
        ),
      );

      if (widget.isFirstLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TransporterHomePage(),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out? You can complete truck setup later."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthCubit>().logOut(context);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogInPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverCubit, DriverState>(
      listener: (context, state) {
        if (state is DriverLoadedState) {
          if (_cachedBrokerName == null) {
            if (state.brokerName != null && state.brokerName!.isNotEmpty) {
              setState(() => _cachedBrokerName = state.brokerName);
            } else if (state.driver.brokerId != null && state.driver.brokerId!.isNotEmpty) {
              _fetchBrokerName(state.driver.brokerId!);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bool isMobile = width < 600;
              final double horizontalPadding = isMobile ? 20 : width * 0.12;

              final driverState = context.watch<DriverCubit>().state;
              String displayBrokerName = _cachedBrokerName ?? 'Assigned Broker';
              String? brokerId;

              if (driverState is DriverLoadedState) {
                brokerId = driverState.driver.brokerId;
                if (driverState.brokerName != null && driverState.brokerName!.isNotEmpty) {
                  displayBrokerName = driverState.brokerName!;
                } else if (driverState.driver.brokerName != null && driverState.driver.brokerName!.isNotEmpty) {
                  displayBrokerName = driverState.driver.brokerName!;
                }
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  15,
                  horizontalPadding,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Header --------
                      Row(
                        children: [
                          if (!widget.isFirstLogin)
                            BackArrowButton(onTap: () => Navigator.pop(context))
                          else
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                              tooltip: "Log Out",
                              onPressed: _handleLogout,
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isFirstLogin ? "Vehicle Setup" : "Truck / Vehicle Details",
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isFirstLogin
                                      ? "Set up your vehicle details to start accepting jobs"
                                      : "Complete vehicle info to join Broker network",
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // -------- Welcome / First Login Banner --------
                      if (widget.isFirstLogin) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Appcolors.primaryBlue.withOpacity(0.08),
                                Appcolors.tertiaryGreen.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Appcolors.tertiaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Appcolors.tertiaryGreen.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Appcolors.tertiaryGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome to TruckLink AI!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Your account is created and linked to your broker. Please provide your truck details below.",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // -------- Assigned Broker (Read-Only) --------
                      const Text(
                        "Assigned Broker",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Appcolors.secondaryPurple.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Appcolors.secondaryPurple,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayBrokerName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    brokerId != null && brokerId.isNotEmpty
                                        ? "Linked Broker Network"
                                        : "Direct Broker Account",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 13,
                                    color: Appcolors.tertiaryGreen,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Linked",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Appcolors.tertiaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // -------- Vehicle Type Field --------
                      const Text(
                        "Vehicle Type",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Please select your vehicle type";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Select Vehicle Type",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(
                            Icons.fire_truck_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Appcolors.tertiaryGreen,
                              width: 1.6,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        items: kVehicleTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVehicleType = val;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // -------- Vehicle Number Field --------
                      const Text(
                        "Vehicle / Truck Number",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _vehicleNumberController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 15),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Please enter your vehicle / truck registration number";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. KHI-7890 or LEA-1234",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(
                            Icons.pin_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Appcolors.tertiaryGreen,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // -------- Save Button --------
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolors.tertiaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.isFirstLogin
                                      ? "Save & Continue to Dashboard"
                                      : "Save Truck Details",
                                  style: const TextStyle(
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
          ),
        ),
      ),
    );
  }
}
