abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String? role;
  AuthSuccess({this.role});
}


class AuthEmailVerified extends AuthState {
  final String email;
  AuthEmailVerified(this.email);
}

class AuthEmailNotVerified extends AuthState {
  final String email;
  AuthEmailNotVerified(this.email);
}

class AuthVerificationEmailSent extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}
class AuthPasswordResetEmailSent extends AuthState {}

class AuthRoleName extends AuthState {
  final String role;
  AuthRoleName(this.role);
}
