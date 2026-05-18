import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../models/user.dart';

const _storage = FlutterSecureStorage();

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({User? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> init() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;
    await _fetchProfile();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _saveTokens(res.data);
      await _fetchProfile();
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: msg.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (username != null && username.isNotEmpty) 'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      await _saveTokens(res.data);
      await _fetchProfile();
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: msg.toString());
      return false;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access_token']);
    if (data['refresh_token'] != null) {
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient.dio.get('/api/auth/me');
      state = AuthState(user: User.fromJson(res.data));
    } catch (_) {
      await logout();
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    try {
      await ApiClient.dio.post('/api/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return null;
    } on DioException catch (e) {
      return e.response?.data?['detail']?.toString() ?? 'Failed';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
