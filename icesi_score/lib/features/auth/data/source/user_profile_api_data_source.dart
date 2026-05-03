import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/auth_user.dart';
import '../../../../amplifyconfiguration.dart' show apiBaseUrl;
import 'user_profile_data_source.dart';

const _kApiBase = apiBaseUrl;

class UserProfileApiDataSource implements UserProfileDataSource {
  final http.Client _client;

  UserProfileApiDataSource([http.Client? client])
      : _client = client ?? http.Client();

  @override
  Future<AuthUser> fetchProfile(String idToken) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/user/profile'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    throw Exception('Error al obtener el perfil (${response.statusCode}).');
  }

  @override
  Future<AuthUser> updateProfile({
    required String idToken,
    required String id,
    required String fullName,
    required String phone,
    required String university,
  }) async {
    final response = await _client.put(
      Uri.parse('$_kApiBase/user/profile'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'university': university,
      }),
    );

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    throw Exception('Error al actualizar el perfil (${response.statusCode}).');
  }

  @override
  Future<void> deleteAccount({required String idToken}) async {
    final response = await _client.delete(
      Uri.parse('$_kApiBase/user'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la cuenta (${response.statusCode}).');
    }
  }

  @override
  Future<void> createAdminUser({
    required String idToken,
    required String fullName,
    required String email,
    required String phone,
    required String university,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/users'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'university': university,
      }),
    );

    if (response.statusCode == 201) return;
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para crear administradores.');
    }
    if (response.statusCode == 409) {
      throw Exception('Ya existe un usuario con ese correo.');
    }
    throw Exception('Error al crear el administrador. Intenta de nuevo.');
  }

  AuthUser _parseUser(String responseBody) {
    final body = jsonDecode(responseBody) as Map<String, dynamic>;
    return AuthUser(
      id: body['id'] as String,
      email: body['email'] as String,
      fullName: (body['fullName'] as String?) ?? '',
      phone: body['phone'] as String?,
      university: body['university'] as String?,
      role: (body['role'] as String?) ?? 'NORMAL',
    );
  }
}
