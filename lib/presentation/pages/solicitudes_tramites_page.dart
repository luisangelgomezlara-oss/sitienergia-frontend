import 'package:flutter/material.dart';

class SolicitudesTramitesPage extends StatelessWidget {
  const SolicitudesTramitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Solicitudes de Red', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Selecciona el tipo de intervención en la infraestructura eléctrica:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          _buildTramiteCard(
            context,
            'Reemplazo de Poste',
            'Solicita el cambio de un poste en mal estado, agrietado o con riesgo de colapso.',
            Icons.foundation,
            Colors.brown,
          ),
          _buildTramiteCard(
            context,
            'Poda Preventiva',
            'Solicita la poda de árboles cuyas ramas estén tocando o en riesgo de reventar las líneas.',
            Icons.park,
            Colors.green,
          ),
          _buildTramiteCard(
            context,
            'Gestión de Transformadores',
            'Solicita un cambio por deficiencia energética, sobrecarga o instalación por primera vez.',
            Icons.electrical_services,
            Colors.orange,
          ),
          _buildTramiteCard(
            context,
            'Cambio de Cableado',
            'Solicita el reemplazo de líneas eléctricas deterioradas, sulfatadas o caídas.',
            Icons.cable,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTramiteCard(BuildContext context, String titulo, String descripcion, IconData icono, MaterialColor color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Formulario de $titulo en desarrollo')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color[50],
                child: Icon(icono, color: color[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(descripcion, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}