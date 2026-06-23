// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Presentation/Bloc/AuthBloc/authCubit.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Presentation/Pages/logInPage.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Presentation/Widgets/continueButton.dart';

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
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           width: double.infinity,
//           height: double.infinity,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: IconButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     icon: Icon(
//                       Icons.arrow_back,
//                       color: Appcolors.primaryBlue,
//                       size: 30,
//                     ),
//                   ),
//                 ),
//                 Center(
//                   child: Container(
//                     width: 100,
//                     height: 100,
//                     child: Image.asset(
//                       "assets/Images/TruckLink AI.png",
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 Center(
//                   child: Text(
//                     "TruckLink AI",
//                     style: TextStyle(
//                       fontSize: 34,
//                       fontWeight: FontWeight.w900,
//                       color: Appcolors.primaryBlue,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   "Create an Account!",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w900,
//                     color: Colors.black,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 SignUpTextField(hintText: "Name", controller: nameController),
//                 SignUpTextField(hintText: "Email", controller: emailController),
//                 SignUpTextField(
//                   hintText: "Phone Number",
//                   controller: phoneController,
//                 ),
//                 SignUpTextField(
//                   hintText: "Password",
//                   controller: passwordController,
//                 ),
//                 SignUpTextField(
//                   hintText: "Confirm Password",
//                   controller: confirmPasswordController,
//                 ),
//                 SizedBox(height: 20),
//                 ContinueButton(
//                   text: "SignUp",
//                   clr: Appcolors.primaryBlue,
//                   onTap: () {
// if (emailController.text.isNotEmpty &&
//     passwordController.text.isNotEmpty &&
//     nameController.text.isNotEmpty &&
//     phoneController.text.isNotEmpty &&
//     confirmPasswordController.text.isNotEmpty) {
//   if (passwordController.text ==
//       confirmPasswordController.text) {
//     AuthCubit.get(context).signUp(
//       name: nameController.text,
//       email: emailController.text,
//       phone: phoneController.text,
//       password: passwordController.text,
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Passwords do not match")),
//     );
//     return;
//   }
// } else {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("Please fill in all fields")),
//   );
//   return;
// }
//                   },
//                 ),
//                 SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Already have an account?",
//                       style: TextStyle(fontSize: 15, color: Colors.grey),
//                     ),
//                     SizedBox(width: 10),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => LogInPage()),
//                         );
//                       },
//                       child: Text(
//                         "Log In",
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
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
import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

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

        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        size: 30,
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        "assets/Images/TruckLink AI.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "TruckLink AI",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Appcolors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create an Account!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SignUpTextField(hintText: "Name", controller: nameController),
                  SignUpTextField(
                    hintText: "Email",
                    controller: emailController,
                    type: TextInputType.emailAddress,
                  ),
                  SignUpTextField(
                    hintText: "Phone Number",
                    controller: phoneController,
                    type: TextInputType.phone,
                  ),
                  SignUpTextField(
                    hintText: "Password",
                    controller: passwordController,
                    obscureText: true,
                  ),
                  SignUpTextField(
                    hintText: "Confirm Password",
                    controller: confirmPasswordController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return ContinueButton(
                        text: state is AuthLoading ? "Loading..." : "SignUp",
                        clr: Appcolors.primaryBlue,
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                if (emailController.text.isNotEmpty &&
                                    passwordController.text.isNotEmpty &&
                                    nameController.text.isNotEmpty &&
                                    phoneController.text.isNotEmpty &&
                                    confirmPasswordController.text.isNotEmpty) {
                                  if (passwordController.text ==
                                      confirmPasswordController.text) {
                                    context.read<AuthCubit>().signUp(
                                      name: nameController.text,
                                      email: emailController.text,
                                      phone: phoneController.text,
                                      password: passwordController.text,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Passwords do not match"),
                                      ),
                                    );
                                    return;
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please fill in all fields",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              },
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LogInPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
