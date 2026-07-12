// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final TextEditingController emailController = TextEditingController();
//   bool _emailSent = false;

//   @override
//   void dispose() {
//     emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthCubit, AuthState>(
//       listener: (context, state) {
//         if (state is AuthPasswordResetEmailSent) {
//           setState(() => _emailSent = true);
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
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: Icon(Icons.arrow_back, color: Appcolors.primaryBlue),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Forgot Password?",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   _emailSent
//                       ? "Check your inbox — we've sent a password reset link to ${emailController.text}."
//                       : "Enter your email and we'll send you a link to reset your password.",
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 25),

//                 if (!_emailSent) ...[
//                   SignUpTextField(
//                     hintText: "example@gmail.com",
//                     label: "Email",
//                     controller: emailController,
//                     type: TextInputType.emailAddress,
//                   ),
//                   const SizedBox(height: 20),
//                   BlocBuilder<AuthCubit, AuthState>(
//                     builder: (context, state) {
//                       final isLoading = state is AuthLoading;
//                       return ContinueButton(
//                         text: isLoading ? "Sending..." : "Send Reset Link",
//                         clr: Appcolors.primaryBlue,
//                         onTap: isLoading
//                             ? null
//                             : () {
//                                 if (emailController.text.trim().isEmpty) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text("Please enter your email"),
//                                     ),
//                                   );
//                                   return;
//                                 }
//                                 context
//                                     .read<AuthCubit>()
//                                     .sendPasswordResetEmail(
//                                       email: emailController.text.trim(),
//                                     );
//                               },
//                       );
//                     },
//                   ),
//                 ] else ...[
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Appcolors.primaryBlue,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text(
//                       "Back to Login",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Center(
//                     child: TextButton(
//                       style: TextButton.styleFrom(
//                         overlayColor: Colors
//                             .transparent,
//                             foregroundColor:Appcolors.primaryBlue,
//                       ),

//                       onPressed: () {
//                         context.read<AuthCubit>().sendPasswordResetEmail(
//                           email: emailController.text.trim(),
//                         );
//                       },
//                       child: const Text("Resend link"),
//                     ),
//                   ),
//                 ],
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
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/pillTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/selectionLabel.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetEmailSent) {
          setState(() => _emailSent = true);
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

              final double badgeSize = (width * 0.2).clamp(72.0, 96.0);

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

                      SizedBox(height: isMobile ? 26 : 34),

                      // -------- Icon badge + copy (centered) --------
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: badgeSize,
                              height: badgeSize,
                              decoration: BoxDecoration(
                                color: Appcolors.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _emailSent
                                    ? Icons.mark_email_read_outlined
                                    : Icons.lock_reset_outlined,
                                size: badgeSize * 0.45,
                                color: Appcolors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _emailSent ? "Check your inbox" : "Forgot Password?",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _emailSent
                                  ? "We've sent a password reset link to ${emailController.text}."
                                  : "Enter your email and we'll send you a link to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 30 : 38),
                      

                      if (!_emailSent) ...[
                        const SectionLabel("Email"),
                        const SizedBox(height: 8),
                        PillTextField(
                          controller: emailController,
                          hintText: "example@gmail.com",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Appcolors.primaryBlue,
                                  disabledBackgroundColor: Appcolors
                                      .primaryBlue
                                      .withOpacity(0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (emailController.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please enter your email",
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        context
                                            .read<AuthCubit>()
                                            .sendPasswordResetEmail(
                                              email:
                                                  emailController.text.trim(),
                                            );
                                      },
                                child: isLoading
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
                                        "Send Reset Link",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolors.primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              overlayColor: Colors.transparent,
                              foregroundColor: Appcolors.primaryBlue,
                            ),
                            onPressed: () {
                              context.read<AuthCubit>().sendPasswordResetEmail(
                                email: emailController.text.trim(),
                              );
                            },
                            child: const Text(
                              "Resend link",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ],
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
