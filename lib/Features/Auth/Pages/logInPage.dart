import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/forgetPasswordPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
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

  bool userChecked = false;
  bool brokerChecked = false;
  bool driverChecked = false;

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
        backgroundColor: Appcolors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              final bool isMobile = width < 600;

              final double horizontalPadding = isMobile ? 20 : width * 0.12;

              final double logoSize = (width * 0.08).clamp(90.0, 130.0);

              final double titleFont = (width * 0.03).clamp(30.0, 40.0);

              final double headingFont = (width * 0.025).clamp(24.0, 32.0);

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: height),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 15,
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
                            size: isMobile ? 30 : 36,
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 20 : 30),

                      SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: Image.asset(
                          "assets/Images/TruckLink AI.png",
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(
                        "TruckLink AI",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.primaryBlue,
                        ),
                      ),

                      SizedBox(height: isMobile ? 10 : 15),

                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: headingFont,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Login to Continue",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      SizedBox(height: isMobile ? 25 : 40),

                      SignUpTextField(
                        hintText: "example@gmail.com",
                        label: "Email",
                        controller: emailController,
                        type: TextInputType.emailAddress,
                      ),

                      SignUpTextField(
                        hintText: "********",
                        label: "Password",
                        controller: passwordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            style: TextButton.styleFrom(
                              overlayColor: Colors.transparent,
                             
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
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: userChecked,
                                activeColor: Appcolors.primaryBlue,
                                onChanged: (value) {
                                  setState(() {
                                    userChecked = value!;
                                    brokerChecked = false;
                                    driverChecked = false;
                                  });
                                },
                              ),
                              const Text(
                                "User",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Appcolors.primaryBlue,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: brokerChecked,
                                activeColor: Appcolors.secondaryPurple,
                                onChanged: (value) {
                                  setState(() {
                                    brokerChecked = value!;
                                    userChecked = false;
                                    driverChecked = false;
                                  });
                                },
                              ),
                              Text(
                                "Broker",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Appcolors.secondaryPurple,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: driverChecked,
                                activeColor: Appcolors.tertiaryGreen,
                                onChanged: (value) {
                                  setState(() {
                                    driverChecked = value!;
                                    userChecked = false;
                                    brokerChecked = false;
                                  });
                                },
                              ),
                              const Text(
                                "Driver",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Appcolors.tertiaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return ContinueButton(
                            text: state is AuthLoading
                                ? "Logging In..."
                                : "Continue",
                            clr: Appcolors.primaryBlue,
                            onTap: state is AuthLoading
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
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
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

                      const SizedBox(height: 5),
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
