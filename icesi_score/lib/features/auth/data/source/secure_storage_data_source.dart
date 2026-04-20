import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/auth_user.dart';

const _kSessionKey = 'icesi_session';

class SecureStorageDataSource {
  final FlutterSecureStorage _storage;

  SecureStorageDataSource([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession(AuthUser user) async {
    final json = jsonEncode({
      'id': user.id,
      'email': user.email,
      'fullName': user.fullName,
      'phone': user.phone,
      'university': user.university,
      'role': user.role,
    });
    await _storage.write(key: _kSessionKey, value: json);
  }

  Future<AuthUser?> getSession() async {
    final raw = await _storage.read(key: _kSessionKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AuthUser(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String?,
      university: map['university'] as String?,
      role: map['role'] as String,
    );
  }

  Future<void> clearSession() => _storage.delete(key: _kSessionKey);
}
