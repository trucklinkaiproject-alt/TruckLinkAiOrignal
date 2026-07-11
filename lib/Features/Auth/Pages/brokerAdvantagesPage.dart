// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/advantagePageRow.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';


// class BrokerAdvantagesPage extends StatelessWidget {
//   const BrokerAdvantagesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         padding: EdgeInsets.only(top: 40, left: 20, right: 20),
//         width: double.infinity,
//         height: double.infinity,
//         color: const Color.fromARGB(255, 231, 223, 255),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Align(
//                 alignment: Alignment.topLeft,
//                 child: IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: Appcolors.secondaryPurple,
//                     size: 30,
//                   ),
//                 ),
//               ),
          
//               Icon(
//                 Icons.interpreter_mode_outlined,
//                 size: 100,
//                 color: Appcolors.secondaryPurple,
//               ),
          
//               Text(
//                 "Broker",
//                 style: TextStyle(
//                   color: Appcolors.secondaryPurple,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 30,
//                 ),
//               ),
//               SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 height: 70,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
          
//                   children: [
//                     Text(
//                       "TruckLink",
//                       style: TextStyle(
//                         fontSize: 34,
//                         fontWeight: FontWeight.w900,
//                         color: Appcolors.secondaryPurple,
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Text(
//                       "AI",
//                       style: TextStyle(
//                         fontSize: 34,
//                         fontWeight: FontWeight.bold,
//                         color: Appcolors.secondaryPurple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 "Manage , Assign ,",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 22,
//                 ),
//               ),
//               Text(
//                 "Deliver.",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 22,
//                 ),
//               ),
//               SizedBox(height: 50),
          
//               AdvantagesPageRow(
//                 text: "Incoming Shipment Alerts",
//                 clr: Appcolors.secondaryPurple,
//               ),
//               AdvantagesPageRow(
//                 text: "Best Quote from Brokers",
//                 clr: Appcolors.secondaryPurple,
//               ),
//               AdvantagesPageRow(
//                 text: "Choose Best Transporters",
//                 clr: Appcolors.secondaryPurple,
//               ),
//               AdvantagesPageRow(
//                 text: "Assign and Manage Shipments",
                
//                 clr: Appcolors.secondaryPurple,
//               ),
          
//               SizedBox(height: 30),
//               ContinueButton(
//                 text: "Continue",
//                 clr: Appcolors.secondaryPurple,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => SignUpPage()),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/advantagePageRow.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

class BrokerAdvantagesPage extends StatelessWidget {
  const BrokerAdvantagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        231,
        223,
        255,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final bool isMobile = width < 600;
            final bool isTablet =
                width >= 600 && width < 1024;

            final double horizontalPadding =
                isMobile ? 20 : width * 0.08;

            final double iconSize =
                isMobile ? 80 : isTablet ? 100 : 120;

            final double roleFont =
                isMobile ? 28 : isTablet ? 32 : 40;

            final double titleFont =
                isMobile ? 34 : isTablet ? 40 : 50;

            final double subtitleFont =
                isMobile ? 22 : isTablet ? 24 : 30;

            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: height,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color:
                              Appcolors.secondaryPurple,
                          size: isMobile ? 28 : 34,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isMobile ? 10 : 20,
                    ),

                    Icon(
                      Icons.interpreter_mode_outlined,
                      size: iconSize,
                      color:
                          Appcolors.secondaryPurple,
                    ),

                    SizedBox(
                      height: isMobile ? 10 : 15,
                    ),

                    Text(
                      "Broker",
                      style: TextStyle(
                        color:
                            Appcolors.secondaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: roleFont,
                      ),
                    ),

                    SizedBox(
                      height: isMobile ? 10 : 15,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          "TruckLink",
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight:
                                FontWeight.w900,
                            color: Appcolors
                                .secondaryPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "AI",
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight:
                                FontWeight.bold,
                            color: Appcolors
                                .secondaryPurple,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: isMobile ? 5 : 10,
                    ),

                    Text(
                      "Manage , Assign ,",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: subtitleFont,
                      ),
                    ),

                    Text(
                      "Deliver.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: subtitleFont,
                      ),
                    ),

                    SizedBox(
                      height: isMobile ? 35 : 50,
                    ),

                    AdvantagesPageRow(
                      text:
                          "Incoming Shipment Alerts",
                      clr:
                          Appcolors.secondaryPurple,
                    ),

                    AdvantagesPageRow(
                      text:
                          "Best Quote from Brokers",
                      clr:
                          Appcolors.secondaryPurple,
                    ),

                    AdvantagesPageRow(
                      text:
                          "Choose Best Transporters",
                      clr:
                          Appcolors.secondaryPurple,
                    ),

                    AdvantagesPageRow(
                      text:
                          "Assign and Manage Shipments",
                      clr:
                          Appcolors.secondaryPurple,
                    ),

                    SizedBox(
                      height: isMobile ? 30 : 50,
                    ),

                    ContinueButton(
                      text: "Continue",
                      clr:
                          Appcolors.secondaryPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignUpPage(),
                          ),
                        );
                      },
                    ),

                    SizedBox(
                      height: isMobile ? 20 : 30,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}