import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/auth_user.dart';
import '../../../../amplifyconfiguration.dart' show apiBaseUrl;

const _kApiBase = apiBaseUrl;

class UserProfileApiDataSource {
  final http.Client _client;

  UserProfileApiDataSource([http.Client? client])
      : _client = client ?? http.Client();

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
