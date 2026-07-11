// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/advantagePageRow.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

// class ShipperAdvantagesPage extends StatefulWidget {
//   const ShipperAdvantagesPage({super.key});

//   @override
//   State<ShipperAdvantagesPage> createState() => _ShipperAdvantagesPageState();
// }

// class _ShipperAdvantagesPageState extends State<ShipperAdvantagesPage> {

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/advantagePageRow.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

class ShipperAdvantagesPage extends StatefulWidget {
  const ShipperAdvantagesPage({super.key});

  @override
  State<ShipperAdvantagesPage> createState() => _ShipperAdvantagesPageState();
}

class _ShipperAdvantagesPageState extends State<ShipperAdvantagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 201, 222, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final bool isMobile = width < 600;
            final bool isTablet = width >= 600 && width < 1024;
            final bool isDesktop = width >= 1024;

            final double horizontalPadding = isDesktop
                ? width * 0.12
                : width * 0.06;

            final double logoSize = isMobile
                ? 65
                : isTablet
                ? 80
                : 100;

            final double roleFont = isMobile
                ? 28
                : isTablet
                ? 32
                : 38;

            final double titleFont = isMobile
                ? 34
                : isTablet
                ? 40
                : 48;

            final double subtitleFont = isMobile
                ? 22
                : isTablet
                ? 24
                : 28;

            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: height),
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
                          color: Appcolors.primaryBlue,
                          size: isMobile ? 28 : 34,
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 10 : 20),

                    SvgPicture.asset(
                      "assets/Images/usersvg.svg",
                      width: logoSize,
                      height: logoSize,
                      color: Appcolors.primaryBlue,
                    ),

                    SizedBox(height: isMobile ? 10 : 15),

                    Text(
                      "Shipper",
                      style: TextStyle(
                        color: Appcolors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: roleFont,
                      ),
                    ),

                    SizedBox(height: isMobile ? 10 : 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "TruckLink",
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.primaryBlue,
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

                    SizedBox(height: isMobile ? 5 : 10),

                    Text(
                      "Smart Logistics.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: subtitleFont,
                      ),
                    ),

                    Text(
                      "Made Simple",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: subtitleFont,
                      ),
                    ),

                    SizedBox(height: isMobile ? 35 : 50),

                    AdvantagesPageRow(
                      text: "Create Shipment",
                      clr: Appcolors.primaryBlue,
                    ),

                    AdvantagesPageRow(
                      text: "Track in Real Time",
                      clr: Appcolors.primaryBlue,
                    ),

                    AdvantagesPageRow(
                      text: "Choose Best Broker",
                      clr: Appcolors.primaryBlue,
                    ),

                    AdvantagesPageRow(
                      text: "Secure and Reliable",
                      clr: Appcolors.primaryBlue,
                    ),

                    SizedBox(height: isMobile ? 30 : 50),

                    ContinueButton(
                      text: "Continue",
                      clr: Appcolors.primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignUpPage()),
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 20 : 30),
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
//  @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         padding: EdgeInsets.only(top: 40, left: 20, right: 20),
//         width: double.infinity,
//         height: double.infinity,
//         color: Color.fromARGB(255, 201, 222, 255),
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
//                     color: Appcolors.primaryBlue,
//                     size: 30,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               SvgPicture.asset(
//                 "assets/Images/usersvg.svg",
//                 width: 70,
//                 color: Appcolors.primaryBlue,
//               ),
//               Text(
//                 "Shipper",
//                 style: TextStyle(
//                   color: Appcolors.primaryBlue,
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
//                         color: Appcolors.primaryBlue,
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Text(
//                       "AI",
//                       style: TextStyle(
//                         fontSize: 34,
//                         fontWeight: FontWeight.bold,
//                         color: Appcolors.primaryBlue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 "Smart Logistics.",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 24,
//                 ),
//               ),
//               Text(
//                 "Made Simple",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 24,
//                 ),
//               ),
//               SizedBox(height: 50),

//               AdvantagesPageRow(
//                 text: "Create Shipment",
//                 clr: Appcolors.primaryBlue,
//               ),
//               AdvantagesPageRow(
//                 text: "Track in Real Time",
//                 clr: Appcolors.primaryBlue,
//               ),
//               AdvantagesPageRow(
//                 text: "Choose Best Broker",
//                 clr: Appcolors.primaryBlue,
//               ),
//               AdvantagesPageRow(
//                 text: "Secure and Reliable",
//                 clr: Appcolors.primaryBlue,
//               ),
//               SizedBox(height: 30),
//               ContinueButton(
//                 text: "Continue",
//                 clr: Appcolors.primaryBlue,
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
