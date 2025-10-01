import 'package:equatable/equatable.dart';
import '../../model/identity_model.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking if user is authenticated
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - during login or session check
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
class AuthAuthenticated extends AuthState {
  final Identity identity;

  const AuthAuthenticated(this.identity);

  @override
  List<Object?> get props => [identity];
}

/// Unauthenticated state - user needs to log in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state - something went wrong
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
