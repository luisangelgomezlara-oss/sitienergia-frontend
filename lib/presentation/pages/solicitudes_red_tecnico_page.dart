import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class SolicitudRedTecnicoItem {
  final int id;
  final String numeroCedula;
  final String numeroNic;
  final String tipoIntervencion;
  final String area;
  final String direccion;
  final String motivo;
  final String fechaCreacion;
  final String estado;
  final String conceptoTecnico;
  final Map<String, dynamic> detallesEspecificos;

  SolicitudRedTecnicoItem({
    required this.id,
    required this.numeroCedula,
    required this.numeroNic,
    required this.tipoIntervencion,
    required this.area,
    required this.direccion,
    required this.motivo,
    required this.fechaCreacion,
    required this.estado,
    required this.conceptoTecnico,
    required this.detallesEspecificos,
  });

  factory SolicitudRedTecnicoItem.fromJson(Map<String, dynamic> json) {
    String fechaLimpia = '';
    final rawFecha = json['fechaCreacion'];
    if (rawFecha != null) {
      if (rawFecha is String) {
        fechaLimpia =
            rawFecha.contains('T') ? rawFecha.split('T')[0] : rawFecha;
      } else if (rawFecha is List && rawFecha.length >= 3) {
        fechaLimpia =
            '${rawFecha[0]}-${rawFecha[1].toString().padLeft(2, '0')}-${rawFecha[2].toString().padLeft(2, '0')}';
      }
    }

    Map<String, dynamic> detalles = {};
    if (json['detallesEspecificos'] != null) {
      if (json['detallesEspecificos'] is Map) {
        detalles = Map<String, dynamic>.from(json['detallesEspecificos']);
      } else if (json['detallesEspecificos'] is String) {
        try {
          detalles = Map<String, dynamic>.from(
              jsonDecode(json['detallesEspecificos']));
        } catch (_) {}
      }
    }

    return SolicitudRedTecnicoItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      numeroCedula: json['numeroCedula']?.toString() ?? '',
      numeroNic: json['numeroNic']?.toString() ?? '',
      tipoIntervencion: json['tipoIntervencion']?.toString() ?? 'SOLICITUD_RED',
      area: json['area']?.toString() ?? 'Redes Eléctricas',
      direccion: json['direccion']?.toString() ?? 'Sin dirección',
      motivo: json['motivo']?.toString() ?? 'Sin motivo',
      fechaCreacion: fechaLimpia,
      estado: json['estado']?.toString() ?? 'EN_EJECUCION',
      conceptoTecnico: json['conceptoTecnico']?.toString() ?? '',
      detallesEspecificos: detalles,
    );
  }
}

class SolicitudesRedTecnicoPage extends StatefulWidget {
  final Session session;
  const SolicitudesRedTecnicoPage({super.key, required this.session});

  @override
  State<SolicitudesRedTecnicoPage> createState() =>
      _SolicitudesRedTecnicoPageState();
}

class _SolicitudesRedTecnicoPageState extends State<SolicitudesRedTecnicoPage> {
  bool loading = true;
  List<SolicitudRedTecnicoItem> solicitudesAsignadas = [];

  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/solicitudes-red';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudesAsignadas();
  }

  int _obtenerIdTecnico() {
    // Forzamos el ID 17 que es donde está asignada la orden en la BD
    return 17;
  }

  Future<void> _cargarSolicitudesAsignadas() async {
    setState(() => loading = true);
    try {
      final tecnicoId = _obtenerIdTecnico();
      final url = Uri.parse('$baseUrl/cuadrilla/$tecnicoId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final list =
            data.map((item) => SolicitudRedTecnicoItem.fromJson(item)).toList();

        if (mounted) {
          setState(() {
            solicitudesAsignadas = list.reversed.toList();
            loading = false;
          });
        }
      } else {
        throw Exception('Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar órdenes asignadas: $e')),
        );
      }
    }
  }

  Future<void> _finalizarSolicitud(
      int id, String nuevoEstado, String concepto) async {
    try {
      final queryParams = Uri(queryParameters: {
        'estado': nuevoEstado,
        'conceptoTecnico': concepto,
      }).query;

      final url = Uri.parse('$baseUrl/$id/estado?$queryParams');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden finalizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _cargarSolicitudesAsignadas();
      } else {
        throw Exception('Error al actualizar (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al procesar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoFinalizar(SolicitudRedTecnicoItem item) {
    final TextEditingController conceptoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Finalizar Orden SOL-${item.id.toString().padLeft(4, '0')}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa el informe / concepto técnico del trabajo realizado:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conceptoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Ej: Se realizó el reemplazo del poste de concreto de 12m...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6070)),
              onPressed: () {
                final concepto = conceptoController.text.trim();
                if (concepto.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('El concepto técnico es obligatorio.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _finalizarSolicitud(item.id, 'COMPLETADO', concepto);
              },
              child: const Text('Completar Trabajo',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_EJECUCION':
        return Colors.purple[700]!;
      case 'COMPLETADO':
        return Colors.green[700]!;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Órdenes de Red Asignadas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E6070),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudesAsignadas,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : solicitudesAsignadas.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes órdenes de red asignadas actualmente.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: solicitudesAsignadas.length,
                  itemBuilder: (context, index) {
                    final item = solicitudesAsignadas[index];
                    final colorEstado = _getColorEstado(item.estado);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SOL-${item.id.toString().padLeft(4, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E6070),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorEstado),
                                  ),
                                  child: Text(
                                    item.estado,
                                    style: TextStyle(
                                      color: colorEstado,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.tipoIntervencion.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Área: ${item.area}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E6070),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dirección: ${item.direccion}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Motivo: ${item.motivo}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (item.detallesEspecificos.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detalles Técnicos de Infraestructura:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...item.detallesEspecificos.entries.map(
                                      (e) => Text(
                                        '• ${e.key}: ${e.value}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (item.conceptoTecnico.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Concepto Registrado: ${item.conceptoTecnico}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.teal),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (item.estado == 'EN_EJECUCION')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E6070),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: Colors.white),
                                  label: const Text(
                                    'Finalizar Trabajo / Concepto',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () =>
                                      _mostrarDialogoFinalizar(item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
