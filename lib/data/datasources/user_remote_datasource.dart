import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class UserRemoteDatasource {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };

  Future<List<UserModel>> getUsers(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios'), headers: _headers(token));
    if (response.statusCode >= 300) throw Exception('No se pudieron cargar los usuarios');
    
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> updateUser(String token, int id, String nombre, String rol, String telefono, bool activo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: _headers(token),
      body: jsonEncode({'nombre': nombre, 'rol': rol, 'telefono': telefono, 'activo': activo})
    );
    if (response.statusCode >= 300) throw Exception('No se pudo actualizar el usuario');
  }

  Future<void> deleteUser(String token, int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/usuarios/$id'), headers: _headers(token));
    if (response.statusCode >= 300) throw Exception('No se pudo desactivar el usuario');
  }
}