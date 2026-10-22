import 'package:flutter/material.dart';

class PuntosAtencionPage extends StatelessWidget {
  const PuntosAtencionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Servicios Comunitarios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Líneas de Atención', Icons.phone_in_talk),
          _buildInfoCard(
            'Emergencias Eléctricas', 
            'Línea nacional gratuita: 115\nWhatsApp Reportes: 300 000 0000', 
            Icons.electrical_services, 
            Colors.orange
          ),
          _buildInfoCard(
            'Alumbrado Público', 
            'Línea directa: 116\nAtención 24/7 para luminarias apagadas', 
            Icons.lightbulb_outline, 
            Colors.blue
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Puntos de Atención', Icons.location_on),
          _buildInfoCard(
            'Oficina Principal - Zona Norte', 
            'Av. Central #45-67, Edificio Principal\nLunes a Viernes: 8:00 AM - 4:00 PM', 
            Icons.storefront, 
            Colors.green
          ),
          _buildInfoCard(
            'Sucursal de Atención Centro', 
            'Calle 10 #11-22, Plaza Central\nLunes a Viernes: 7:30 AM - 3:30 PM', 
            Icons.storefront, 
            Colors.green
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Mantenimientos Programados', Icons.build_circle),
          _buildInfoCard(
            'Corte Programado - Sector Centro', 
            'Fecha: 25 de Octubre, 8:00 AM - 2:00 PM\nMotivo: Poda de árboles cerca a redes de media tensión y cambio de cableado.', 
            Icons.warning_amber_rounded, 
            Colors.red
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff176b87)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff176b87)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon, MaterialColor color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color[50],
          child: Icon(icon, color: color[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle, style: const TextStyle(height: 1.4, color: Colors.black87)),
        ),
      ),
    );
  }
}