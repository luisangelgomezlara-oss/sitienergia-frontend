import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/session.dart';
import 'login_page.dart';
import 'categories_page.dart';
import 'users_page.dart';


class HomePage extends StatefulWidget {
  final Session session;
  const HomePage({super.key, required this.session});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.session.rol == 'ADMIN';
    final pages = <Widget>[Overview(session: widget.session)];
    if (admin) {
      pages.add(CategoriesPage(session: widget.session));
      pages.add(UsersPage(session: widget.session));
    }
    return Scaffold(
      appBar: AppBar(title: Text(tab == 0 ? 'Resumen' : tab == 1 ? 'Categorías' : 'Usuarios'), actions: [IconButton(onPressed: logout, tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (value) => setState(() => tab = value), destinations: [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Resumen'),
        if (admin) const NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorías'),
        if (admin) const NavigationDestination(icon: Icon(Icons.people_outline), label: 'Usuarios'),
      ]),
    );
  }
}

class Overview extends StatelessWidget {
  final Session session;
  const Overview({super.key, required this.session});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('Hola, ${session.nombre}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Sistema Integrado de Tareas e Incidencias Energéticas'),
        const SizedBox(height: 28),
        Card(child: ListTile(leading: const Icon(Icons.security), title: const Text('Sesión segura'), subtitle: Text('Rol actual: ${session.rol}'))),
        const Card(child: ListTile(leading: Icon(Icons.rule), title: Text('SitiEnergia'), subtitle: Text('Gestión de incidencias del sector eléctrico'))),
      ]);
}
