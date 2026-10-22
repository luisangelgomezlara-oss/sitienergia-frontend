import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override 
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    // 1. Validamos que no haya campos vacíos
    if (_nameController.text.trim().isEmpty || 
        _nicController.text.trim().isEmpty || 
        _cedulaController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Por favor, completa todos los campos.');
      return;
    }
    
    setState(() { _loading = true; _error = null; });
    
    try {
      final datasource = AuthRemoteDatasource();
      // 2. Llamamos al nuevo método (que agregaremos en el paso 2)
      await datasource.registerCliente(
        _nameController.text.trim(),
        _nicController.text.trim(),
        _cedulaController.text.trim(),
        _phoneController.text.trim()
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada exitosamente. Ya puedes iniciar sesión.'), backgroundColor: Colors.green)
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                    const Icon(Icons.person_add_alt_1, size: 56, color: Color(0xff176b87)),
                    const SizedBox(height: 16),
                    const Text('Registro de Cliente', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff176b87))),
                    const Text('Ingresa tus datos para vincular tu servicio', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 30),

                    TextField(
                      controller: _nameController, 
                      decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _nicController, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Número de NIC (Contrato)', prefixIcon: Icon(Icons.receipt_long), border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _cedulaController, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Cédula de Ciudadanía', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _phoneController, 
                      keyboardType: TextInputType.phone, 
                      decoration: const InputDecoration(labelText: 'Teléfono Celular', prefixIcon: Icon(Icons.phone_android), border: OutlineInputBorder())
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
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _register,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff176b87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        child: Text(_loading ? 'Verificando datos...' : 'Crear mi cuenta', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}