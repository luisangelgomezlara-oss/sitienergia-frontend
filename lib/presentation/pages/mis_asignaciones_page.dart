import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';
import '../widgets/detalle_incidencia_modal.dart';

class IncidenciaTecnicoItem {
  final int id;
  final String codigo;
  final String categoria;
  final String descripcion;
  final String fecha;
  final String estado;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final String? imagenUrl;

  IncidenciaTecnicoItem({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.estado,
    required this.direccion,
    this.latitud,
    this.longitud,
    this.imagenUrl,
  });
}

class MisAsignacionesPage extends StatefulWidget {
  final Session session;
  const MisAsignacionesPage({super.key, required this.session});

  @override
  State<MisAsignacionesPage> createState() => _MisAsignacionesPageState();
}

class _MisAsignacionesPageState extends State<MisAsignacionesPage> {
  bool loading = true;
  List<IncidenciaTecnicoItem> asignaciones = [];
  final String baseUrl =
      'https://sitienergia-backend.onrender.com/api/incidencias';

  @override
  void initState() {
    super.initState();
    _cargarAsignaciones();
  }

  Future<void> _cargarAsignaciones() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mis-asignaciones'),
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
          final fechaLimpia =
              fechaCruda.contains('T') ? fechaCruda.split('T')[0] : fechaCruda;

          return IncidenciaTecnicoItem(
            id: item['id'],
            codigo: 'INC-2026-${item['id'].toString().padLeft(3, '0')}',
            categoria: categoriaNombre,
            descripcion: item['descripcion'] ?? 'Sin detalles',
            fecha: fechaLimpia,
            estado: item['estado'] ?? 'PENDIENTE',
            direccion: item['direccion'] ??
                item['ubicacion'] ??
                'Dirección no registrada',
            latitud: item['latitud'] != null
                ? double.tryParse(item['latitud'].toString())
                : null,
            longitud: item['longitud'] != null
                ? double.tryParse(item['longitud'].toString())
                : null,
            imagenUrl: item['imagen'],
          );
        }).toList();

        if (mounted) {
          setState(() {
            asignaciones = list.reversed.toList();
            loading = false;
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Estado actualizado'),
              backgroundColor: Colors.green));
          _cargarAsignaciones();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _mostrarOpcionesEstado(IncidenciaTecnicoItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Reportar Avance',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.engineering_rounded, color: Colors.orange),
                title: const Text('Marcar como EN PROCESO'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'EN_PROCESO');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.green),
                title: const Text('Marcar como RESUELTO'),
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

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.red[700]!;
      case 'EN_PROCESO':
        return Colors.orange[800]!;
      case 'RESUELTO':
        return Colors.green[700]!;
      default:
        return Colors.blueGrey;
    }
  }

  String _limpiarBase64(String base64String) {
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }
    return base64String.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Asignaciones',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : asignaciones.isEmpty
              ? const Center(child: Text('No tienes trabajos asignados hoy.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: asignaciones.length,
                  itemBuilder: (context, index) {
                    final item = asignaciones[index];
                    final colorEstado = _getColorEstado(item.estado);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => mostrarDetalleIncidencia(
                          context: context,
                          codigo: item.codigo,
                          categoria: item.categoria,
                          descripcion: item.descripcion,
                          estado: item.estado,
                          fecha: item.fecha,
                          ubicacion: item.direccion,
                          latitud: item.latitud,
                          longitud: item.longitud,
                          imagen: item.imagenUrl,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.codigo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xff176b87),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.categoria,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Botón directo a Google Maps en las coordenadas
                                    InkWell(
                                      onTap: () => abrirEnGoogleMaps(
                                        context,
                                        lat: item.latitud,
                                        lng: item.longitud,
                                        ubicacionTexto: item.direccion,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 16,
                                                color: Colors.redAccent),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item.direccion,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.directions,
                                                size: 16,
                                                color: Color(0xff176b87)),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    Text(
                                      item.descripcion,
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),

                                    if (item.imagenUrl != null &&
                                        item.imagenUrl!.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(
                                            base64Decode(_limpiarBase64(
                                                item.imagenUrl!)),
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12)),
                                          ),
                                        ),
                                      ),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Fecha asignación: ${item.fecha}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ),
                                        const Text(
                                          'Ver mapa',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff176b87),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.map_outlined,
                                            size: 14, color: Color(0xff176b87)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Botón de cambio de estado
                              InkWell(
                                onTap: () => _mostrarOpcionesEstado(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorEstado),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.estado,
                                        style: TextStyle(
                                          color: colorEstado,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.handyman,
                                          size: 14, color: colorEstado),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
