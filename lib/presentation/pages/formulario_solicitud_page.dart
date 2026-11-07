import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/datasources/solicitud_red_datasource.dart';

class FormularioSolicitudPage extends StatefulWidget {
  final String tipoIntervencion;
  final String tituloIntervencion;
  final String token;
  final String cedulaCliente;
  final String nicCliente;

  const FormularioSolicitudPage({
    super.key,
    required this.tipoIntervencion,
    required this.tituloIntervencion,
    required this.token,
    required this.cedulaCliente,
    required this.nicCliente,
  });

  @override
  State<FormularioSolicitudPage> createState() =>
      _FormularioSolicitudPageState();
}

class _FormularioSolicitudPageState extends State<FormularioSolicitudPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  final String _departamento = 'Córdoba';
  String _municipio = 'Cereté';
  final List<String> _municipiosPermitidos = [
    'Cereté',
    'San Carlos',
    'Ciénaga de Oro',
    'San Pelayo'
  ];

  String _materialPoste = 'Concreto';
  String _nivelRiesgoPoste = 'Medio';
  final TextEditingController _tipoVegetacionController =
      TextEditingController();
  String _motivoTransformador = 'Deficiencia energética';
  String _estadoCableado = 'Deteriorado / Sulfatado';
  bool _isEnviando = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _nicController.dispose();
    _direccionController.dispose();
    _motivoController.dispose();
    _tipoVegetacionController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEnviando = true);

    Map<String, dynamic> detallesEspecificosMapa = {};
    String areaSolicitud = 'Redes Eléctricas';

    switch (widget.tipoIntervencion) {
      case 'REEMPLAZO_POSTE':
        areaSolicitud = 'Redes Eléctricas';
        detallesEspecificosMapa = {
          'material': _materialPoste,
          'nivelRiesgo': _nivelRiesgoPoste,
        };
        break;
      case 'PODA_PREVENTIVA':
        areaSolicitud = 'Redes Eléctricas';
        detallesEspecificosMapa = {
          'tipoVegetacion': _tipoVegetacionController.text.trim(),
          'cercaniaLineas': 'Ramas en contacto directo',
        };
        break;
      case 'GESTION_TRANSFORMADORES':
        areaSolicitud = 'Obras Civiles';
        detallesEspecificosMapa = {
          'motivoSolicitud': _motivoTransformador,
        };
        break;
      case 'CAMBIO_CABLEADO':
        areaSolicitud = 'Redes Eléctricas';
        detallesEspecificosMapa = {
          'estadoCableado': _estadoCableado,
        };
        break;
    }

    final direccionCompleta =
        '${_direccionController.text.trim()}, $_municipio, $_departamento';

    final datosSolicitud = {
      'numeroCedula': _cedulaController.text.trim(),
      'numeroNic': _nicController.text.trim(),
      'tipoIntervencion': widget.tipoIntervencion,
      'area': areaSolicitud,
      'direccion': direccionCompleta,
      'motivo': _motivoController.text.trim(),
      // Codificamos el mapa a String para coincidir con private String detallesEspecificos en Java
      'detallesEspecificos': jsonEncode(detallesEspecificosMapa),
    };

    final exito = await SolicitudRedDataSource().radicarSolicitud(
      datosSolicitud,
      widget.token,
    );

    if (mounted) {
      setState(() => _isEnviando = false);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Solicitud de red radicada con éxito'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Error al radicar la solicitud. Verifica la consola.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6070),
        title: Text(widget.tituloIntervencion,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos del Contrato',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E6070))),
              const SizedBox(height: 12),
              const Text('Número de Cédula',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 1000000000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'La cédula es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('NIC del Contrato',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 4409315',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'El NIC es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Ubicación del Daño',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E6070))),
              const SizedBox(height: 12),
              const Text('Departamento',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _departamento,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Córdoba', child: Text('Córdoba'))
                ],
                onChanged: null,
              ),
              const SizedBox(height: 16),
              const Text('Municipio',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _municipio,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: _municipiosPermitidos.map((mun) {
                  return DropdownMenuItem(
                      value: mun,
                      child: Text(mun, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) => setState(() => _municipio = val!),
              ),
              const SizedBox(height: 16),
              const Text('Dirección exacta o barrio',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Calle 15 # 4-22 Barrio El Centro',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'La dirección es obligatoria'
                    : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Motivo o Descripción General',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1E6070))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Explique detalladamente el problema observado en la red...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'El motivo es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Detalles Específicos del Requerimiento',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E6070))),
              const SizedBox(height: 12),
              if (widget.tipoIntervencion == 'REEMPLAZO_POSTE') ...[
                const Text('Material del Poste',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _materialPoste,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(
                        value: 'Concreto',
                        child:
                            Text('Concreto', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Madera',
                        child: Text('Madera', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Metal',
                        child: Text('Metal', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => _materialPoste = val!),
                ),
                const SizedBox(height: 16),
                const Text('Nivel de Riesgo de Colapso',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _nivelRiesgoPoste,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(
                        value: 'Bajo',
                        child: Text('Bajo (Grietas menores)',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Medio',
                        child: Text('Medio (Inclinación moderada)',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Alto',
                        child: Text('Alto (Riesgo inminente de caída)',
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => _nivelRiesgoPoste = val!),
                ),
              ] else if (widget.tipoIntervencion == 'PODA_PREVENTIVA') ...[
                const Text('Tipo de Árbol / Vegetación',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _tipoVegetacionController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Mango, Matarratón, Palma',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Indique el tipo de vegetación'
                      : null,
                ),
              ] else if (widget.tipoIntervencion ==
                  'GESTION_TRANSFORMADORES') ...[
                const Text('Motivo de la Solicitud del Transformador',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _motivoTransformador,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(
                        value: 'Deficiencia energética',
                        child: Text('Deficiencia energética / Bajo voltaje',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Sobrecarga constante',
                        child: Text('Sobrecarga constante del equipo',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Instalación por primera vez',
                        child: Text(
                            'Instalación por primera vez (Nuevo servicio)',
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) =>
                      setState(() => _motivoTransformador = val!),
                ),
              ] else if (widget.tipoIntervencion == 'CAMBIO_CABLEADO') ...[
                const Text('Estado de la Línea / Cableado',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _estadoCableado,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(
                        value: 'Deteriorado / Sulfatado',
                        child: Text('Deteriorado / Sulfatado',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Línea suelta o caída',
                        child: Text('Línea suelta o caída',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'Rozamiento con estructuras',
                        child: Text('Rozamiento constante con estructuras',
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => _estadoCableado = val!),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6070),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isEnviando ? null : _enviarSolicitud,
                  child: _isEnviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Radicar Solicitud',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
