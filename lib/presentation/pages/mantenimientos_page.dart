import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

// --- MODELO ---
class MantenimientoProgramado {
  final int id;
  final String sector;
  final String descripcion;
  final String fechaInicio;
  final String fechaFin;
  final String estado;

  MantenimientoProgramado({
    required this.id,
    required this.sector,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
  });

  factory MantenimientoProgramado.fromJson(Map<String, dynamic> json) {
    return MantenimientoProgramado(
      id: json['id'] ?? 0,
      sector: json['sector'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: json['fechaInicio']?.toString().replaceAll('T', ' ') ?? '',
      fechaFin: json['fechaFin']?.toString().replaceAll('T', ' ') ?? '',
      estado: json['estado'] ?? '',
    );
  }
}

// --- VISTA ---
class MantenimientosPage extends StatefulWidget {
  final Session session;
  const MantenimientosPage({super.key, required this.session});

  @override
  State<MantenimientosPage> createState() => _MantenimientosPageState();
}

class _MantenimientosPageState extends State<MantenimientosPage> {
  bool loading = true;
  List<MantenimientoProgramado> mantenimientos = [];

  // Recuerda: Si pruebas en emulador usa 10.0.2.2, si es físico/web usa 127.0.0.1
  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/mantenimientos';

  @override
  void initState() {
    super.initState();
    _cargarMantenimientos();
  }

  bool get isAdmin => widget.session.rol == 'ADMIN';

  Future<void> _cargarMantenimientos() async {
    setState(() => loading = true);
    try {
      // El admin trae todos, los demás solo los activos
      final endpoint = isAdmin ? baseUrl : '$baseUrl/activos';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          mantenimientos = data
              .map((item) => MantenimientoProgramado.fromJson(item))
              .toList();
          // Ordenar para ver los más recientes primero
          mantenimientos = mantenimientos.reversed.toList();
          loading = false;
        });
      } else {
        throw Exception('Error al cargar: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/estado?nuevoEstado=$nuevoEstado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Estado actualizado'),
            backgroundColor: Colors.green));
        _cargarMantenimientos();
      } else {
        throw Exception('Error al actualizar estado');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _mostrarDialogoCrear() {
    final sectorCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final fechaInicioCtrl = TextEditingController(text: '2026-11-15T08:00:00');
    final fechaFinCtrl = TextEditingController(text: '2026-11-15T14:00:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Programar Mantenimiento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: sectorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Sector (Ej. Barrio Centro)')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Descripción del trabajo')),
              TextField(
                  controller: fechaInicioCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fecha Inicio (YYYY-MM-DDTHH:mm:ss)')),
              TextField(
                  controller: fechaFinCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fecha Fin (YYYY-MM-DDTHH:mm:ss)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff176b87)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final response = await http.post(
                  Uri.parse(baseUrl),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${widget.session.token}'
                  },
                  body: jsonEncode({
                    'sector': sectorCtrl.text,
                    'descripcion': descCtrl.text,
                    'fechaInicio': fechaInicioCtrl.text,
                    'fechaFin': fechaFinCtrl.text,
                    'estado': 'PROGRAMADO'
                  }),
                );
                if (response.statusCode == 200 || response.statusCode == 201) {
                  _cargarMantenimientos();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Error al crear mantenimiento')));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'PROGRAMADO':
        return Colors.blue;
      case 'EN_CURSO':
        return Colors.orange;
      case 'FINALIZADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cortes y Mantenimientos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xff176b87),
              onPressed: _mostrarDialogoCrear,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : mantenimientos.isEmpty
              ? const Center(child: Text('No hay mantenimientos programados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mantenimientos.length,
                  itemBuilder: (context, index) {
                    final item = mantenimientos[index];
                    final color = _getColorEstado(item.estado);

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.sector,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(item.estado,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.descripcion,
                                style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 8),
                            Text('🕒 Inicio: ${item.fechaInicio}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700])),
                            Text('🏁 Fin: ${item.fechaFin}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700])),

                            // Botones de acción SOLO para ADMIN
                            if (isAdmin) ...[
                              const Divider(height: 24),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.estado == 'PROGRAMADO')
                                    ActionChip(
                                      label: const Text('Iniciar',
                                          style: TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.orange[100],
                                      onPressed: () =>
                                          _cambiarEstado(item.id, 'EN_CURSO'),
                                    ),
                                  if (item.estado == 'EN_CURSO')
                                    ActionChip(
                                      label: const Text('Finalizar',
                                          style: TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.green[100],
                                      onPressed: () =>
                                          _cambiarEstado(item.id, 'FINALIZADO'),
                                    ),
                                  if (item.estado == 'PROGRAMADO')
                                    ActionChip(
                                      label: const Text('Cancelar',
                                          style: TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.red[100],
                                      onPressed: () =>
                                          _cambiarEstado(item.id, 'CANCELADO'),
                                    ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
