import 'package:flutter/material.dart';
import 'formulario_solicitud_page.dart';

class SolicitudesRedPage extends StatelessWidget {
  final String token;
  final String cedulaCliente;
  final String nicCliente;

  const SolicitudesRedPage({
    super.key,
    required this.token,
    required this.cedulaCliente,
    required this.nicCliente,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6070),
        title: const Text('Solicitudes de Red',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de intervención en la infraestructura eléctrica:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildIntervencionCard(
                    context,
                    titulo: 'Reemplazo de Poste',
                    descripcion:
                        'Solicita el cambio de un poste en mal estado, agrietado o con riesgo de colapso.',
                    icono: Icons.home_work_outlined,
                    colorIcono: Colors.brown,
                    tipoIntervencion: 'REEMPLAZO_POSTE',
                  ),
                  const SizedBox(height: 12),
                  _buildIntervencionCard(
                    context,
                    titulo: 'Poda Preventiva',
                    descripcion:
                        'Solicita la poda de árboles cuyas ramas estén tocando o en riesgo de reventar las líneas.',
                    icono: Icons.park,
                    colorIcono: Colors.green,
                    tipoIntervencion: 'PODA_PREVENTIVA',
                  ),
                  const SizedBox(height: 12),
                  _buildIntervencionCard(
                    context,
                    titulo: 'Gestión de Transformadores',
                    descripcion:
                        'Solicita un cambio por deficiencia energética, sobrecarga o instalación por primera vez.',
                    icono: Icons.electrical_services,
                    colorIcono: Colors.orange,
                    tipoIntervencion: 'GESTION_TRANSFORMADORES',
                  ),
                  const SizedBox(height: 12),
                  _buildIntervencionCard(
                    context,
                    titulo: 'Cambio de Cableado',
                    descripcion:
                        'Solicita el reemplazo de líneas eléctricas deterioradas, sulfatadas o caídas.',
                    icono: Icons.cable,
                    colorIcono: Colors.blueAccent,
                    tipoIntervencion: 'CAMBIO_CABLEADO',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervencionCard(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color colorIcono,
    required String tipoIntervencion,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioSolicitudPage(
                tipoIntervencion: tipoIntervencion,
                tituloIntervencion: titulo,
                token: token,
                cedulaCliente: cedulaCliente,
                nicCliente: nicCliente,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorIcono.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorIcono, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(descripcion,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
