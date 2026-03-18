import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _roleKey = 'user_role';

  // Guardar el rol
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    print('✅ Rol guardado: $role');
  }

  // Obtener el rol
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // Eliminar el rol (al cerrar sesión)
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}
