import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Función global que Julián y tú llamarán al tocar cualquier tarjeta de incidencia
void mostrarDetalleIncidencia({
  required BuildContext context,
  required String codigo,
  required String categoria,
  required String descripcion,
  required String estado,
  String? fecha,
  String? ubicacion,
  double? latitud,
  double? longitud,
  String? imagen,
  String? cuadrilla,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DetalleIncidenciaModal(
      codigo: codigo,
      categoria: categoria,
      descripcion: descripcion,
      estado: estado,
      fecha: fecha,
      ubicacion: ubicacion,
      latitud: latitud,
      longitud: longitud,
      imagen: imagen,
      cuadrilla: cuadrilla,
    ),
  );
}

/// Función auxiliar para abrir Google Maps directamente desde cualquier botón
Future<void> abrirEnGoogleMaps(
  BuildContext context, {
  double? lat,
  double? lng,
  String? ubicacionTexto,
}) async {
  final coords = _resolverCoordenadas(lat, lng, ubicacionTexto);

  if (coords == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este reporte no tiene coordenadas GPS válidas.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la aplicación de Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

LatLng? _resolverCoordenadas(double? lat, double? lng, String? ubicacionTexto) {
  if (lat != null && lng != null && (lat != 0 || lng != 0)) {
    return LatLng(lat, lng);
  }
  if (ubicacionTexto != null && ubicacionTexto.contains(',')) {
    final partes = ubicacionTexto.split(',');
    if (partes.length >= 2) {
      final parsedLat = double.tryParse(partes[0].trim());
      final parsedLng = double.tryParse(partes[1].trim());
      if (parsedLat != null && parsedLng != null) {
        return LatLng(parsedLat, parsedLng);
      }
    }
  }
  return null;
}

class DetalleIncidenciaModal extends StatelessWidget {
  final String codigo;
  final String categoria;
  final String descripcion;
  final String estado;
  final String? fecha;
  final String? ubicacion;
  final double? latitud;
  final double? longitud;
  final String? imagen;
  final String? cuadrilla;

  const DetalleIncidenciaModal({
    super.key,
    required this.codigo,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    this.fecha,
    this.ubicacion,
    this.latitud,
    this.longitud,
    this.imagen,
    this.cuadrilla,
  });

  String _limpiarBase64(String base64String) {
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }
    return base64String.replaceAll(RegExp(r'\s+'), '');
  }

  Uint8List? _decodificarBase64(String raw) {
    try {
      return base64Decode(_limpiarBase64(raw));
    } catch (_) {
      return null;
    }
  }

  Color _getColorEstado(String est) {
    switch (est.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.red[700]!;
      case 'ASIGNADA':
        return Colors.blueGrey[700]!;
      case 'EN_PROCESO':
        return Colors.orange[800]!;
      case 'RESUELTO':
        return Colors.green[700]!;
      default:
        return const Color(0xff176b87);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coords = _resolverCoordenadas(latitud, longitud, ubicacion);
    final colorEstado = _getColorEstado(estado);
    final imagenBytes =
        imagen != null && imagen!.isNotEmpty && !imagen!.startsWith('http')
            ? _decodificarBase64(imagen!)
            : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Indicador superior de arrastre
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    // Cabecera: Código y Estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          codigo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff176b87),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorEstado),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              color: colorEstado,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Categoría y Descripción
                    Text(
                      categoria,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (fecha != null && fecha!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Fecha: $fecha',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                    if (cuadrilla != null && cuadrilla!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.groups,
                              size: 16, color: Color(0xff176b87)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cuadrilla: $cuadrilla',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff176b87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 28),

                    // Sección de Ubicación en el Mapa
                    const Text(
                      'Ubicación de la Incidencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff176b87),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (coords != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: coords,
                              zoom: 16.5,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(codigo),
                                position: coords,
                                infoWindow: InfoWindow(
                                  title: codigo,
                                  snippet: categoria,
                                ),
                              ),
                            },
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coordenadas: ${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => abrirEnGoogleMaps(
                            context,
                            lat: coords.latitude,
                            lng: coords.longitude,
                          ),
                          icon:
                              const Icon(Icons.directions, color: Colors.white),
                          label: const Text(
                            'Abrir en Google Maps / Cómo llegar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff176b87),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ubicación textual: ${ubicacion ?? "No registrada"}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),

                    // Sección de Evidencia Fotográfica
                    if (imagen != null && imagen!.isNotEmpty) ...[
                      const Divider(height: 28),
                      const Text(
                        'Evidencia Adjunta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff176b87),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imagen!.startsWith('http')
                            ? Image.network(
                                imagen!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Text('No se pudo cargar la imagen'),
                              )
                            : imagenBytes == null
                                ? const Text('No se pudo decodificar la imagen')
                                : Image.memory(
                                    imagenBytes,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Text(
                                        'No se pudo decodificar la imagen'),
                                  ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
