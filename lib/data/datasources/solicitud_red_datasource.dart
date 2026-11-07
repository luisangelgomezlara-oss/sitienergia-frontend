import 'dart:convert';
import 'package:http/http.dart' as http;

class SolicitudRedDataSource {
  static const String baseUrl = 'https://sitienergia-backend.onrender.com/api/solicitudes-red';

  Future<bool> radicarSolicitud(
      Map<String, dynamic> datosSolicitud, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/radicar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(datosSolicitud),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error del servidor (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de conexión al radicar solicitud: $e');
      return false;
    }
  }
}
