import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/parent_api_service.dart';
import 'secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storage);
  client.onUnauthorized = () => ref.read(authStateProvider.notifier).logout();
  return client;
});

final parentApiProvider = Provider<ParentApiService>((ref) => ParentApiService(ref.watch(apiClientProvider)));

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userName;
  final String? userPhone;
  const AuthState({required this.status, this.userName, this.userPhone});

  AuthState copyWith({AuthStatus? status, String? userName, String? userPhone}) => AuthState(
        status: status ?? this.status,
        userName: userName ?? this.userName,
        userPhone: userPhone ?? this.userPhone,
      );
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  AuthStateNotifier(this._storage) : super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await _storage.getToken();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    final name = await _storage.getUserName();
    final phone = await _storage.getUserPhone();
    state = AuthState(status: AuthStatus.authenticated, userName: name, userPhone: phone);
  }

  Future<void> loginSuccess({required String token, required String name, required String phone}) async {
    await _storage.saveToken(token);
    await _storage.saveUserInfo(name: name, phone: phone);
    state = AuthState(status: AuthStatus.authenticated, userName: name, userPhone: phone);
  }

  /// Full logout AND "Switch User" both call this - there's no partial
  /// sign-out state, since leaving a stale token or student selection
  /// around risks mixing one guardian's session with another's.
  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(secureStorageProvider));
});

/// The currently selected child, for parents with more than one - every
/// per-student screen reads this rather than each screen re-fetching or
/// guessing which student is "current".
final selectedStudentIdProvider = StateProvider<String?>((ref) => null);
