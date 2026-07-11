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
        backgroundColor: Appcolors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Appcolors.primaryBlue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Please verify your email",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We've sent a verification link to ${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolors.primaryBlue,
                              minimumSize: const Size(double.infinity, 50),
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
                            child: Text(
                              isLoading
                                  ? "Checking..."
                                  : "I've verified, continue",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
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
                            child: const Text("Resend email"),
                          ),
                          TextButton(
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
                              style: TextStyle(color: Colors.red),
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
        ),
      ),
    );
  }
}
