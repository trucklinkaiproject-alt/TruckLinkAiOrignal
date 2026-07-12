// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
// import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';

// class VerifyEmailPage extends StatefulWidget {
//   const VerifyEmailPage({
//     super.key,
//     required this.email,
//     required this.password,
//   });

//   final String email;
//   final String password;

//   @override
//   State<VerifyEmailPage> createState() => _VerifyEmailPageState();
// }

// class _VerifyEmailPageState extends State<VerifyEmailPage> {
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthCubit, AuthState>(
//       listener: (context, state) {
//         if (state is AuthVerificationEmailSent) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Verification email resent")),
//           );
//         }

//         if (state is AuthSuccess) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Email verified! Please log in.")),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => LogInPage()),
//           );
//         }

//         if (state is AuthEmailNotVerified) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Not verified yet. Please check your inbox."),
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
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.mark_email_unread_outlined,
//                     size: 80,
//                     color: Appcolors.primaryBlue,
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     "Please verify your email",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "We've sent a verification link to ${widget.email}",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                   const SizedBox(height: 30),

//                   BlocBuilder<AuthCubit, AuthState>(
//                     builder: (context, state) {
//                       final isLoading = state is AuthLoading;
//                       return Column(
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Appcolors.primaryBlue,
//                               minimumSize: const Size(double.infinity, 50),
//                             ),
//                             onPressed: isLoading
//                                 ? null
//                                 : () {
//                                     context
//                                         .read<AuthCubit>()
//                                         .checkEmailVerified(
//                                           email: widget.email,
//                                           password: widget.password,
//                                           role: context
//                                               .read<AuthCubit>()
//                                               .selectedRole,
//                                         );
//                                   },
//                             child: Text(
//                               isLoading
//                                   ? "Checking..."
//                                   : "I've verified, continue",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           TextButton(
//                             onPressed: isLoading
//                                 ? null
//                                 : () {
//                                     context
//                                         .read<AuthCubit>()
//                                         .resendVerificationEmail(
//                                           email: widget.email,
//                                           password: widget.password,
//                                         );
//                                   },
//                             child: const Text("Resend email"),
//                           ),
//                           TextButton(
//                             onPressed: isLoading
//                                 ? null
//                                 : () async {
//                                     await context
//                                         .read<AuthCubit>()
//                                         .cancelSignUp(
//                                           email: widget.email,
//                                           password: widget.password,
//                                         );
//                                     if (context.mounted) {
//                                       Navigator.pop(
//                                         context,
//                                       ); // back to SignUpPage, form still filled
//                                     }
//                                   },
//                             child: const Text(
//                               "Entered the wrong email? Go back",
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ],
//               ),
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
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/logInPage.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthVerificationEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verification email resent")),
          );
        }

        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email verified! Please log in.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LogInPage()),
          );
        }

        if (state is AuthEmailNotVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Not verified yet. Please check your inbox."),
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

              final double horizontalPadding = isMobile ? 24 : width * 0.14;

              final double badgeSize = (width * 0.22).clamp(84.0, 110.0);

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: height),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // -------- Icon badge --------
                        Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: badgeSize * 0.45,
                            color: Appcolors.primaryBlue,
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          "Please verify your email",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: "We've sent a verification link to ",
                              ),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 34),

                        // -------- Actions (same cubit calls) --------
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return Column(
                              children: [
                                SizedBox(
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
                                        borderRadius:
                                            BorderRadius.circular(28),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            context
                                                .read<AuthCubit>()
                                                .checkEmailVerified(
                                                  email: widget.email,
                                                  password: widget.password,
                                                  role: context
                                                      .read<AuthCubit>()
                                                      .selectedRole,
                                                );
                                          },
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            "I've verified, continue",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                TextButton(
                                  style: TextButton.styleFrom(
                                    overlayColor: Colors.transparent,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context
                                              .read<AuthCubit>()
                                              .resendVerificationEmail(
                                                email: widget.email,
                                                password: widget.password,
                                              );
                                        },
                                  child: Text(
                                    "Resend email",
                                    style: TextStyle(
                                      color: Appcolors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),

                                TextButton(
                                  style: TextButton.styleFrom(
                                    overlayColor: Colors.transparent,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          await context
                                              .read<AuthCubit>()
                                              .cancelSignUp(
                                                email: widget.email,
                                                password: widget.password,
                                              );
                                          if (context.mounted) {
                                            Navigator.pop(
                                              context,
                                            ); // back to SignUpPage, form still filled
                                          }
                                        },
                                  child: const Text(
                                    "Entered the wrong email? Go back",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
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