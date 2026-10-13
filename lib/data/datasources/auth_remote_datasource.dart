import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/session_model.dart';

class AuthRemoteDatasource {
  Future<SessionModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Correo o contraseña incorrectos');
    }
    
    return SessionModel.fromJson(jsonDecode(response.body));
  }

  Future<void> register(String nombre, String email, String telefono, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'password': password
      }),
    );
    
    if (response.statusCode != 201) {
      throw Exception('No se pudo crear la cuenta');
    }
  }
}