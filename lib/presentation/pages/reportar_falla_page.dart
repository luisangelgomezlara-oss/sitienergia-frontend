import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class ReportarFallaPage extends StatefulWidget {
  final Session session;
  const ReportarFallaPage({super.key, required this.session});

  @override
  State<ReportarFallaPage> createState() => _ReportarFallaPageState();
}

class _ReportarFallaPageState extends State<ReportarFallaPage> {
  LatLng _centerLatLng = const LatLng(8.8829, -75.7276);
  GoogleMapController? _mapController;
  bool _cargandoUbicacion = true;
  bool _enviando = false;
  
  List<dynamic> _categoriasDB = [];
  int? _categoriaIdSeleccionada;
  String? _tipoDanoSeleccionadoNombre; 
  String? _detalleDanoSeleccionado;
  
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  File? _imagenEvidencia;
  
  final Map<String, List<String>> _detallesPorCategoria = {
    'Falla en red de baja tensión': ['Cables reventados', 'Fluctuación de voltaje', 'Sin energía en un sector'],
    'Transformador averiado': ['Humo/Fuego en poste', 'Líquido derramado', 'Sonido fuerte/Explosión'],
    'Cortocircuito en líneas de distribución': ['Chispas fuertes', 'Cables haciendo contacto'],
    'Poste averiado / caído': ['Poste inclinado', 'Poste en el suelo', 'Poste chocado por vehículo'],
    'Daño en infraestructura de soportes': ['Cruceta rota', 'Tensores sueltos', 'Estructura colgando'],
    'Riesgo por árboles sobre redes': ['Ramas tocando cables', 'Árbol caído sobre red'],
    'Revisión de medidor': ['Medidor apagado', 'Pantalla rota', 'Medidor quemado'],
    'Anomalías en facturación / acometida': ['Acometida sulfatada', 'Cable de entrada roto'],
    'Fraude o manipulación de medida': ['Conexión directa', 'Sello de seguridad roto', 'Cables puenteados']
  };

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _cargarCategoriasDesdeBD();
  }

  Future<void> _cargarCategoriasDesdeBD() async {
    try {
      final response = await http.get(
        Uri.parse('https://sitienergia-backend.onrender.com/api/categorias'),
        headers: {'Authorization': 'Bearer ${widget.session.token}'}
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _categoriasDB = data.where((c) => c['activa'] == true).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _cargandoUbicacion = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _cargandoUbicacion = false);
        return;
      }
    }
    
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _centerLatLng = LatLng(position.latitude, position.longitude);
        _cargandoUbicacion = false;
      });
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _centerLatLng, zoom: 17)));
    }
  }

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) {
      setState(() => _imagenEvidencia = File(photo.path));
    }
  }

  Future<void> _enviarReporte() async {
    if (_categoriaIdSeleccionada == null || _detalleDanoSeleccionado == null || _nicController.text.isEmpty || _referenciaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan campos requeridos'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _enviando = true);

    try {
      String? imagenBase64;
      if (_imagenEvidencia != null) {
        final bytes = await _imagenEvidencia!.readAsBytes();
        imagenBase64 = base64Encode(bytes);
      }
      
      final response = await http.post(
        Uri.parse('https://sitienergia-backend.onrender.com/api/incidencias'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
        body: jsonEncode({
          "categoriaId": _categoriaIdSeleccionada,
          "nic": _nicController.text,
          "descripcion": "$_detalleDanoSeleccionado - ${_referenciaController.text}",
          "ubicacion": "${_centerLatLng.latitude}, ${_centerLatLng.longitude}",
          "latitud": _centerLatLng.latitude,
          "longitud": _centerLatLng.longitude,
          "imagen": imagenBase64
        }),
      );

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte registrado con éxito'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error del servidor: ${response.body}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _nicController.dispose();
    _referenciaController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Reportar Falla', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: _centerLatLng, zoom: 16),
                    onMapCreated: (controller) => _mapController = controller,
                    onCameraMove: (position) => _centerLatLng = position.target,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 35.0),
                    child: Icon(Icons.location_on, size: 45, color: Colors.red),
                  ),
                  if (_cargandoUbicacion)
                    const Positioned(top: 16, child: CircularProgressIndicator()),
                ],
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue[600],
              child: Text(
                'Coordenadas: ${_centerLatLng.latitude.toStringAsFixed(4)}, ${_centerLatLng.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de daño', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // DROPDOWN CON TEXTO AJUSTADO (Evita overflow con Expanded)
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Seleccione aquí'),
                    isExpanded: true, // Vital para que respete los límites
                    value: _categoriaIdSeleccionada,
                    items: _categoriasDB.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text(
                          cat['nombre'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _categoriaIdSeleccionada = newValue;
                        final catSeleccionada = _categoriasDB.firstWhere((c) => c['id'] == newValue);
                        _tipoDanoSeleccionadoNombre = catSeleccionada['nombre'];
                        _detalleDanoSeleccionado = null; 
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('NIC del Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: 'Ej: 4409315', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 16),

                  const Text('Detalle del daño', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Seleccione detalle'),
                    isExpanded: true,
                    value: _detalleDanoSeleccionado,
                    items: _tipoDanoSeleccionadoNombre == null 
                        ? [] 
                        : (_detallesPorCategoria[_tipoDanoSeleccionadoNombre] ?? ['Falla general reportada']).map((String detail) {
                            return DropdownMenuItem<String>(
                              value: detail,
                              child: Text(
                                detail,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _detalleDanoSeleccionado = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('Punto de referencia / Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _referenciaController,
                    maxLines: 3,
                    decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff176b87),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: _enviando ? null : _enviarReporte,
                          child: _enviando 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _tomarFoto,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _imagenEvidencia == null ? Colors.grey[300] : Colors.green[100], borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.camera_alt, color: _imagenEvidencia == null ? Colors.black54 : Colors.green[800], size: 28),
                        ),
                      ),
                    ],
                  ),
                  if (_imagenEvidencia != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('✓ Evidencia fotográfica capturada', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}