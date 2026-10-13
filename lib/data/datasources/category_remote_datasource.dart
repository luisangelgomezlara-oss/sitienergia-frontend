import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../domain/entities/category.dart';

class CategoryRemoteDatasource {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };

  Future<List<Category>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categorias'), 
      headers: _headers(token)
    );
    if (response.statusCode >= 300) throw Exception('No se pudieron cargar los datos');
    return jsonDecode(response.body); 
  }

  Future<void> createCategory(String token, String nombre, String area) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categorias'),
      headers: _headers(token),
      body: jsonEncode({'nombre': nombre, 'area': area})
    );
    if (response.statusCode >= 300) throw Exception('Error al crear');
  }
  
  Future<void> updateCategory(String token, int id, String nombre, String area) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categorias/$id'),
      headers: _headers(token),
      body: jsonEncode({'nombre': nombre, 'area': area})
    );
    if (response.statusCode >= 300) throw Exception('No se pudo actualizar la categoría');
  }

  Future<void> deleteCategory(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categorias/$id'),
      headers: _headers(token)
    );
    if (response.statusCode >= 300) throw Exception('No se pudo desactivar la categoría');
  }
}