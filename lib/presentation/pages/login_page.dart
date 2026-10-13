import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart'; 
// ignore: unused_import
import '../../domain/entities/session.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'admin@sitienergia.com');
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      final authRepository = AuthRepositoryImpl(remoteDatasource: AuthRemoteDatasource());
      final session = await authRepository.login(email.text, password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(session: session)));
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.electrical_services, size: 56, color: Color(0xff176b87)),
                const SizedBox(height: 18),
                const Text('SitiEnergia', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('Sistema Integrado de Tareas e Incidencias Energéticas', textAlign: TextAlign.center),
                const SizedBox(height: 36),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 22),
                FilledButton.icon(onPressed: loading ? null : login, icon: const Icon(Icons.login), label: Text(loading ? 'Ingresando...' : 'Iniciar sesión'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(16))),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('¿No tienes cuenta? Regístrate')),
              ]),
            ),
          ),
        ),
      );
}