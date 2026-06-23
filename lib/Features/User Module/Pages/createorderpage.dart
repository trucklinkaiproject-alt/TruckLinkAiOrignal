import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerselectionpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/mapscreenpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/heading.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/locationcontainer.dart';
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            color: Appcolors.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContainer(title: "Create Order",backArrow: false,),
                SizedBox(height: 20),
                Heading(text: "Pickup Location"),
                SizedBox(height: 10),

                LocationContainer(
                  clr: Appcolors.primaryBlue,
                  city: pickupCity.isEmpty ? "City" : pickupCity,
                  address: pickupComp.isEmpty ? "Street" : pickupComp,
                  // onTap: () {
                  //   showModalBottomSheet(
                  //     context: context,
                  //     isScrollControlled: true,
                  //     shape: const RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.vertical(
                  //         top: Radius.circular(20),
                  //       ),
                  //     ),
                  //     builder: (context) {
                  //       return Padding(
                  //         padding: EdgeInsets.only(
                  //           left: 20,
                  //           right: 20,
                  //           top: 20,
                  //           bottom:
                  //               MediaQuery.of(context).viewInsets.bottom + 20,
                  //         ),
                  //         child: Column(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             const Text(
                  //               "Enter Address",
                  //               style: TextStyle(
                  //                 fontSize: 20,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //             const SizedBox(height: 20),

                  //             TextField(
                  //               controller: pickupCityLocation,
                  //               decoration: const InputDecoration(
                  //                 labelText: "City , Province",
                  //                 hintText: "e.g : Lahore , Punjab",
                  //                 border: OutlineInputBorder(),
                  //               ),
                  //             ),

                  //             const SizedBox(height: 20),
                  //             TextField(
                  //               controller: pickupCompLocation,
                  //               decoration: const InputDecoration(
                  //                 labelText: "Complete Address",
                  //                 hintText:
                  //                     "e.g : House no 43,Street no 1, Al Rehman Garden",
                  //                 border: OutlineInputBorder(),
                  //               ),
                  //             ),
                  //             const SizedBox(height: 20),

                  //             ContinueButton(
                  //               text: 'Save',
                  //               clr: Appcolors.primaryBlue,
                  //               onTap: () {
                  //                 setState(() {
                  //                   pickupCity = pickupCityLocation.text;
                  //                   pickupComp = pickupCompLocation.text;
                  //                 });
                  //                 Navigator.pop(context);
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     },
                  //   );
                  // },
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
                SizedBox(height: 30),
                Heading(text: "Drop Location"),
                SizedBox(height: 10),

                LocationContainer(
                  clr: Appcolors.secondaryPurple,
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
                SizedBox(height: 30),
                Heading(text: "Item Details"),
                SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonFormField<String>(
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
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Appcolors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(12),
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
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.number,
                            controller: weightController,
                            decoration: InputDecoration(
                              labelText: "Weight",
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              hintText: "kg",
                              contentPadding: EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            maxLines: null,
                            expands: true,
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              hintText: "Units",
                              contentPadding: EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Heading(text: "Additional Details"),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 100,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: additionalDetailsController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText:
                          "Any specific instructions or details about the shipment",
                      hintStyle: TextStyle(
                        color: const Color.fromARGB(255, 74, 74, 74),
                        fontSize: 12,
                      ),
                      contentPadding: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                BlocBuilder<CreateReqCubit, CreateReqState>(
                  builder: (context, state) {
                    return ContinueButton(
                      text: state is CreateReqLoadingState
                          ? "Loading ..."
                          : "Continue",
                      clr: Appcolors.primaryBlue,
                      onTap: () async {
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
                              int.tryParse(weightController.text) ?? 0,
                              int.tryParse(quantityController.text) ?? 0,
                            );

                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BrokerSelectionPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
