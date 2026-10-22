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

  // --- NUEVO MÉTODO PARA EL ACCESO DE CLIENTES ---
  Future<SessionModel> loginCliente(String nic, String cedula) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login-cliente'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nic': nic, 'cedula': cedula}),
    );

    if (response.statusCode != 200) {
      throw Exception('NIC o número de cédula incorrectos');
    }

    return SessionModel.fromJson(jsonDecode(response.body));
  }

  Future<void> registerCliente(
      String nombre, String nic, String cedula, String telefono) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/auth/register-cliente'), // Asegúrate de crear este endpoint en Spring Boot
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'nic': nic,
        'cedula': cedula,
        'telefono': telefono,
        'rol': 'CLIENTE'
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
          'Error al registrar: verifica que la Cédula o NIC no estén repetidos.');
    }
  }

  Future<void> register(
      String nombre, String email, String telefono, String password) async {
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
