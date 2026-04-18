import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  // TODO: Get this from amplifyconfig.dart or a central config file
  // For now, I'll use a placeholder or try to read it from the file.
  static const String _apiEndpoint = 'https://psmue63kcl.execute-api.us-east-2.amazonaws.com/promote-admin';

  static Future<List<Map<String, dynamic>>> listAdmins() async {
    final user = await AuthService.checkExistingSession();
    if (user == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse(_apiEndpoint),
      headers: {
        'Authorization': user.token,
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Error al listar administradores: ${response.body}');
    }
  }

  static Future<void> addAdmin(String email) async {
    final user = await AuthService.checkExistingSession();
    if (user == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {
        'Authorization': user.token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'action': 'add',
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al añadir administrador: ${response.body}');
    }
  }

  static Future<void> removeAdmin(String email) async {
    final user = await AuthService.checkExistingSession();
    if (user == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {
        'Authorization': user.token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'action': 'remove',
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar administrador: ${response.body}');
    }
  }
}
