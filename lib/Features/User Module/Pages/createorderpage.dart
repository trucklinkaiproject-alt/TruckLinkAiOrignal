// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerselectionpage.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Pages/mapscreenpage.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/heading.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/locationcontainer.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';

// class CreateOrderPage extends StatefulWidget {
//   const CreateOrderPage({super.key});

//   @override
//   State<CreateOrderPage> createState() => _CreateOrderPageState();
// }

// class _CreateOrderPageState extends State<CreateOrderPage> {
//   TextEditingController itemTypeController = TextEditingController();
//   TextEditingController weightController = TextEditingController();
//   TextEditingController quantityController = TextEditingController();
//   TextEditingController additionalDetailsController = TextEditingController();
//   TextEditingController pickupCompLocation = TextEditingController();
//   TextEditingController dropCompLocation = TextEditingController();
//   TextEditingController pickupCityLocation = TextEditingController();
//   TextEditingController dropCityLocation = TextEditingController();
//   String uid = '';
//   String selectedItemType = '';
//   String pickupCity = '';
//   String pickupComp = '';
//   String dropCity = '';
//   String dropComp = '';
//   double pickupLat = 0;
//   double pickupLng = 0;

//   double dropLat = 0;
//   double dropLng = 0;
//   final List<String> itemTypes = [
//     "Furniture",
//     "Plastic",
//     "Glass",
//     "Iron",
//     "Machinery",
//     "Other",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }

//   Future<void> _loadUser() async {
//     await context.read<UserCubit>().fetchUserData();

//     if (!mounted) return;

//     setState(() {
//       uid = context.read<UserCubit>().userId;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 10),
//             color: Appcolors.background,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 AppBarContainer(title: "Create Order", backArrow: false),
//                 SizedBox(height: 20),
//                 Heading(text: "Pickup Location"),
//                 SizedBox(height: 10),

//                 LocationContainer(
//                   clr: Appcolors.primaryBlue,
//                   city: pickupCity.isEmpty ? "City" : pickupCity,
//                   address: pickupComp.isEmpty ? "Street" : pickupComp,

//                   onTap: () async {
//                     final result = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const MapPickerScreen(),
//                       ),
//                     );

//                     if (result != null) {
//                       setState(() {
//                         pickupCity = result.city;
//                         pickupComp = result.address;

//                         pickupLat = result.latitude;
//                         pickupLng = result.longitude;
//                       });
//                     }
//                   },
//                 ),
//                 SizedBox(height: 30),
//                 Heading(text: "Drop Location"),
//                 SizedBox(height: 10),

//                 LocationContainer(
//                   clr: Appcolors.secondaryPurple,
//                   city: dropCity.isEmpty ? "City" : dropCity,
//                   address: dropComp.isEmpty ? "Street" : dropComp,
//                   onTap: () async {
//                     final result = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const MapPickerScreen(),
//                       ),
//                     );

//                     if (result != null) {
//                       setState(() {
//                         dropCity = result.city;
//                         dropComp = result.address;

//                         dropLat = result.latitude;
//                         dropLng = result.longitude;
//                       });
//                     }
//                   },
//                 ),
//                 SizedBox(height: 30),
//                 Heading(text: "Item Details"),
//                 SizedBox(height: 20),

//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 15),
//                   child: DropdownButtonFormField<String>(
//                     value: selectedItemType.isEmpty ? null : selectedItemType,
//                     decoration: InputDecoration(
//                       labelText: "Item Type",
//                       hintText: "Select Item Type",
//                       prefixIcon: const Icon(Icons.inventory_2_outlined),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 16,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Colors.grey.shade300,
//                           width: 1,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: Appcolors.primaryBlue,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     icon: const Icon(Icons.keyboard_arrow_down_rounded),
//                     borderRadius: BorderRadius.circular(12),
//                     dropdownColor: Colors.white,
//                     isExpanded: true,
//                     items: itemTypes.map((type) {
//                       return DropdownMenuItem<String>(
//                         value: type,
//                         child: Text(
//                           type,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedItemType = value!;
//                       });
//                     },
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Padding(
//                   padding: EdgeInsetsGeometry.symmetric(horizontal: 30),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 100,
//                         height: 50,

//                         margin: EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: TextField(
//                           maxLines: null,
//                           expands: true,
//                           textAlign: TextAlign.center,
//                           keyboardType: TextInputType.number,
//                           controller: weightController,
//                           decoration: InputDecoration(
//                             labelText: "Weight",
//                             labelStyle: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                             hintText: "kg",
//                             contentPadding: EdgeInsets.only(
//                               left: 10,
//                               right: 10,
//                               top: 10,
//                             ),
//                             border: InputBorder.none,
//                           ),
//                         ),
//                       ),
//                       Spacer(),
//                       Container(
//                         width: 100,
//                         height: 50,
//                         margin: EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: TextField(
//                           maxLines: null,
//                           expands: true,
//                           controller: quantityController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: "Quantity",
//                             labelStyle: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                             hintText: "Units",
//                             contentPadding: EdgeInsets.only(
//                               left: 10,
//                               right: 10,
//                               top: 10,
//                             ),
//                             border: InputBorder.none,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 Heading(text: "Additional Details"),
//                 SizedBox(height: 10),
//                 Container(
//                   width: double.infinity,
//                   height: 100,
//                   margin: EdgeInsets.symmetric(horizontal: 15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: TextField(
//                     controller: additionalDetailsController,
//                     maxLines: null,
//                     expands: true,
//                     decoration: InputDecoration(
//                       hintText:
//                           "Any specific instructions or details about the shipment",
//                       hintStyle: TextStyle(
//                         color: const Color.fromARGB(255, 74, 74, 74),
//                         fontSize: 12,
//                       ),
//                       contentPadding: EdgeInsets.only(
//                         left: 10,
//                         right: 10,
//                         top: 10,
//                       ),
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 BlocBuilder<CreateReqCubit, CreateReqState>(
//                   builder: (context, state) {
//                     final isLoading = state is CreateReqLoadingState;

//                     return ContinueButton(
//                       text: "Continue",
//                       clr: Appcolors.primaryBlue,
//                       isLoading: isLoading,
//                       onTap: () async {
//                         final isWeightValid =
//                             int.tryParse(weightController.text.trim()) !=
//                                 null &&
//                             int.tryParse(weightController.text.trim())! > 0;

//                         final isQuantityValid =
//                             int.tryParse(quantityController.text.trim()) !=
//                                 null &&
//                             int.tryParse(quantityController.text.trim())! > 0;

//                         if (uid.isEmpty ||
//                             pickupCity.isEmpty ||
//                             pickupComp.isEmpty ||
//                             dropCity.isEmpty ||
//                             dropComp.isEmpty ||
//                             selectedItemType.isEmpty ||
//                             weightController.text.trim().isEmpty ||
//                             quantityController.text.trim().isEmpty ||
//                             !isWeightValid ||
//                             !isQuantityValid) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("Please fill all the fields"),
//                             ),
//                           );
//                           return;
//                         }

//                         await context
//                             .read<CreateReqCubit>()
//                             .createInitialRequest(
//                               uid,
//                               pickupCity,
//                               dropCity,
//                               pickupComp,
//                               dropComp,
//                               selectedItemType,
//                               additionalDetailsController.text,
//                               int.tryParse(weightController.text) ?? 0,
//                               int.tryParse(quantityController.text) ?? 0,
//                             );

//                         if (!mounted) return;

//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => BrokerSelectionPage(),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
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
  String pickupCity = '';
  String pickupComp = '';
  String dropCity = '';
  String dropComp = '';
  double pickupLat = 0;
  double pickupLng = 0;

  double dropLat = 0;
  double dropLng = 0;
  final List<String> itemTypes = [
    "Furniture",
    "Plastic",
    "Glass",
    "Iron",
    "Machinery",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
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
                  // -------- Header (no back arrow, same as before) --------
                  const Text(
                    "Create Order",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 30),

                  // -------- Pickup Location (same onTap logic) --------
                  const _SectionLabel("Pickup Location"),
                  const SizedBox(height: 10),
                  _LocationCard(
                    icon: Icons.trip_origin,
                    color: Appcolors.primaryBlue,
                    city: pickupCity.isEmpty ? "City" : pickupCity,
                    address: pickupComp.isEmpty ? "Street" : pickupComp,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerScreen(),
                        ),
                      );

                      if (result != null) {
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

                  // -------- Drop Location (same onTap logic) --------
                  const _SectionLabel("Drop Location"),
                  const SizedBox(height: 10),
                  _LocationCard(
                    icon: Icons.location_on,
                    color: Appcolors.secondaryPurple,
                    city: dropCity.isEmpty ? "City" : dropCity,
                    address: dropComp.isEmpty ? "Street" : dropComp,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerScreen(),
                        ),
                      );

                      if (result != null) {
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

                  // -------- Item Details --------
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

                  // -------- Weight / Quantity (same controllers) --------
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

                  // -------- Additional Details --------
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

                  // -------- Continue (same validation/cubit logic) --------
                  BlocBuilder<CreateReqCubit, CreateReqState>(
                    builder: (context, state) {
                      final isLoading = state is CreateReqLoadingState;

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

                                  await context
                                      .read<CreateReqCubit>()
                                      .createInitialRequest(
                                        uid,
                                        pickupCity,
                                        dropCity,
                                        pickupComp,
                                        dropComp,
                                        selectedItemType,
                                        additionalDetailsController.text,
                                        int.tryParse(weightController.text) ??
                                            0,
                                        int.tryParse(
                                              quantityController.text,
                                            ) ??
                                            0,
                                      );

                                  if (!mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BrokerSelectionPage(),
                                    ),
                                  );
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

                  SizedBox(height: isMobile ? 20 : 26),
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
// UI-only helper widgets below, matching the rest of the app's theme.
// No business logic lives in any of these — onTap/callbacks are passed
// straight through from the same logic as before.
// =====================================================================

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
  final VoidCallback onTap;

  const _LocationCard({
    required this.icon,
    required this.color,
    required this.city,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
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
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
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