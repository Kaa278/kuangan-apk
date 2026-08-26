import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:kuangan/shared/demo/demo_data.dart';
import 'package:kuangan/shared/models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState({
    required this.status,
    this.user,
    this.error,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.error == error;
  }

  @override
  int get hashCode => status.hashCode ^ user.hashCode ^ error.hashCode;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }

  final _supabase = sb.Supabase.instance.client;
  bool _isDemoMode = false;
  String? _pendingSignupName;
  String? _pendingSignupEmail;
  String? _pendingSignupPassword;

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        _isDemoMode = false;
        final email = session.user.email ?? '';
        String mappedUserId = session.user.id;
        String mappedName = session.user.userMetadata?['name'] ?? email;
        Map<String, dynamic>? userRecord;

        try {
          userRecord = await _supabase
              .from('users')
              .select('id, name, telegram_id')
              .eq('email', email)
              .maybeSingle();

          if (userRecord != null) {
            mappedUserId = userRecord['id'] as String;
            mappedName = userRecord['name'] as String? ?? mappedName;
          }
        } catch (e) {
          debugPrint('Error mapping user from public users table: $e');
        }

        state = AuthState.authenticated(User(
          id: mappedUserId,
          name: mappedName,
          email: email,
          telegramId: userRecord?['telegram_id'] as String?,
        ));
      } else {
        if (_isDemoMode) {
          state = AuthState.authenticated(demoUser);
          return;
        }
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == demoEmail && password == demoPassword) {
      _isDemoMode = true;
      state = AuthState.authenticated(demoUser);
      return true;
    }

    try {
      _isDemoMode = false;
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      String errorMessage = 'Login gagal: ${e.toString()}';

      if (e is sb.AuthApiException &&
          (e.code == 'email_not_confirmed' ||
              e.message.contains('Email not confirmed'))) {
        errorMessage =
            'Email kamu sudah terdaftar, tapi belum dikonfirmasi. Silakan cek inbox email-mu untuk link konfirmasi dari Supabase.';
      }

      state = AuthState.unauthenticated(error: errorMessage);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = AuthState.loading();
    try {
      _pendingSignupName = name.trim();
      _pendingSignupEmail = email.trim().toLowerCase();
      _pendingSignupPassword = password;

      final response = await _supabase.functions.invoke(
        'request-signup-otp',
        body: {
          'name': _pendingSignupName,
          'email': _pendingSignupEmail,
        },
      );
      final error = response.data?['error'];
      if (response.status != 200 || error != null) {
        throw Exception(error ?? 'Gagal mengirim kode verifikasi.');
      }

      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      _pendingSignupName = null;
      _pendingSignupEmail = null;
      _pendingSignupPassword = null;
      state =
          AuthState.unauthenticated(error: 'Registrasi gagal: ${e.toString()}');
      return false;
    }
  }

  String? get pendingSignupEmail => _pendingSignupEmail;
  String? get pendingSignupName => _pendingSignupName;
  String? get pendingSignupPassword => _pendingSignupPassword;

  Future<bool> verifySignupOtp({
    required String email,
    required String token,
    String? name,
  }) async {
    state = AuthState.loading();
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final trimmedToken = token.trim();
      final signupPassword = _pendingSignupPassword;
      if (signupPassword == null || signupPassword.isEmpty) {
        throw Exception(
          'Sesi pendaftaran sudah habis. Silakan daftar ulang untuk kirim kode baru.',
        );
      }

      final userName = (name ?? _pendingSignupName ?? normalizedEmail).trim();

      final response = await _supabase.functions.invoke(
        'verify-signup-otp',
        body: {
          'name': userName,
          'email': normalizedEmail,
          'password': signupPassword,
          'token': trimmedToken,
        },
      );
      final error = response.data?['error'];
      if (response.status != 200 || error != null) {
        throw Exception(error ?? 'Verifikasi kode gagal.');
      }

      await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: signupPassword,
      );

      _pendingSignupEmail = null;
      _pendingSignupName = null;
      _pendingSignupPassword = null;
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(
        error: 'Verifikasi kode gagal: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> resendSignupOtp(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _supabase.functions.invoke(
        'request-signup-otp',
        body: {
          'name': _pendingSignupName ?? 'Pengguna Kuangan',
          'email': normalizedEmail,
        },
      );
      final error = response.data?['error'];
      if (response.status != 200 || error != null) {
        throw Exception(error ?? 'Gagal mengirim ulang kode verifikasi.');
      }
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(
        error: 'Gagal mengirim ulang kode: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final wasDemoMode = _isDemoMode;
    _isDemoMode = false;
    if (!wasDemoMode) {
      await _supabase.auth.signOut();
    }
    state = AuthState.unauthenticated();
  }

  Future<bool> updateProfile(String newName) async {
    if (_isDemoMode && state.user != null) {
      state = AuthState.authenticated(
        User(
          id: state.user!.id,
          name: newName,
          email: state.user!.email,
          telegramId: state.user!.telegramId,
        ),
      );
      return true;
    }
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Update auth metadata
      await _supabase.auth.updateUser(
        sb.UserAttributes(
          data: {'name': newName},
        ),
      );

      // Update public users table if exists
      try {
        await _supabase
            .from('users')
            .update({'name': newName}).eq('email', session.user.email ?? '');
      } catch (e) {
        debugPrint('Error updating public user record: $e');
      }

      // Update local state optimistic
      if (state.status == AuthStatus.authenticated && state.user != null) {
        state = AuthState.authenticated(
          User(id: state.user!.id, name: newName, email: state.user!.email),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_isDemoMode) {
      return true;
    }
    try {
      await _supabase.auth.updateUser(
        sb.UserAttributes(
          password: newPassword,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Password update error: $e');
      return false;
    }
  }
}
