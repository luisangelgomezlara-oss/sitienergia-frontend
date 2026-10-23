import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

// Modelo para representar la incidencia/reporte
class IncidenciaItem {
  final int? id;
  final String codigo;
  final String categoria;
  final String descripcion;
  final String fecha;
  final String estado;

  IncidenciaItem({
    this.id,
    required this.codigo,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.estado,
  });
}

class MisReportesPage extends StatefulWidget {
  final Session session;
  const MisReportesPage({super.key, required this.session});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage> {
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<IncidenciaItem> reportes = [];
  List<IncidenciaItem> filteredReportes = [];

  // TODO: Ajusta esta URL a la IP de tu servidor backend local
  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/incidencias';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReportes);
    _cargarReportes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mis-reportes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        final list = data.map((item) {
          final categoriaNombre = (item['categoria'] is Map) 
              ? item['categoria']['nombre'] ?? 'Sin categoría'
              : 'Falla Eléctrica';
              
          final fechaCruda = item['fechaCreacion']?.toString() ?? '';
          final fechaLimpia = fechaCruda.contains('T') ? fechaCruda.split('T')[0] : fechaCruda;

          return IncidenciaItem(
            id: item['id'],
            codigo: 'INC-2026-${item['id'].toString().padLeft(3, '0')}',
            categoria: categoriaNombre,
            descripcion: item['descripcion'] ?? 'Sin detalles',
            fecha: fechaLimpia,
            estado: item['estado'] ?? 'PENDIENTE',
          );
        }).toList();

        if (mounted) {
          setState(() {
            reportes = list;
            filteredReportes = list;
            loading = false;
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
      }
    }
  }

  void _filterReportes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredReportes = reportes.where((r) =>
        r.codigo.toLowerCase().contains(query) ||
        r.categoria.toLowerCase().contains(query) ||
        r.estado.toLowerCase().contains(query)
      ).toList();
    });
  }

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE': return Colors.red[700]!;
      case 'EN_PROCESO': return Colors.orange[800]!;
      case 'RESUELTO':
      case 'ATENDIDO': return Colors.green[700]!;
      default: return Colors.blueGrey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE': return Icons.access_time_rounded;
      case 'EN_PROCESO': return Icons.engineering_rounded;
      case 'RESUELTO':
      case 'ATENDIDO': return Icons.check_circle_outline_rounded;
      default: return Icons.info_outline;
    }
  }

  String _getTextoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE': return 'PENDIENTE';
      case 'EN_PROCESO': return 'EN PROCESO';
      case 'RESUELTO':
      case 'ATENDIDO': return 'RESUELTO';
      default: return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xff176b87),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código, categoría o estado...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredReportes.isEmpty
                      ? const Center(
                          child: Text(
                            'No tienes reportes registrados.',
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReportes.length,
                          itemBuilder: (context, index) {
                            final item = filteredReportes[index];
                            final colorEstado = _getColorEstado(item.estado);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.codigo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xff176b87),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorEstado.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: colorEstado, width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getIconoEstado(item.estado), size: 14, color: colorEstado),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getTextoEstado(item.estado),
                                                style: TextStyle(
                                                  color: colorEstado,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Text(
                                      item.categoria,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.descripcion,
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reportado el ${item.fecha}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}