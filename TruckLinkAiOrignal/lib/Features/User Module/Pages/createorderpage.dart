

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerselectionpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/mapscreenpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';


class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  TextEditingController itemTypeController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController additionalDetailsController = TextEditingController();
  TextEditingController pickupCompLocation = TextEditingController();
  TextEditingController dropCompLocation = TextEditingController();
  TextEditingController pickupCityLocation = TextEditingController();
  TextEditingController dropCityLocation = TextEditingController();
  String uid = '';
  String selectedItemType = '';
  String selectedVehicleType = '';
  String pickupCity = '';
  String pickupComp = '';
  String dropCity = '';
  String dropComp = '';
  double pickupLat = 0;
  double pickupLng = 0;

  double dropLat = 0;
  double dropLng = 0;
  bool _isSubmitting = false;
  final List<String> itemTypes = [
    "Furniture",
    "Plastic",
    "Glass",
    "Iron",
    "Machinery",
    "Other",
  ];
  final List<String> vehicleTypes = [
    "Truck",
    "Van",
    "Trailer",
    "Container",
    "PickUp Truck",
    "Shahzore",
    "Loader Rickshaw",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    itemTypeController.dispose();
    weightController.dispose();
    quantityController.dispose();
    additionalDetailsController.dispose();
    pickupCompLocation.dispose();
    dropCompLocation.dispose();
    pickupCityLocation.dispose();
    dropCityLocation.dispose();
    super.dispose();
  }

  void _resetForm() {
    itemTypeController.clear();
    weightController.clear();
    quantityController.clear();
    additionalDetailsController.clear();
    pickupCompLocation.clear();
    dropCompLocation.clear();
    pickupCityLocation.clear();
    dropCityLocation.clear();
    if (mounted) {
      setState(() {
        selectedItemType = '';
        selectedVehicleType = '';
        pickupCity = '';
        pickupComp = '';
        dropCity = '';
        dropComp = '';
        pickupLat = 0;
        pickupLng = 0;
        dropLat = 0;
        dropLng = 0;
        _isSubmitting = false;
      });
    }
  }

  Future<void> _loadUser() async {
    await context.read<UserCubit>().fetchUserData();

    if (!mounted) return;

    setState(() {
      uid = context.read<UserCubit>().userId;
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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Create Order",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 30),


                  const _SectionLabel("Pickup Location"),
                  const SizedBox(height: 10),
                  _LocationCard(
                    icon: Icons.trip_origin,
                    color: Appcolors.primaryBlue,
                    city: pickupCity.isEmpty ? "Select Pickup City" : pickupCity,
                    address: pickupComp.isEmpty ? "Tap to search or pick exact map location" : pickupComp,
                    latitude: pickupLat != 0.0 ? pickupLat : null,
                    longitude: pickupLng != 0.0 ? pickupLng : null,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerScreen(),
                        ),
                      );

                      if (result is LocationModel) {
                        setState(() {
                          pickupCity = result.city;
                          pickupComp = result.address;
                          pickupLat = result.latitude;
                          pickupLng = result.longitude;
                        });
                      }
                    },
                  ),

                  SizedBox(height: isMobile ? 24 : 30),


                  const _SectionLabel("Drop Location"),
                  const SizedBox(height: 10),
                  _LocationCard(
                    icon: Icons.location_on,
                    color: Appcolors.secondaryPurple,
                    city: dropCity.isEmpty ? "Select Drop City" : dropCity,
                    address: dropComp.isEmpty ? "Tap to search or pick exact map location" : dropComp,
                    latitude: dropLat != 0.0 ? dropLat : null,
                    longitude: dropLng != 0.0 ? dropLng : null,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerScreen(),
                        ),
                      );

                      if (result is LocationModel) {
                        setState(() {
                          dropCity = result.city;
                          dropComp = result.address;
                          dropLat = result.latitude;
                          dropLng = result.longitude;
                        });
                      }
                    },
                  ),


                  SizedBox(height: isMobile ? 24 : 30),


                  const _SectionLabel("Item Details"),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedItemType.isEmpty ? null : selectedItemType,
                    decoration: InputDecoration(
                      labelText: "Item Type",
                      hintText: "Select Item Type",
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
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
                        borderSide: BorderSide(
                          color: Appcolors.primaryBlue,
                          width: 1.6,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    items: itemTypes.map((type) {
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
                    onChanged: (value) {
                      setState(() {
                        selectedItemType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 14),


                  Row(
                    children: [
                      Expanded(
                        child: _InlineField(
                          controller: weightController,
                          label: "Weight",
                          hintText: "kg",
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InlineField(
                          controller: quantityController,
                          label: "Quantity",
                          hintText: "Units",
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 24 : 30),
                  const _SectionLabel("Transportation Details"),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedVehicleType.isEmpty ? null : selectedVehicleType,
                    decoration: InputDecoration(
                      labelText: "Vehicle Type",
                      hintText: "Select Vehicle Type",
                      prefixIcon: const Icon(Icons.fire_truck_sharp),
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
                        borderSide: BorderSide(
                          color: Appcolors.primaryBlue,
                          width: 1.6,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    items: vehicleTypes.map((type) {
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
                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 14),


                  const _SectionLabel("Additional Details"),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 110,
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
                    child: TextField(
                      controller: additionalDetailsController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText:
                            "Any specific instructions or details about the shipment",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.5,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 26 : 32),


                  BlocBuilder<CreateReqCubit, CreateReqState>(
                    builder: (context, state) {
                      final isLoading = state is CreateReqLoadingState || _isSubmitting;

                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolors.primaryBlue,
                            disabledBackgroundColor: Appcolors.primaryBlue
                                .withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final isWeightValid =
                                      int.tryParse(
                                            weightController.text.trim(),
                                          ) !=
                                          null &&
                                      int.tryParse(
                                            weightController.text.trim(),
                                          )! >
                                          0;

                                  final isQuantityValid =
                                      int.tryParse(
                                            quantityController.text.trim(),
                                          ) !=
                                          null &&
                                      int.tryParse(
                                            quantityController.text.trim(),
                                          )! >
                                          0;

                                  if (uid.isEmpty ||
                                      pickupCity.isEmpty ||
                                      pickupComp.isEmpty ||
                                      dropCity.isEmpty ||
                                      dropComp.isEmpty ||
                                      selectedItemType.isEmpty ||
                                      selectedVehicleType.isEmpty ||
                                      weightController.text.trim().isEmpty ||
                                      quantityController.text
                                          .trim()
                                          .isEmpty ||
                                      !isWeightValid ||
                                      !isQuantityValid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please fill all the fields",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  try {
                                    await context
                                        .read<CreateReqCubit>()
                                        .createInitialRequest(
                                          uid,
                                          pickupCity,
                                          dropCity,
                                          pickupComp,
                                          dropComp,
                                          selectedItemType,
                                          selectedVehicleType,
                                          additionalDetailsController.text,
                                          int.tryParse(weightController.text) ??
                                              0,
                                          int.tryParse(
                                                quantityController.text,
                                              ) ??
                                              0,
                                          pickupLat: pickupLat,
                                          pickupLng: pickupLng,
                                          dropLat: dropLat,
                                          dropLng: dropLng,
                                        );

                                    if (!mounted) return;

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BrokerSelectionPage(
                                          requiredVehicleType: selectedVehicleType,
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSubmitting = false;
                                      });
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
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

class _LocationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  const _LocationCard({
    required this.icon,
    required this.color,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCoordinates = latitude != null &&
        longitude != null &&
        latitude != 0.0 &&
        longitude != 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (hasCoordinates) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;

  const _InlineField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12.5),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }
}