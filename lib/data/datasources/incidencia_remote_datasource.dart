import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incidencia_model.dart'; // Asegúrate de importar el modelo correcto

class IncidenciaRemoteDatasource {
  final String baseUrl = "https://sitienergia-backend.onrender.com/api"; // URL local con el puente ADB

  Future<bool> crearIncidencia(IncidenciaModel request, String token) async {
    final url = Uri.parse('$baseUrl/incidencias');
    
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(request.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}