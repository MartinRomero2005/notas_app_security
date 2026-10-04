import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SessionController extends ChangeNotifier {
  SessionController({SessionStorage? storage})
    : _storage = storage ?? SecureSessionStorage();

  static const _tokenKey = 'session_token';
  static const _emailKey = 'session_email';

  final SessionStorage _storage;
  String? _token;
  String? _userEmail;
  bool _loading = true;

  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _userEmail != null;
  String? get userEmail => _userEmail;

  Future<void> restore() async {
    try {
      final token = await _storage.read(_tokenKey);
      final email = await _storage.read(_emailKey);
      if (token != null && email != null) {
        _token = token;
        _userEmail = email;
      } else {
        await _storage.delete(_tokenKey);
        await _storage.delete(_emailKey);
      }
    } catch (_) {
      _token = null;
      _userEmail = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@') || password.trim().length < 6) {
      throw const FormatException('Ingresa un correo y contraseña válidos.');
    }

    final token = _createToken();
    await _storage.write(_tokenKey, token);
    try {
      await _storage.write(_emailKey, normalizedEmail);
    } catch (_) {
      await _storage.delete(_tokenKey);
      rethrow;
    }

    _token = token;
    _userEmail = normalizedEmail;
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_emailKey);
    _token = null;
    _userEmail = null;
    notifyListeners();
  }

  String _createToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
