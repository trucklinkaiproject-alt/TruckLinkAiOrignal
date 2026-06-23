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
  @override
  Widget build(BuildContext context) {
    return
    // BlocProvider(
    //   create: (context) => AuthCubit(),
    //   child: BlocListener(
    //     listener: (context, state) {
    //       if (state is AuthSuccess) {
    //         Navigator.push(
    //           context,
    //           MaterialPageRoute(builder: (context) => ShipperAdvantagesPage()),
    //         );
    //       }
    //     },
    //child:
    Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      SvgPicture.asset(
                        "assets/Images/trucksvg.svg",
                        width: 50,
                        color: Appcolors.primaryBlue,
                      ),
                      Text(
                        "TruckLink",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "AI",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Appcolors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Text("Smart Logistics.", style: AppTextStyles.subheading),
                Text("Strong Connections.", style: AppTextStyles.mainheading),
                Container(
                  width: 400,
                  height: 210,
                  padding: EdgeInsets.only(top: 20),
                  child: Image.asset(
                    "assets/Images/Only Logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
                Text(
                  "Select your role to get continue",
                  style: TextStyle(
                    color: const Color.fromARGB(175, 48, 48, 48),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: 10),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SelectionPageButton(
                      title: state is AuthLoading
                          ? "Loading ..."
                          : "I am a User",
                      subtitle: "Book and Track Shipments",
                      clr: Appcolors.primaryBlue,
                      icn: Icon(Icons.person_outline_sharp),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().getRoleName("User");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShipperAdvantagesPage(),
                                ),
                              );
                              print(context.read<AuthCubit>().selectedRole);
                            },
                    );
                  },
                ),
                // SelectionPageButton(
                //   title: "I am a Broker",
                //   subtitle: "Manage and Assign Loads",
                //   clr: Appcolors.secondaryPurple,
                //   icn: Icon(Icons.interpreter_mode_outlined),
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => BrokerAdvantagesPage(),
                //       ),
                //     );
                //   },
                // ),
                // SelectionPageButton(
                //   title: "I am a Transporter/Driver",
                //   subtitle: "Deliver and Update status",
                //   clr: Appcolors.tertiaryGreen,
                //   icn: Icon(Icons.fire_truck_sharp),
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => TransporterAdvantagesPage(),
                //       ),
                //     );
                //   },
                // ),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SelectionPageButton(
                      title: state is AuthLoading
                          ? "Loading ..."
                          : "I am a Broker",
                      subtitle: "Manage and Assign Loads",
                      clr: Appcolors.secondaryPurple,
                      icn: Icon(Icons.interpreter_mode_outlined),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().getRoleName("Broker");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BrokerAdvantagesPage(),
                                ),
                              );
                              print(context.read<AuthCubit>().selectedRole);
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
                      icn: Icon(Icons.fire_truck_sharp),
                      onTap: state is AuthLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().getRoleName("Driver");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransporterAdvantagesPage(),
                                ),
                              );  
                              print(context.read<AuthCubit>().selectedRole);
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // ),
    // );
  }
}
