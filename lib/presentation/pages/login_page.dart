import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
// ignore: unused_import
import '../../domain/entities/session.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- Controladores Cliente ---
  final _nicController = TextEditingController();
  final _cedulaController = TextEditingController();

  // --- Controladores Empleado ---
  final _emailController = TextEditingController(text: 'admin@sitienergia.com');
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  // Lógica de Login para el Cliente
  Future<void> _loginCliente() async {
    if (_nicController.text.isEmpty || _cedulaController.text.isEmpty) {
      if (mounted) setState(() => _error = 'Por favor ingresa tu NIC y Cédula');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final datasource = AuthRemoteDatasource();
      final sessionModel = await datasource.loginCliente(
        _nicController.text.trim(), 
        _cedulaController.text.trim()
      );
      
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(session: sessionModel)));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  // Lógica de Login para el Empleado
  Future<void> _loginEmpleado() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) setState(() => _error = 'Por favor ingresa tu correo y contraseña');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final authRepository = AuthRepositoryImpl(remoteDatasource: AuthRemoteDatasource());
      final session = await authRepository.login(_emailController.text.trim(), _passwordController.text.trim());
      
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(session: session)));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Icon(Icons.electrical_services, size: 56, color: Color(0xff176b87)),
                      const SizedBox(height: 18),
                      const Text('SitiEnergia', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff176b87))),
                      const Text('Sistema Integrado de Tareas e Incidencias Energéticas', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 30),

                      // --- Pestañas (Tabs) ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: const Color(0xff176b87),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black54,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Soy Cliente'),
                            Tab(text: 'Soy Empleado'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),

                      
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            
                            // --- Formulario: SOY CLIENTE ---
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextField(
                                  controller: _nicController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Número de NIC (Contrato)', prefixIcon: Icon(Icons.receipt_long), border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _cedulaController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Cédula de Ciudadanía', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _loading ? null : _loginCliente,
                                    icon: const Icon(Icons.login),
                                    label: Text(_loading ? 'Ingresando...' : 'Acceso Rápido'),
                                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: const Color(0xff176b87)),
                                  ),
                                ),
                              ],
                            ),

                            // --- Formulario: SOY EMPLEADO ---
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(labelText: 'Correo electrónico corporativo', prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _loading ? null : _loginEmpleado,
                                    icon: const Icon(Icons.admin_panel_settings),
                                    label: Text(_loading ? 'Verificando...' : 'Acceso Seguro'),
                                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // --- Botón de Registro ---
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('¿No tienes cuenta? Regístrate aquí'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}