import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';

class TransporterHomePage extends StatelessWidget {
  const TransporterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read <AuthCubit>().logOut(context);
    return const Placeholder();
  }
}
