import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class IncidenciaAdminItem {
  final int id;
  final String codigo;
  final String categoria;
  final String descripcion;
  final String fecha;
  final String estado;

  IncidenciaAdminItem({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.estado,
  });
}

class GestionIncidenciasPage extends StatefulWidget {
  final Session session;
  const GestionIncidenciasPage({super.key, required this.session});

  @override
  State<GestionIncidenciasPage> createState() => _GestionIncidenciasPageState();
}

class _GestionIncidenciasPageState extends State<GestionIncidenciasPage> {
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<IncidenciaAdminItem> reportes = [];
  List<IncidenciaAdminItem> filteredReportes = [];

  final String baseUrl = 'http://127.0.0.1:8080/api/incidencias';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReportes);
    _cargarTodasLasIncidencias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodasLasIncidencias() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
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
              : item['categoria']?.toString() ?? 'Falla Eléctrica';
              
          final fechaCruda = item['fechaCreacion']?.toString() ?? '';
          final fechaLimpia = fechaCruda.contains('T') ? fechaCruda.split('T')[0] : fechaCruda;

          return IncidenciaAdminItem(
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
            reportes = list.reversed.toList(); // Mostrar las más nuevas arriba
            filteredReportes = reportes;
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

  Future<void> _actualizarEstado(int id, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/estado?estado=$nuevoEstado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado'), backgroundColor: Colors.green));
        _cargarTodasLasIncidencias(); // Recargar lista
      } else {
        throw Exception('Error al actualizar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _mostrarOpcionesEstado(IncidenciaAdminItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Actualizar Estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded, color: Colors.red),
                title: const Text('PENDIENTE'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'PENDIENTE');
                },
              ),
              ListTile(
                leading: const Icon(Icons.engineering_rounded, color: Colors.orange),
                title: const Text('EN PROCESO'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'EN_PROCESO');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                title: const Text('RESUELTO'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'RESUELTO');
                },
              ),
            ],
          ),
        );
      },
    );
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
      case 'RESUELTO': return Colors.green[700]!;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Incidencias', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
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
                      hintText: 'Buscar incidencias...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredReportes.isEmpty
                      ? const Center(child: Text('No hay incidencias registradas.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReportes.length,
                          itemBuilder: (context, index) {
                            final item = filteredReportes[index];
                            final colorEstado = _getColorEstado(item.estado);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(item.codigo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff176b87))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(item.categoria, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Text(item.descripcion),
                                    const SizedBox(height: 8),
                                    Text('Fecha: ${item.fecha}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                trailing: InkWell(
                                  onTap: () => _mostrarOpcionesEstado(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorEstado.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colorEstado),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(item.estado, style: TextStyle(color: colorEstado, fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit, size: 14, color: colorEstado),
                                      ],
                                    ),
                                  ),
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