import 'package:flutter/material.dart';
import '../../domain/entities/session.dart';
import 'login_page.dart';
import 'reportar_falla_page.dart';
// Importa tus pantallas de administrador
import 'users_page.dart';
import 'categories_page.dart';
import 'mis_reportes_page.dart';
import 'gestion_incidencias_page.dart';
import 'puntos_atencion_page.dart';
import 'solicitudes_tramites_page.dart';

class HomePage extends StatelessWidget {
  final Session session;

  const HomePage({super.key, required this.session});

  void _cerrarSesion(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('SitiEnergia',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _cerrarSesion(context),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Saludo al Usuario ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xff176b87).withOpacity(0.1),
                      child: const Icon(Icons.person,
                          size: 35, color: Color(0xff176b87)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hola,',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54)),
                          Text(
                            session.nombre,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff176b87)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: session.rol == 'ADMIN'
                                  ? Colors.purple[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Perfil: ${session.rol}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: session.rol == 'ADMIN'
                                    ? Colors.purple[800]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('¿En qué te podemos ayudar hoy?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 16),

              // --- Cuadrícula de Servicios Dinámica según el Rol ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: _obtenerTarjetasSegunRol(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Lógica de Tarjetas por Rol ---
  List<Widget> _obtenerTarjetasSegunRol(BuildContext context) {
    if (session.rol == 'ADMIN') {
      // Menú exclusivo para Administradores
      return [
        _construirTarjeta(
          context: context,
          titulo: 'Gestionar\nUsuarios',
          icono: Icons.people_alt_outlined,
          colorFondo: Colors.purple[50]!,
          colorIcono: Colors.purple[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UsersPage(session: session)),
            );
          },
        ),
        _construirTarjeta(
          context: context,
          titulo: 'Modificar\nCategorías',
          icono: Icons.category_outlined,
          colorFondo: Colors.teal[50]!,
          colorIcono: Colors.teal[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CategoriesPage(session: session)),
            );
          },
        ),
        _construirTarjeta(
          context: context,
          titulo: 'Todas las\nIncidencias',
          icono: Icons.assignment_outlined,
          colorFondo: Colors.blue[50]!,
          colorIcono: Colors.blue[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GestionIncidenciasPage(session: session)),
            );
          },
        ),
      ];
    } else {
      // Menú para Clientes
      return [
        _construirTarjeta(
          context: context,
          titulo: 'Reportar\nFalla',
          icono: Icons.warning_amber_rounded,
          colorFondo: Colors.red[50]!,
          colorIcono: Colors.red[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReportarFallaPage(session: session)),
            );
          },
        ),
        _construirTarjeta(
          context: context,
          titulo: 'Mis\nReportes',
          icono: Icons.assignment_turned_in_outlined,
          colorFondo: Colors.blue[50]!,
          colorIcono: Colors.blue[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MisReportesPage(session: session)),
            );
          },
        ),
        _construirTarjeta(
          context: context,
          titulo: 'Solicitudes\ny Trámites',
          icono: Icons.document_scanner_outlined,
          colorFondo: Colors.green[50]!,
          colorIcono: Colors.green[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SolicitudesTramitesPage()),
            );
          },
        ),
        _construirTarjeta(
          context: context,
          titulo: 'Puntos de\nAtención',
          icono: Icons.location_on_outlined,
          colorFondo: Colors.orange[50]!,
          colorIcono: Colors.orange[700]!,
          alPresionar: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PuntosAtencionPage()),
            );
          },
        ),
      ];
    }
  }

  // --- Método para crear las tarjetas rápidamente ---
  Widget _construirTarjeta({
    required BuildContext context,
    required String titulo,
    required IconData icono,
    required Color colorFondo,
    required Color colorIcono,
    required VoidCallback alPresionar,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alPresionar,
        child: Container(
          decoration: BoxDecoration(color: colorFondo),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(icono, size: 40, color: colorIcono),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
