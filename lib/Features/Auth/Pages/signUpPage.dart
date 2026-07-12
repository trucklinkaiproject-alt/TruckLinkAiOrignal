// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// // import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
// // import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
// // import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
// // import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';
// // import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

// // class SignUpPage extends StatefulWidget {
// //   const SignUpPage({super.key});

// //   @override
// //   State<SignUpPage> createState() => _SignUpPageState();
// // }

// // class _SignUpPageState extends State<SignUpPage> {
// //   final TextEditingController emailController = TextEditingController();
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController phoneController = TextEditingController();
// //   final TextEditingController passwordController = TextEditingController();
// //   final TextEditingController confirmPasswordController =
// //       TextEditingController();

// //   @override
// //   void dispose() {
// //     emailController.dispose();
// //     nameController.dispose();
// //     phoneController.dispose();
// //     passwordController.dispose();
// //     confirmPasswordController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocListener<AuthCubit, AuthState>(
// //       listener: (context, state) {
// //         if (state is AuthSuccess) {
// //           ScaffoldMessenger.of(
// //             context,
// //           ).showSnackBar(const SnackBar(content: Text("Signup Successful")));

// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(builder: (context) => LogInPage()),
// //           );
// //         }

// //         if (state is AuthFailure) {
// //           ScaffoldMessenger.of(
// //             context,
// //           ).showSnackBar(SnackBar(content: Text(state.error)));
// //         }
// //       },
// //       child: Scaffold(
// //         body: SafeArea(
// //           child: Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //             width: double.infinity,
// //             height: double.infinity,
// //             child: SingleChildScrollView(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Align(
// //                     alignment: Alignment.topLeft,
// //                     child: IconButton(
// //                       onPressed: () {
// //                         Navigator.pop(context);
// //                       },
// //                       icon: Icon(
// //                         Icons.arrow_back,
// //                         color: Appcolors.primaryBlue,
// //                         size: 30,
// //                       ),
// //                     ),
// //                   ),
// //                   Center(
// //                     child: SizedBox(
// //                       width: 100,
// //                       height: 100,
// //                       child: Image.asset(
// //                         "assets/Images/TruckLink AI.png",
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                   ),
// //                   Center(
// //                     child: Text(
// //                       "TruckLink AI",
// //                       style: TextStyle(
// //                         fontSize: 34,
// //                         fontWeight: FontWeight.w900,
// //                         color: Appcolors.primaryBlue,
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 10),
// //                   const Text(
// //                     "Create an Account!",
// //                     style: TextStyle(
// //                       fontSize: 20,
// //                       fontWeight: FontWeight.w900,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),

// //                   SignUpTextField(hintText: "Name", controller: nameController),
// //                   SignUpTextField(
// //                     hintText: "Email",
// //                     controller: emailController,
// //                     type: TextInputType.emailAddress,
// //                   ),
// //                   SignUpTextField(
// //                     hintText: "Phone Number",
// //                     controller: phoneController,
// //                     type: TextInputType.phone,
// //                   ),
// //                   SignUpTextField(
// //                     hintText: "Password",
// //                     controller: passwordController,
// //                     obscureText: true,
// //                   ),
// //                   SignUpTextField(
// //                     hintText: "Confirm Password",
// //                     controller: confirmPasswordController,
// //                     obscureText: true,
// //                   ),

// //                   const SizedBox(height: 20),

// //                   BlocBuilder<AuthCubit, AuthState>(
// //                     builder: (context, state) {
// //                       return ContinueButton(
// //                         text: state is AuthLoading ? "Loading..." : "SignUp",
// //                         clr: Appcolors.primaryBlue,
// //                         onTap: state is AuthLoading
// //                             ? null
// //                             : () {
// //                                 if (emailController.text.isNotEmpty &&
// //                                     passwordController.text.isNotEmpty &&
// //                                     nameController.text.isNotEmpty &&
// //                                     phoneController.text.isNotEmpty &&
// //                                     confirmPasswordController.text.isNotEmpty) {
// //                                   if (passwordController.text ==
// //                                       confirmPasswordController.text) {
// //                                     context.read<AuthCubit>().signUp(
// //                                       name: nameController.text,
// //                                       email: emailController.text,
// //                                       phone: phoneController.text,
// //                                       password: passwordController.text,
// //                                     );
// //                                   } else {
// //                                     ScaffoldMessenger.of(context).showSnackBar(
// //                                       SnackBar(
// //                                         content: Text("Passwords do not match"),
// //                                       ),
// //                                     );
// //                                     return;
// //                                   }
// //                                 } else {
// //                                   ScaffoldMessenger.of(context).showSnackBar(
// //                                     SnackBar(
// //                                       content: Text(
// //                                         "Please fill in all fields",
// //                                       ),
// //                                     ),
// //                                   );
// //                                   return;
// //                                 }
// //                               },
// //                       );
// //                     },
// //                   ),

// //                   const SizedBox(height: 10),

// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       const Text(
// //                         "Already have an account?",
// //                         style: TextStyle(fontSize: 15, color: Colors.grey),
// //                       ),
// //                       const SizedBox(width: 10),
// //                       GestureDetector(
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (context) => LogInPage(),
// //                             ),
// //                           );
// //                         },
// //                         child: const Text(
// //                           "Log In",
// //                           style: TextStyle(
// //                             color: Colors.black,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/verifyEmailPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   @override
//   void dispose() {
//     emailController.dispose();
//     nameController.dispose();
//     phoneController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthCubit, AuthState>(
//       listener: (context, state) {
//         if (state is AuthSuccess) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("Signup Successful")));

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => LogInPage()),
//           );
//         }

//         if (state is AuthEmailNotVerified) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VerifyEmailPage(
//                 email: emailController.text,
//                 password: passwordController.text,
//               ),
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

//               final double logoSize = (width * 0.08).clamp(80.0, 120.0);

//               final double titleFont = (width * 0.03).clamp(28.0, 38.0);

//               final double headingFont = (width * 0.02).clamp(20.0, 28.0);

//               return SingleChildScrollView(
//                 child: Container(
//                   width: double.infinity,
//                   constraints: BoxConstraints(minHeight: height),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: horizontalPadding,
//                     vertical: 15,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
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

//                       SizedBox(height: isMobile ? 10 : 20),

//                       Center(
//                         child: SizedBox(
//                           width: logoSize,
//                           height: logoSize,
//                           child: Image.asset(
//                             "assets/Images/TruckLink AI.png",
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: isMobile ? 10 : 15),

//                       Center(
//                         child: Text(
//                           "TruckLink AI",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: titleFont,
//                             fontWeight: FontWeight.w900,
//                             color: Appcolors.primaryBlue,
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: isMobile ? 20 : 30),

//                       Text(
//                         "Create an Account!",
//                         style: TextStyle(
//                           fontSize: headingFont,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.black,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       SignUpTextField(
//                         hintText: "Jhon",
//                         label: "Name",
//                         controller: nameController,
//                       ),

//                       SignUpTextField(
//                         hintText: "example@gmail.com",
//                         label: "Email",
//                         controller: emailController,
//                         type: TextInputType.emailAddress,
//                       ),

//                       SignUpTextField(
//                         hintText: "03XXXXXXXXX",
//                         label: "Phone Number",
//                         controller: phoneController,
//                         type: TextInputType.phone,
//                       ),

//                       SignUpTextField(
//                         hintText: "********",
//                         label: "Password",
//                         controller: passwordController,
//                         obscureText: true,
//                       ),

//                       SignUpTextField(
//                         hintText: "********",
//                         label: "Confirm Password",
//                         controller: confirmPasswordController,
//                         obscureText: true,
//                       ),

//                       const SizedBox(height: 25),

//                       BlocBuilder<AuthCubit, AuthState>(
//                         builder: (context, state) {
//                           return ContinueButton(
//                             text: state is AuthLoading
//                                 ? "Loading..."
//                                 : "SignUp",
//                             clr: Appcolors.primaryBlue,
//                             onTap: state is AuthLoading
//                                 ? null
//                                 : () {
//                                     if (emailController.text.isNotEmpty &&
//                                         passwordController.text.isNotEmpty &&
//                                         nameController.text.isNotEmpty &&
//                                         phoneController.text.isNotEmpty &&
//                                         confirmPasswordController
//                                             .text
//                                             .isNotEmpty) {
//                                       if (passwordController.text ==
//                                           confirmPasswordController.text) {
//                                         if (!RegExp(
//                                           r'^03[0-9]{9}$',
//                                         ).hasMatch(phoneController.text)) {
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 "Please enter a valid 11-digit phone number starting with 03",
//                                               ),
//                                             ),
//                                           );
//                                           return;
//                                         }
//                                         context.read<AuthCubit>().signUp(
//                                           name: nameController.text,
//                                           email: emailController.text,
//                                           phone: phoneController.text,
//                                           password: passwordController.text,
//                                         );
//                                       } else {
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           const SnackBar(
//                                             content: Text(
//                                               "Passwords do not match",
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     } else {
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                             "Please fill in all fields",
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   },
//                           );
//                         },
//                       ),

//                       const SizedBox(height: 20),

//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                             "Already have an account?",
//                             style: TextStyle(fontSize: 15, color: Colors.grey),
//                           ),
//                           const SizedBox(width: 10),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => LogInPage(),
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               "Log In",
//                               style: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),
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
import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/verifyEmailPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/pillTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/selectionLabel.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ------- UI-only, not tied to any logic -------
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Signup Successful")));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LogInPage()),
          );
        }

        if (state is AuthEmailNotVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailPage(
                email: emailController.text,
                password: passwordController.text,
              ),
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

              final double titleFont = (width * 0.07).clamp(22.0, 28.0);

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

                      SizedBox(height: isMobile ? 20 : 28),

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
                              "Create an account to get started",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: headingFont,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 26 : 34),

                      // -------- Name --------
                      const SectionLabel("Name"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: nameController,
                        hintText: "Jhon",
                      ),

                      const SizedBox(height: 16),

                      // -------- Email --------
                      const SectionLabel("Email"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: emailController,
                        hintText: "example@gmail.com",
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // -------- Phone --------
                      const SectionLabel("Phone Number"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: phoneController,
                        hintText: "03XXXXXXXXX",
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // -------- Password --------
                      const SectionLabel("Password"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: passwordController,
                        hintText: "********",
                        obscureText: obscurePassword,
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

                      const SizedBox(height: 16),

                      // -------- Confirm Password --------
                      const SectionLabel("Confirm Password"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: confirmPasswordController,
                        hintText: "********",
                        obscureText: obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: isMobile ? 26 : 32),

                      // -------- Sign up button (same validation/cubit logic) --------
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
                                      if (emailController.text.isNotEmpty &&
                                          passwordController
                                              .text
                                              .isNotEmpty &&
                                          nameController.text.isNotEmpty &&
                                          phoneController.text.isNotEmpty &&
                                          confirmPasswordController
                                              .text
                                              .isNotEmpty) {
                                        if (passwordController.text ==
                                            confirmPasswordController.text) {
                                          if (!RegExp(
                                            r'^03[0-9]{9}$',
                                          ).hasMatch(phoneController.text)) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Please enter a valid 11-digit phone number starting with 03",
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          context.read<AuthCubit>().signUp(
                                            name: nameController.text,
                                            email: emailController.text,
                                            phone: phoneController.text,
                                            password:
                                                passwordController.text,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Passwords do not match",
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please fill in all fields",
                                            ),
                                          ),
                                        );
                                      }
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
                                      "Sign Up",
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

                      // -------- Log in row --------
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
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
                                    builder: (context) => LogInPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Log In",
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

