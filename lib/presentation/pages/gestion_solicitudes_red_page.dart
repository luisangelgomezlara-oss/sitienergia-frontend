import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class SolicitudRedAdminItem {
  final int id;
  final String numeroCedula;
  final String numeroNic;
  final String tipoIntervencion;
  final String area;
  final String direccion;
  final String motivo;
  final String fechaCreacion;
  final String estado;
  final Map<String, dynamic> detallesEspecificos;

  SolicitudRedAdminItem({
    required this.id,
    required this.numeroCedula,
    required this.numeroNic,
    required this.tipoIntervencion,
    required this.area,
    required this.direccion,
    required this.motivo,
    required this.fechaCreacion,
    required this.estado,
    required this.detallesEspecificos,
  });

  factory SolicitudRedAdminItem.fromJson(Map<String, dynamic> json) {
    final fechaCruda = json['fechaCreacion']?.toString() ?? '';
    final fechaLimpia =
        fechaCruda.contains('T') ? fechaCruda.split('T')[0] : fechaCruda;

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

    final tipo = json['tipoIntervencion']?.toString() ?? 'SOLICITUD_RED';
    String areaInferida = 'Redes Eléctricas';
    if (tipo.contains('TRANSFORMADOR')) {
      areaInferida = 'Obras Civiles';
    } else if (tipo.contains('COMERCIAL')) {
      areaInferida = 'Comerciales';
    }

    return SolicitudRedAdminItem(
      id: json['id'] ?? 0,
      numeroCedula: json['numeroCedula'] ?? '',
      numeroNic: json['numeroNic'] ?? '',
      tipoIntervencion: tipo,
      area: json['area'] ?? json['categoria'] ?? areaInferida,
      direccion: json['direccion'] ?? 'Sin dirección',
      motivo: json['motivo'] ?? 'Sin motivo',
      fechaCreacion: fechaLimpia,
      estado: json['estado'] ?? 'RADICADA',
      detallesEspecificos: detalles,
    );
  }
}

class GestionSolicitudesRedPage extends StatefulWidget {
  final Session session;
  const GestionSolicitudesRedPage({super.key, required this.session});

  @override
  State<GestionSolicitudesRedPage> createState() =>
      _GestionSolicitudesRedPageState();
}

class _GestionSolicitudesRedPageState extends State<GestionSolicitudesRedPage> {
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<SolicitudRedAdminItem> solicitudes = [];
  List<SolicitudRedAdminItem> filteredSolicitudes = [];

  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/solicitudes-red';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSolicitudes);
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Normalización para ignorar tildes y mayúsculas
  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  // Extracción flexible del área del técnico (anidada o directa)
  String _obtenerAreaTecnico(dynamic u) {
    if (u == null) return '';
    if (u['area'] is String) return u['area'];
    if (u['especialidad'] is String) return u['especialidad'];
    if (u['categoriaNombre'] is String) return u['categoriaNombre'];
    if (u['categoria'] is Map && u['categoria']['nombre'] != null) {
      return u['categoria']['nombre'].toString();
    }
    if (u['area'] is Map && u['area']['nombre'] != null) {
      return u['area']['nombre'].toString();
    }
    if (u['categoria'] is String) return u['categoria'];
    return '';
  }

  Future<void> _cargarSolicitudes() async {
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
        final list =
            data.map((item) => SolicitudRedAdminItem.fromJson(item)).toList();

        if (mounted) {
          setState(() {
            solicitudes = list.reversed.toList();
            filteredSolicitudes = solicitudes;
            loading = false;
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar solicitudes: $e')));
      }
    }
  }

  Future<void> _actualizarEstado(int id, String nuevoEstado) async {
    try {
      final url = Uri.parse('$baseUrl/$id/estado?estado=$nuevoEstado');

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
                content: Text('Estado actualizado correctamente'),
                backgroundColor: Colors.green),
          );
        }
        _cargarSolicitudes();
      } else {
        throw Exception(
            'Error al actualizar (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _asignarCuadrillaBackend(
      int solicitudId, int cuadrillaId) async {
    try {
      final url = Uri.parse(
          '$baseUrl/$solicitudId/asignar-cuadrilla?cuadrillaId=$cuadrillaId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuadrilla asignada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _cargarSolicitudes();
      } else {
        throw Exception('Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAsignarCuadrilla(SolicitudRedAdminItem item) async {
    int? tecnicoSeleccionado;
    List<dynamic> listaTecnicosFiltrados = [];
    bool cargandoTecnicos = true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            if (cargandoTecnicos) {
              http.get(
                Uri.parse('https://sitienergia-backend.onrender.com/api/usuarios'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.session.token}'
                },
              ).then((response) {
                if (response.statusCode == 200) {
                  final List<dynamic> data =
                      jsonDecode(utf8.decode(response.bodyBytes));
                  if (context.mounted) {
                    setStateModal(() {
                      final areaTargetNorm = _normalizarTexto(item.area);

                      // 1. Filtrar solo usuarios con rol TECNICO
                      final soloTecnicos = data
                          .where((u) =>
                              (u['rol'] == 'TECNICO' || u['role'] == 'TECNICO'))
                          .toList();

                      // 2. Coincidencia de área ignorando tildes y mayúsculas
                      listaTecnicosFiltrados = soloTecnicos.where((u) {
                        final areaTecnicoNorm =
                            _normalizarTexto(_obtenerAreaTecnico(u));
                        if (areaTecnicoNorm.isEmpty) return true;
                        return areaTecnicoNorm.contains(areaTargetNorm) ||
                            areaTargetNorm.contains(areaTecnicoNorm);
                      }).toList();

                      // 3. Fallback: Si no hay coincidencia exacta por área, mostrar todos los técnicos
                      if (listaTecnicosFiltrados.isEmpty &&
                          soloTecnicos.isNotEmpty) {
                        listaTecnicosFiltrados = soloTecnicos;
                      } else if (listaTecnicosFiltrados.isEmpty) {
                        listaTecnicosFiltrados = data;
                      }

                      cargandoTecnicos = false;
                    });
                  }
                } else {
                  if (context.mounted)
                    setStateModal(() => cargandoTecnicos = false);
                }
              }).catchError((_) {
                if (context.mounted)
                  setStateModal(() => cargandoTecnicos = false);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Asignar Cuadrilla (${item.area})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: cargandoTecnicos
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()))
                    : listaTecnicosFiltrados.isEmpty
                        ? const Text(
                            'No hay usuarios registrados en el sistema.')
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Seleccione Técnico',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: listaTecnicosFiltrados
                                .map<DropdownMenuItem<int>>((tec) {
                              final id = tec['id'] ?? 0;
                              final nombre = tec['nombre'] ??
                                  tec['username'] ??
                                  'Técnico #$id';
                              final areaTec = _obtenerAreaTecnico(tec);
                              final etiquetaArea =
                                  areaTec.isNotEmpty ? ' ($areaTec)' : '';
                              return DropdownMenuItem<int>(
                                value: id is int
                                    ? id
                                    : int.tryParse(id.toString()) ?? 0,
                                child: Text('$nombre$etiquetaArea',
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateModal(() => tecnicoSeleccionado = val);
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6070)),
                  onPressed: tecnicoSeleccionado == null
                      ? null
                      : () {
                          final idTecnico = tecnicoSeleccionado!;
                          Navigator.pop(context);
                          _asignarCuadrillaBackend(item.id, idTecnico);
                        },
                  child: const Text('Asignar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _filterSolicitudes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSolicitudes = solicitudes
          .where((s) =>
              s.numeroCedula.toLowerCase().contains(query) ||
              s.numeroNic.toLowerCase().contains(query) ||
              s.tipoIntervencion.toLowerCase().contains(query) ||
              s.direccion.toLowerCase().contains(query) ||
              s.estado.toLowerCase().contains(query))
          .toList();
    });
  }

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'RADICADO':
      case 'RADICADA':
        return Colors.blue[700]!;
      case 'EN_REVISION':
        return Colors.orange[800]!;
      case 'APROBADO':
        return Colors.teal[700]!;
      case 'EN_EJECUCION':
        return Colors.purple[700]!;
      case 'COMPLETADO':
        return Colors.green[700]!;
      case 'RECHAZADO':
        return Colors.red[700]!;
      default:
        return Colors.blueGrey;
    }
  }

  void _mostrarOpcionesEstado(SolicitudRedAdminItem item) {
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
                child: Text('Gestionar Estado de la Solicitud',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.group_add_rounded, color: Colors.indigo),
                title: const Text('Asignar a Cuadrilla Correspondiente',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.indigo)),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoAsignarCuadrilla(item);
                },
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.fact_check_rounded, color: Colors.orange),
                title: const Text('En Revisión'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'EN_REVISION');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.thumb_up_alt_rounded, color: Colors.teal),
                title: const Text('Aprobado'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'APROBADO');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.engineering_rounded, color: Colors.purple),
                title: const Text('En Ejecución'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'EN_EJECUCION');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                title: const Text('Completado'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'COMPLETADO');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                title: const Text('Rechazado'),
                onTap: () {
                  Navigator.pop(context);
                  _actualizarEstado(item.id, 'RECHAZADO');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Solicitudes de Red',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E6070),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E6070),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por Cédula, NIC o dirección...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredSolicitudes.isEmpty
                      ? const Center(
                          child: Text('No hay solicitudes de red registradas.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSolicitudes.length,
                          itemBuilder: (context, index) {
                            final item = filteredSolicitudes[index];
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            'SOL-${item.id.toString().padLeft(4, '0')}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1E6070))),
                                        InkWell(
                                          onTap: () =>
                                              _mostrarOpcionesEstado(item),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  colorEstado.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: colorEstado),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(item.estado,
                                                    style: TextStyle(
                                                        color: colorEstado,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(width: 4),
                                                Icon(Icons.edit,
                                                    size: 14,
                                                    color: colorEstado),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        item.tipoIntervencion
                                            .replaceAll('_', ' '),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87)),
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
                                            color: Color(0xFF1E6070)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Cédula: ${item.numeroCedula} | NIC: ${item.numeroNic}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w500)),
                                    Text('Dirección: ${item.direccion}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87)),
                                    Text('Motivo: ${item.motivo}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700])),
                                    const SizedBox(height: 8),
                                    if (item
                                        .detallesEspecificos.isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                                'Atributos de Infraestructura:',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            ...item.detallesEspecificos.entries
                                                .map((entry) => Text(
                                                    '• ${entry.key}: ${entry.value}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.black87))),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text('Fecha: ${item.fechaCreacion}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
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
