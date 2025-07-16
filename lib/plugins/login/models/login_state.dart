import 'package:mira/plugins/login/models/user_model.dart';

class LoginState {
  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;

  LoginState({
    required this.isLoggedIn,
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

  LoginState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool? isLoading,
    String? error,
  }) {
    return LoginState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
