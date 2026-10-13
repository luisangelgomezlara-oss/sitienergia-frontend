import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> register() async {
    if (name.text.trim().isEmpty || !email.text.contains('@') || password.text.length < 6) {
      setState(() => error = 'Completa los campos. La contraseña debe tener mínimo 6 caracteres.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final authRepository = AuthRepositoryImpl(remoteDatasource: AuthRemoteDatasource());
      await authRepository.register(name.text, email.text, phone.text, password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada. Ya puedes iniciar sesión.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 20),
          FilledButton(onPressed: loading ? null : register, child: Text(loading ? 'Creando...' : 'Registrarme')),
        ],
        ),
      );
}