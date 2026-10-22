import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/session.dart';
import '../../data/datasources/incidencia_remote_datasource.dart';
import '../../data/models/incidencia_model.dart';

class ReportarFallaPage extends StatefulWidget {
  final Session session;

  const ReportarFallaPage({super.key, required this.session});

  @override
  State<ReportarFallaPage> createState() => _ReportarFallaPageState();
}

class _ReportarFallaPageState extends State<ReportarFallaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController(); // Aún útil como referencia escrita

  int? _categoriaIdSeleccionada;
  bool _isLoading = false;

  // --- VARIABLES PARA EL MAPA ---
  GoogleMapController? mapController;
  LatLng? _coordenadasSeleccionadas;
  Set<Marker> _markers = {};
  bool _buscandoUbicacion = true;
  
  // Coordenadas por defecto (Bogotá) en caso de que falle el GPS
  static const LatLng _centroPorDefecto = LatLng(4.6097, -74.0817);

  final List<Map<String, dynamic>> _categoriasFake = [
    {"id": 1, "nombre": "Falla en red de baja tensión"},
    {"id": 2, "nombre": "Transformador quemado"},
    {"id": 3, "nombre": "Poste caído"},
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  // --- LÓGICA DEL GPS Y MAPA ---
  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _finalizarBusquedaConUbicacionFija(_centroPorDefecto);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _finalizarBusquedaConUbicacionFija(_centroPorDefecto);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _finalizarBusquedaConUbicacionFija(_centroPorDefecto);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng ubicacionActual = LatLng(position.latitude, position.longitude);
      _finalizarBusquedaConUbicacionFija(ubicacionActual);
    } catch (e) {
      _finalizarBusquedaConUbicacionFija(_centroPorDefecto);
    }
  }

  void _finalizarBusquedaConUbicacionFija(LatLng ubicacion) {
    if (mounted) {
      setState(() {
        _coordenadasSeleccionadas = ubicacion;
        _actualizarMarcador(ubicacion);
        _buscandoUbicacion = false;
      });

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(ubicacion, 16));
      }
    }
  }

  void _actualizarMarcador(LatLng position) {
    setState(() {
      _coordenadasSeleccionadas = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('falla_ubicacion'),
          position: position,
          infoWindow: const InfoWindow(title: 'Lugar del daño'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  // --- EL PUENTE A SPRING BOOT ---
  Future<void> _enviarReporte() async {
    if (_formKey.currentState!.validate()) {
      if (_categoriaIdSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una categoría')),
        );
        return;
      }

      if (_coordenadasSeleccionadas == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún no se ha cargado el mapa de ubicación')),
        );
        return;
      }

      setState(() { _isLoading = true; });

      try {
        final datasource = IncidenciaRemoteDatasource();

        final request = IncidenciaRequest(
          categoriaId: _categoriaIdSeleccionada!,
          nic: _nicController.text,
          descripcion: _descripcionController.text,
          ubicacion: _ubicacionController.text, 
          // AQUÍ MANDAMOS LAS COORDENADAS DEL MAPA:
          latitud: _coordenadasSeleccionadas!.latitude,
          longitud: _coordenadasSeleccionadas!.longitude,
        );

        final token = widget.session.token;
        final exito = await datasource.crearIncidencia(request, token);

        if (exito) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Incidencia reportada con GPS en Spring Boot!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: El backend rechazó la petición.'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Falla (Incidencia)'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detalles del Daño', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Tipo de falla', border: OutlineInputBorder()),
                        value: _categoriaIdSeleccionada,
                        items: _categoriasFake.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'] as int,
                            child: Text(cat['nombre'] as String),
                          );
                        }).toList(),
                        onChanged: (val) { setState(() { _categoriaIdSeleccionada = val; }); },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número de NIC (Recibo de luz)',
                          hintText: 'Ej. 1234567',
                          prefixIcon: Icon(Icons.receipt_long),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del daño',
                          hintText: 'Ej. Salen chispas y huele a quemado',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Escribe una descripción' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _ubicacionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección o referencia escrita',
                          hintText: 'Ej. Cra 4 Calle 5-56',
                          prefixIcon: Icon(Icons.map),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Obligatorio' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- CONTENEDOR DEL MAPA ---
              const Text('Señala en el mapa el lugar exacto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buscandoUbicacion
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _coordenadasSeleccionadas ?? _centroPorDefecto,
                            zoom: 16,
                          ),
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            mapController = controller;
                          },
                          onTap: (LatLng position) {
                            // Al tocar el mapa, se mueve el marcador rojo
                            _actualizarMarcador(position);
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // --- BOTÓN DE ENVIAR ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red[700],
                      ),
                      onPressed: _enviarReporte,
                      child: const Text('ENVIAR REPORTE', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}