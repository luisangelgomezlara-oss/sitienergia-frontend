import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incidencia_model.dart'; // Asegúrate de que el nombre coincida

class IncidenciaRemoteDatasource {
  final String baseUrl = "https://sitienergia-backend.onrender.com/api/..."; 

  Future<bool> crearIncidencia(IncidenciaRequest request, String token) async {
    final url = Uri.parse('$baseUrl/incidencias');
    
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(request.toJson()),
    );

    return response.statusCode == 201; 
  }
}