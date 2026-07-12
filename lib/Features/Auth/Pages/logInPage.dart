// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/forgetPasswordPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokernavbar.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
// import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';

// class LogInPage extends StatefulWidget {
//   const LogInPage({super.key});

//   @override
//   State<LogInPage> createState() => _LogInPageState();
// }

// class _LogInPageState extends State<LogInPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   bool userChecked = false;
//   bool brokerChecked = false;
//   bool driverChecked = false;

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthCubit, AuthState>(
//       listener: (context, state) {
//         if (state is AuthSuccess) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) {
//                 if (state.role == "User") {
//                   return ShipperBottomNavBar();
//                 } else if (state.role == "Broker") {
//                   return BrokerBottomNavBar();
//                 } else if (state.role == "Driver") {
//                   return TransporterHomePage();
//                 } else {
//                   return ShipperBottomNavBar();
//                 }
//               },
//             ),
//           );
//         }

//         if (state is AuthFailure) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(state.error)));
//         }
//       },
//       child: Scaffold(
//         backgroundColor: Appcolors.background,
//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final width = constraints.maxWidth;
//               final height = constraints.maxHeight;

//               final bool isMobile = width < 600;

//               final double horizontalPadding = isMobile ? 20 : width * 0.12;

//               final double logoSize = (width * 0.08).clamp(90.0, 130.0);

//               final double titleFont = (width * 0.03).clamp(30.0, 40.0);

//               final double headingFont = (width * 0.025).clamp(24.0, 32.0);

//               return SingleChildScrollView(
//                 child: Container(
//                   width: double.infinity,
//                   constraints: BoxConstraints(minHeight: height),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: horizontalPadding,
//                     vertical: 15,
//                   ),
//                   child: Column(
//                     children: [
//                       Align(
//                         alignment: Alignment.topLeft,
//                         child: IconButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           icon: Icon(
//                             Icons.arrow_back,
//                             color: Appcolors.primaryBlue,
//                             size: isMobile ? 30 : 36,
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: isMobile ? 20 : 30),

//                       SizedBox(
//                         width: logoSize,
//                         height: logoSize,
//                         child: Image.asset(
//                           "assets/Images/TruckLink AI.png",
//                           fit: BoxFit.contain,
//                         ),
//                       ),

//                       SizedBox(height: 10),

//                       Text(
//                         "TruckLink AI",
//                         style: TextStyle(
//                           fontSize: titleFont,
//                           fontWeight: FontWeight.w900,
//                           color: Appcolors.primaryBlue,
//                         ),
//                       ),

//                       SizedBox(height: isMobile ? 10 : 15),

//                       Text(
//                         "Welcome Back!",
//                         style: TextStyle(
//                           fontSize: headingFont,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.black,
//                         ),
//                       ),

//                       const SizedBox(height: 5),

//                       const Text(
//                         "Login to Continue",
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),

//                       SizedBox(height: isMobile ? 25 : 40),

//                       SignUpTextField(
//                         hintText: "example@gmail.com",
//                         label: "Email",
//                         controller: emailController,
//                         type: TextInputType.emailAddress,
//                       ),

//                       SignUpTextField(
//                         hintText: "********",
//                         label: "Password",
//                         controller: passwordController,
//                         obscureText: true,
//                       ),

//                       const SizedBox(height: 5),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                             style: TextButton.styleFrom(
//                               overlayColor: Colors.transparent,
//                              // foregroundColor: Appcolors.primaryBlue,
//                             ),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const ForgotPasswordPage(),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             "Forgot Password?",
//                             style: TextStyle(
//                               color: Colors.black87,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       Wrap(
//                         alignment: WrapAlignment.center,
//                         spacing: 20,
//                         runSpacing: 10,
//                         children: [
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Checkbox(
//                                 value: userChecked,
//                                 activeColor: Appcolors.primaryBlue,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     userChecked = value!;
//                                     brokerChecked = false;
//                                     driverChecked = false;
//                                   });
//                                 },
//                               ),
//                               const Text(
//                                 "User",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Appcolors.primaryBlue,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Checkbox(
//                                 value: brokerChecked,
//                                 activeColor: Appcolors.secondaryPurple,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     brokerChecked = value!;
//                                     userChecked = false;
//                                     driverChecked = false;
//                                   });
//                                 },
//                               ),
//                               Text(
//                                 "Broker",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Appcolors.secondaryPurple,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Checkbox(
//                                 value: driverChecked,
//                                 activeColor: Appcolors.tertiaryGreen,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     driverChecked = value!;
//                                     userChecked = false;
//                                     brokerChecked = false;
//                                   });
//                                 },
//                               ),
//                               const Text(
//                                 "Driver",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Appcolors.tertiaryGreen,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),

//                       BlocBuilder<AuthCubit, AuthState>(
//                         builder: (context, state) {
//                           return ContinueButton(
//                             text: state is AuthLoading
//                                 ? "Logging In..."
//                                 : "Continue",
//                             clr: Appcolors.primaryBlue,
//                             onTap: state is AuthLoading
//                                 ? null
//                                 : () {
//                                     context.read<AuthCubit>().logIn(
//                                       email: emailController.text,
//                                       password: passwordController.text,
//                                       role: userChecked
//                                           ? "User"
//                                           : brokerChecked
//                                           ? "Broker"
//                                           : driverChecked
//                                           ? "Driver"
//                                           : "",
//                                     );
//                                   },
//                           );
//                         },
//                       ),

//                       const SizedBox(height: 20),

//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                             "Don't have an account?",
//                             style: TextStyle(fontSize: 14, color: Colors.grey),
//                           ),
//                           const SizedBox(width: 10),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const RoleSelectionPage(),
//                                 ),
//                               );
//                             },
//                             child: Text(
//                               "Sign Up",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Appcolors.primaryBlue,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 5),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/forgetPasswordPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/pillTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/roleCard.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/selectionLabel.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokernavbar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ------- Same state / logic as before, untouched -------
  bool userChecked = false;
  bool brokerChecked = false;
  bool driverChecked = false;

  // Purely cosmetic, UI-only toggle (matches the "Remember me" checkbox in
  // the design). It is not wired into any auth logic.
  bool rememberMe = false;

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (state.role == "User") {
                  return ShipperBottomNavBar();
                } else if (state.role == "Broker") {
                  return BrokerBottomNavBar();
                } else if (state.role == "Driver") {
                  return TransporterHomePage();
                } else {
                  return ShipperBottomNavBar();
                }
              },
            ),
          );
        }

        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              final bool isMobile = width < 600;

              final double horizontalPadding = isMobile ? 22 : width * 0.12;

              final double logoSize = (width * 0.16).clamp(64.0, 84.0);

              final double titleFont = (width * 0.07).clamp(24.0, 30.0);

              final double headingFont = (width * 0.045).clamp(15.0, 18.0);

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: height),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Back button --------
                      BackArrowButton(onTap: () => Navigator.pop(context)),

                      SizedBox(height: isMobile ? 24 : 32),

                      // -------- Logo + title (centered) --------
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              
                              child: Image.asset(
                                "assets/Images/TruckLink AI.png",
                                fit: BoxFit.contain,
                                
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "TruckLink AI",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Welcome back! Login to continue",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: headingFont,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 28 : 36),

                      // -------- Select role --------
                      const SectionLabel("Select Role"),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RoleCard(
                              icon: Icons.person_outline,
                              title: "User",
                              subtitle: "Send goods",
                              color: Appcolors.primaryBlue,
                              selected: userChecked,
                              onTap: () {
                                setState(() {
                                  userChecked = true;
                                  brokerChecked = false;
                                  driverChecked = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RoleCard(
                              icon: Icons.handshake_outlined,
                              title: "Broker",
                              subtitle: "Manage deals",
                              color: Appcolors.secondaryPurple,
                              selected: brokerChecked,
                              onTap: () {
                                setState(() {
                                  brokerChecked = true;
                                  userChecked = false;
                                  driverChecked = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RoleCard(
                              icon: Icons.local_shipping_outlined,
                              title: "Driver",
                              subtitle: "Deliver goods",
                              color: Appcolors.tertiaryGreen,
                              selected: driverChecked,
                              onTap: () {
                                setState(() {
                                  driverChecked = true;
                                  userChecked = false;
                                  brokerChecked = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 26 : 32),

                      // -------- Email --------
                      const SectionLabel("Email"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: emailController,
                        hintText: "example@gmail.com",
                        keyboardType: TextInputType.emailAddress,
                        filled: true,
                      ),

                      SizedBox(height: isMobile ? 18 : 22),

                      // -------- Password --------
                      const SectionLabel("Password"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: passwordController,
                        hintText: "********",
                        obscureText: obscurePassword,
                        filled: false,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // -------- Remember me + Forgot password --------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: rememberMe,
                                  activeColor: Appcolors.primaryBlue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      rememberMe = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Remember me",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              overlayColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(
                                color: Appcolors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 22 : 28),

                      // -------- Sign in button (same cubit logic) --------
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final bool loading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.primaryBlue,
                                disabledBackgroundColor:
                                    Appcolors.primaryBlue.withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: loading
                                  ? null
                                  : () {
                                      context.read<AuthCubit>().logIn(
                                        email: emailController.text,
                                        password: passwordController.text,
                                        role: userChecked
                                            ? "User"
                                            : brokerChecked
                                            ? "Broker"
                                            : driverChecked
                                            ? "Driver"
                                            : "",
                                      );
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isMobile ? 18 : 24),

                      // -------- Sign up row --------
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RoleSelectionPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Appcolors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
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



