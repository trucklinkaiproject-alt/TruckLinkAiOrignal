
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
                     
                      BackArrowButton(onTap: () => Navigator.pop(context)),

                      SizedBox(height: isMobile ? 20 : 28),

                     
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

                      
                      const SectionLabel("Name"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: nameController,
                        hintText: "Jhon",
                      ),

                      const SizedBox(height: 16),

                      
                      const SectionLabel("Email"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: emailController,
                        hintText: "example@gmail.com",
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                     
                      const SectionLabel("Phone Number"),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: phoneController,
                        hintText: "03XXXXXXXXX",
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

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

