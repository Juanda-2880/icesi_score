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
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser(
        id: body['id'] as String,
        email: body['email'] as String,
        fullName: (body['fullName'] as String?) ?? '',
        phone: body['phone'] as String?,
        university: body['university'] as String?,
        role: (body['role'] as String?) ?? 'NORMAL',
      );
    }

    throw Exception('Error al obtener el perfil (${response.statusCode}).');
  }
}
