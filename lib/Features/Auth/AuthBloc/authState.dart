abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String? role;
  AuthSuccess({this.role});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class AuthRoleName extends AuthState {
  final String role;
  AuthRoleName(this.role);
}
