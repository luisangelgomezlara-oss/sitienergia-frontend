import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';

class UsersPage extends StatefulWidget {
  final Session session;
  const UsersPage({super.key, required this.session});
  @override 
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> items = [];
  List<User> filteredItems = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/usuarios'; 
  
  final _formKey = GlobalKey<FormState>();
  String _nuevoNombre = '';
  String _nuevoCorreo = '';
  String _nuevaCedula = ''; 
  String _nuevoTelefono = ''; 
  String _nuevoPassword = '';
  String _nuevoRol = 'TECNICO';
  String _nuevaEspecialidad = 'REDES ELECTRICAS';
  bool _isCreating = false;

  @override 
  void initState() { 
    super.initState(); 
    _searchController.addListener(_filterUsers);
    refresh(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((u) => 
        u.nombre.toLowerCase().contains(query) || 
        u.telefono.contains(query) || 
        (u.cedula != null && u.cedula!.contains(query)) ||
        u.rol.toLowerCase().contains(query) ||
        (u.especialidad != null && u.especialidad!.toLowerCase().contains(query))
      ).toList();
    });
  }

  Future<void> refresh() async {
    setState(() => loading = true);
    try { 
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer ${widget.session.token}'}
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data.map((item) => User.fromJson(item)).toList();
        if (mounted) {
          setState(() { 
            items = list; 
            filteredItems = list;
            loading = false; 
            _filterUsers();
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) { 
      if (mounted) { setState(() => loading = false); message(e); } 
    }
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isCreating = true);

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.session.token}'
        },
        body: jsonEncode({
          'nombre': _nuevoNombre,
          'email': _nuevoCorreo,
          'password': _nuevoPassword,
          'rol': _nuevoRol,
          'cedula': _nuevaCedula, 
          'telefono': _nuevoTelefono, 
          'especialidad': _nuevoRol == 'TECNICO' ? _nuevaEspecialidad : null,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente'), backgroundColor: Colors.green),
        );
        refresh(); 
      } else {
        throw Exception('Error al crear usuario. Código: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión local: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _mostrarFormularioCreacion() {
    _nuevoRol = 'TECNICO';
    _nuevaEspecialidad = 'REDES ELECTRICAS';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Registrar Personal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff176b87))),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                        onSaved: (val) => _nuevoNombre = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Identificación (Cédula)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _nuevaCedula = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        onSaved: (val) => _nuevoTelefono = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (val) => _nuevoCorreo = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                        obscureText: true,
                        onSaved: (val) => _nuevoPassword = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _nuevoRol, 
                            isExpanded: true, 
                            items: const [
                              DropdownMenuItem(value: 'TECNICO', child: Text('TÉCNICO')), 
                              DropdownMenuItem(value: 'ADMIN', child: Text('ADMINISTRADOR')),
                              DropdownMenuItem(value: 'CLIENTE', child: Text('CLIENTE'))
                            ], 
                            onChanged: (val) { if (val != null) setModalState(() => _nuevoRol = val); }
                          ),
                        ),
                      ),
                      if (_nuevoRol == 'TECNICO') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _nuevaEspecialidad,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'REDES ELECTRICAS', child: Text('REDES ELECTRICAS')),
                                DropdownMenuItem(value: 'OBRAS CIVILES', child: Text('OBRAS CIVILES')),
                                DropdownMenuItem(value: 'COMERCIAL', child: Text('COMERCIAL')),
                              ],
                              onChanged: (val) { if (val != null) setModalState(() => _nuevaEspecialidad = val); },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff176b87)),
                          onPressed: _isCreating ? null : () async {
                            setModalState(() => _isCreating = true);
                            await _crearUsuario();
                            setModalState(() => _isCreating = false);
                          },
                          child: _isCreating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  Future<void> edit(User item) async {
    final name = TextEditingController(text: item.nombre);
    final cedula = TextEditingController(text: item.cedula ?? '');
    final phone = TextEditingController(text: item.telefono);
    String role = item.rol;
    bool active = item.activo;
    String? especialidad = item.especialidad ?? 'REDES ELECTRICAS';
    
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff176b87))), 
          content: SingleChildScrollView( 
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())), 
                const SizedBox(height: 16), 
                TextField(controller: cedula, decoration: const InputDecoration(labelText: 'Identificación (Cédula)', border: OutlineInputBorder())), 
                const SizedBox(height: 16), 
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())), 
                const SizedBox(height: 16), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role, 
                      isExpanded: true, 
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')), 
                        DropdownMenuItem(value: 'TECNICO', child: Text('TÉCNICO')), 
                        DropdownMenuItem(value: 'CLIENTE', child: Text('CLIENTE'))
                      ], 
                      onChanged: (val) { if (val != null) setDialog(() => role = val); }
                    ),
                  ),
                ), 
                if (role == 'TECNICO') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: especialidad,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'REDES ELECTRICAS', child: Text('REDES ELECTRICAS')),
                          DropdownMenuItem(value: 'OBRAS CIVILES', child: Text('OBRAS CIVILES')),
                          DropdownMenuItem(value: 'COMERCIAL', child: Text('COMERCIAL')),
                        ],
                        onChanged: (val) { if (val != null) setDialog(() => especialidad = val); },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(title: const Text('Usuario Activo'), value: active, onChanged: (val) => setDialog(() => active = val), contentPadding: EdgeInsets.zero)
              ]
            ),
          ), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), 
            FilledButton(
              onPressed: () => Navigator.pop(context, true), 
              style: FilledButton.styleFrom(backgroundColor: const Color(0xff176b87)),
              child: const Text('Guardar Cambios')
            )
          ]
        )
      )
    );
    if (ok == true) { 
      try { 
        final response = await http.put(
          Uri.parse('$baseUrl/${item.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.session.token}'
          },
          body: jsonEncode({
            'nombre': name.text,
            'rol': role,
            'cedula': cedula.text,
            'telefono': phone.text,
            'activo': active,
            'especialidad': role == 'TECNICO' ? especialidad : null,
          }),
        );

        if (response.statusCode == 200) {
          refresh(); 
        } else {
          throw Exception('Error al actualizar. Servidor dice: ${response.statusCode}');
        }
      } catch (e) { message(e); } 
    }
  }
  
  Future<void> deactivateUser(User item) async {
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desactivar usuario'), 
        content: Text('¿Estás seguro de que deseas desactivar a "${item.nombre}"?'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), 
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar')
          )
        ]
      )
    );
    if (ok == true) { 
      try { 
        final response = await http.delete(
          Uri.parse('$baseUrl/${item.id}'),
          headers: {'Authorization': 'Bearer ${widget.session.token}'}
        );
        if (response.statusCode == 204 || response.statusCode == 200) {
          refresh(); 
        } else {
          throw Exception('Error al desactivar');
        }
      } catch (e) { message(e); } 
    }
  }

  Color _getColorPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN': return Colors.purple;
      case 'CLIENTE': return Colors.green;
      default: return Colors.orange;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear Usuario',
            onPressed: _mostrarFormularioCreacion, 
          )
        ],
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xff176b87),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh, 
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), 
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final inicial = item.nombre.isNotEmpty ? item.nombre[0].toUpperCase() : '?';
                      
                      final textoCedula = (item.cedula != null && item.cedula!.isNotEmpty) ? 'C.C: ${item.cedula}' : 'Sin Cédula';
                      final textoTelefono = item.telefono.isNotEmpty ? 'Tel: ${item.telefono}' : 'Sin Teléfono';
                      final colorRol = _getColorPorRol(item.rol);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: colorRol.withOpacity(0.15),
                                child: Text(inicial, style: TextStyle(color: colorRol, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('$textoCedula  •  $textoTelefono', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    
                                    // --- FIX: Cambiamos Row por Wrap para evitar el Overflow ---
                                    Wrap(
                                      spacing: 6, // Espacio horizontal entre etiquetas
                                      runSpacing: 4, // Espacio vertical si se bajan de línea
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: colorRol, borderRadius: BorderRadius.circular(8)),
                                          child: Text(item.rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        if (item.rol.toUpperCase() == 'TECNICO' && item.especialidad != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                                            child: Text(item.especialidad!, style: const TextStyle(color: Color(0xff176b87), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              
                              Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  IconButton(tooltip: 'Editar', onPressed: () => edit(item), icon: const Icon(Icons.edit, color: Color(0xff176b87))), 
                                  IconButton(tooltip: 'Desactivar', onPressed: item.activo ? () => deactivateUser(item) : null, icon: Icon(Icons.delete, color: item.activo ? Colors.red[400] : Colors.grey[300]))
                                ]
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  )
                ),
              ),
            ],
          ),
    );
  }
}