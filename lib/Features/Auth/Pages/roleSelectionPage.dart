import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Constants/app_text_styles.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/brokerAdvantagesPage.dart';

import 'package:trucklinkai_orignal/Features/Auth/Pages/shipperAdvantagesPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/transporterAdvantagesPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/selectionpagebutton.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  // @override
  // Widget build(BuildContext context) {
  //   return
    
  //    Scaffold(
    //   backgroundColor: Appcolors.background,
    //   body: SafeArea(
    //     child: Container(
    //       width: double.infinity,
    //       height: double.infinity,
    //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    //       child: SingleChildScrollView(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.center,

    //           children: [
    //             SizedBox(
    //               width: double.infinity,
    //               height: 70,
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 crossAxisAlignment: CrossAxisAlignment.center,

    //                 children: [
    //                   SvgPicture.asset(
    //                     "assets/Images/trucksvg.svg",
    //                     width: 50,
    //                     color: Appcolors.primaryBlue,
    //                   ),
    //                   Text(
    //                     "TruckLink",
    //                     style: TextStyle(
    //                       fontSize: 34,
    //                       fontWeight: FontWeight.w900,
    //                       color: Appcolors.textPrimary,
    //                     ),
    //                   ),
    //                   SizedBox(width: 10),
    //                   Text(
    //                     "AI",
    //                     style: TextStyle(
    //                       fontSize: 34,
    //                       fontWeight: FontWeight.bold,
    //                       color: Appcolors.primaryBlue,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //             Text("Smart Logistics.", style: AppTextStyles.subheading),
    //             Text("Strong Connections.", style: AppTextStyles.mainheading),
    //             Container(
    //               width: 400,
    //               height: 210,
    //               padding: EdgeInsets.only(top: 20),
    //               child: Image.asset(
    //                 "assets/Images/Only Logo.png",
    //                 fit: BoxFit.cover,
    //               ),
    //             ),
    //             Text(
    //               "Select your role to get continue",
    //               style: TextStyle(
    //                 color: const Color.fromARGB(175, 48, 48, 48),
    //                 fontSize: 18,
    //                 fontWeight: FontWeight.w300,
    //               ),
    //             ),
    //             SizedBox(height: 10),
    //             BlocBuilder<AuthCubit, AuthState>(
    //               builder: (context, state) {
    //                 return SelectionPageButton(
    //                   title: state is AuthLoading
    //                       ? "Loading ..."
    //                       : "I am a User",
    //                   subtitle: "Book and Track Shipments",
    //                   clr: Appcolors.primaryBlue,
    //                   icn: Icon(Icons.person_outline_sharp),
    //                   onTap: state is AuthLoading
    //                       ? null
    //                       : () {
    //                           context.read<AuthCubit>().getRoleName("User");
    //                           Navigator.push(
    //                             context,
    //                             MaterialPageRoute(
    //                               builder: (context) => ShipperAdvantagesPage(),
    //                             ),
    //                           );
    //                           print(context.read<AuthCubit>().selectedRole);
    //                         },
    //                 );
    //               },
    //             ),
    //             // SelectionPageButton(
    //             //   title: "I am a Broker",
    //             //   subtitle: "Manage and Assign Loads",
    //             //   clr: Appcolors.secondaryPurple,
    //             //   icn: Icon(Icons.interpreter_mode_outlined),
    //             //   onTap: () {
    //             //     Navigator.push(
    //             //       context,
    //             //       MaterialPageRoute(
    //             //         builder: (context) => BrokerAdvantagesPage(),
    //             //       ),
    //             //     );
    //             //   },
    //             // ),
    //             // SelectionPageButton(
    //             //   title: "I am a Transporter/Driver",
    //             //   subtitle: "Deliver and Update status",
    //             //   clr: Appcolors.tertiaryGreen,
    //             //   icn: Icon(Icons.fire_truck_sharp),
    //             //   onTap: () {
    //             //     Navigator.push(
    //             //       context,
    //             //       MaterialPageRoute(
    //             //         builder: (context) => TransporterAdvantagesPage(),
    //             //       ),
    //             //     );
    //             //   },
    //             // ),
    //             BlocBuilder<AuthCubit, AuthState>(
    //               builder: (context, state) {
    //                 return SelectionPageButton(
    //                   title: state is AuthLoading
    //                       ? "Loading ..."
    //                       : "I am a Broker",
    //                   subtitle: "Manage and Assign Loads",
    //                   clr: Appcolors.secondaryPurple,
    //                   icn: Icon(Icons.interpreter_mode_outlined),
    //                   onTap: state is AuthLoading
    //                       ? null
    //                       : () {
    //                           context.read<AuthCubit>().getRoleName("Broker");
    //                         Navigator.push(
    //                             context,
    //                             MaterialPageRoute(
    //                               builder: (context) => BrokerAdvantagesPage(),
    //                             ),
    //                           );
    //                           print(context.read<AuthCubit>().selectedRole);
    //                         },
    //                 );
    //               },
    //             ),
    //             BlocBuilder<AuthCubit, AuthState>(
    //               builder: (context, state) {
    //                 return SelectionPageButton(
    //                   title: state is AuthLoading
    //                       ? "Loading ..."
    //                       : "I am a Transporter/Driver",
    //                   subtitle: "Deliver and Update status",
    //                   clr: Appcolors.tertiaryGreen,
    //                   icn: Icon(Icons.fire_truck_sharp),
    //                   onTap: state is AuthLoading
    //                       ? null
    //                       : () {
    //                           context.read<AuthCubit>().getRoleName("Driver");
    //                           Navigator.push(
    //                             context,
    //                             MaterialPageRoute(
    //                               builder: (context) => TransporterAdvantagesPage(),
    //                             ),
    //                           );  
    //                           print(context.read<AuthCubit>().selectedRole);
    //                         },
    //                 );
    //               },
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    // ),
    // );
    @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  double logoSize = screenWidth * 0.25;
  logoSize = logoSize.clamp(180.0, 320.0);

  double titleFont = (screenWidth * 0.03).clamp(28.0, 42.0);
  double subtitleFont = (screenWidth * 0.015).clamp(14.0, 20.0);

  return Scaffold(
    backgroundColor: Appcolors.background,
    body: SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/Images/trucksvg.svg",
                        width: (screenWidth * 0.04).clamp(40.0, 60.0),
                        color: Appcolors.primaryBlue,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "TruckLink",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.textPrimary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "AI",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.bold,
                          color: Appcolors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                Text(
                  "Smart Logistics.",
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: subtitleFont,
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  "Strong Connections.",
                  style: AppTextStyles.mainheading.copyWith(
                    fontSize: subtitleFont + 4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.02),

                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    "assets/Images/Only Logo.png",
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                Text(
                  "Select your role to get continue",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color.fromARGB(
                      175,
                      48,
                      48,
                      48,
                    ),
                    fontSize: subtitleFont,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SelectionPageButton(
                      title: state is AuthLoading
                          ? "Loading ..."
                          : "I am a User",
                      subtitle: "Book and Track Shipments",
                      clr: Appcolors.primaryBlue,
                      icn: const Icon(
                        Icons.person_outline_sharp,
                        
                      ),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context
                                  .read<AuthCubit>()
                                  .getRoleName("User");

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ShipperAdvantagesPage(),
                                ),
                              );
                            },
                    );
                  },
                ),

                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SelectionPageButton(
                      title: state is AuthLoading
                          ? "Loading ..."
                          : "I am a Broker",
                      subtitle: "Manage and Assign Loads",
                      clr: Appcolors.secondaryPurple,
                      icn: const Icon(
                        Icons.interpreter_mode_outlined,
                      ),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context
                                  .read<AuthCubit>()
                                  .getRoleName("Broker");

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BrokerAdvantagesPage(),
                                ),
                              );
                            },
                    );
                  },
                ),

                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SelectionPageButton(
                      title: state is AuthLoading
                          ? "Loading ..."
                          : "I am a Transporter/Driver",
                      subtitle: "Deliver and Update status",
                      clr: Appcolors.tertiaryGreen,
                      icn: const Icon(
                        Icons.fire_truck_sharp,
                      ),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context
                                  .read<AuthCubit>()
                                  .getRoleName("Driver");

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TransporterAdvantagesPage(),
                                ),
                              );
                            },
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  }
}
