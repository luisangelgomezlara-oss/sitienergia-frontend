import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class MisSolicitudesRedPage extends StatefulWidget {
  final Session session;
  const MisSolicitudesRedPage({super.key, required this.session});

  @override
  State<MisSolicitudesRedPage> createState() => _MisSolicitudesRedPageState();
}

class _MisSolicitudesRedPageState extends State<MisSolicitudesRedPage> {
  final TextEditingController _cedulaConsultaController =
      TextEditingController();
  List<dynamic> solicitudes = [];
  bool loading = false;
  bool buscando = false;

  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/solicitudes-red/cedula';

  Future<void> _buscarSolicitudes(String cedula) async {
    if (cedula.trim().isEmpty) return;
    setState(() {
      loading = true;
      buscando = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${cedula.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            solicitudes = data.reversed.toList();
            loading = false;
          });
        }
      } else {
        throw Exception('No se encontraron registros');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          solicitudes = [];
          loading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Seguimiento de Solicitudes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E6070),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cedulaConsultaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu número de Cédula',
                          border: InputBorder.none,
                          icon: Icon(Icons.badge, color: Color(0xFF1E6070)),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6070)),
                      onPressed: () =>
                          _buscarSolicitudes(_cedulaConsultaController.text),
                      child: const Text('Consultar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : !buscando
                      ? const Center(
                          child: Text(
                              'Digita tu cédula para consultar el estado de tus solicitudes.'))
                      : solicitudes.isEmpty
                          ? const Center(
                              child: Text(
                                  'No se encontraron solicitudes asociadas a esa cédula.'))
                          : ListView.builder(
                              itemCount: solicitudes.length,
                              itemBuilder: (context, index) {
                                final item = solicitudes[index];
                                final estado = item['estado'] ?? 'RADICADA';
                                final colorEstado = _getColorEstado(estado);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      (item['tipoIntervencion'] ?? 'SOLICITUD')
                                          .toString()
                                          .replaceAll('_', ' '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E6070)),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('NIC: ${item['numeroNic']}'),
                                        Text('Dirección: ${item['direccion']}'),
                                        Text('Motivo: ${item['motivo']}'),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colorEstado.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: colorEstado),
                                      ),
                                      child: Text(
                                        estado,
                                        style: TextStyle(
                                            color: colorEstado,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
