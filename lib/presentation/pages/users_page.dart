import 'package:flutter/material.dart';
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
  List<User> filteredItems = []; // Nueva lista para la barra de búsqueda
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override 
  void initState() { 
    super.initState(); 
    _searchController.addListener(_filterUsers); // Escucha la barra de búsqueda
    refresh(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  
  // --- Lógica de la barra de búsqueda ---
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((u) => 
        u.nombre.toLowerCase().contains(query) || 
        u.telefono.contains(query) || 
        u.rol.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> refresh() async {
    try { 
      final data = await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).getUsers(widget.session.token); 
      if (mounted) setState(() { 
        items = data; 
        filteredItems = data; // Inicializamos la lista filtrada
        loading = false; 
        _filterUsers(); // Aplicamos filtro si ya había algo escrito
      }); 
    }
    catch (e) { 
      if (mounted) { setState(() => loading = false); message(e); } 
    }
  }
  
  Future<void> edit(User item) async {
    final name = TextEditingController(text: item.nombre);
    final phone = TextEditingController(text: item.telefono);
    String role = item.rol;
    bool active = item.activo;
    
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff176b87))), 
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())), 
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
                      DropdownMenuItem(value: 'USER', child: Text('USER (TÉCNICO)')), 
                      DropdownMenuItem(value: 'CLIENTE', child: Text('CLIENTE'))
                    ], 
                    onChanged: (val) { if (val != null) setDialog(() => role = val); }
                  ),
                ),
              ), 
              const SizedBox(height: 8),
              SwitchListTile(title: const Text('Usuario Activo'), value: active, onChanged: (val) => setDialog(() => active = val), contentPadding: EdgeInsets.zero)
            ]
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
        await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).updateUser(widget.session.token, item.id, name.text, role, phone.text, active); 
        refresh(); 
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
        await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).deleteUser(widget.session.token, item.id); 
        refresh(); 
      } catch (e) { message(e); } 
    }
  }

  // --- Helpers para el diseño dinámico ---
  Color _getColorPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN': return Colors.purple;
      case 'CLIENTE': return Colors.green;
      default: return Colors.orange; // Para USER o TÉCNICO
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulario de creación en desarrollo')));
            },
          )
        ],
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // --- Barra de búsqueda ---
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
              
              // --- Lista de Usuarios ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh, 
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), 
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final inicial = item.nombre.isNotEmpty ? item.nombre[0].toUpperCase() : '?';
                      final textoTelefono = item.telefono.isEmpty ? 'Sin teléfono' : item.telefono;
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
                              // Avatar
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: colorRol.withOpacity(0.15),
                                child: Text(inicial, style: TextStyle(color: colorRol, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              
                              // Información del usuario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(textoTelefono, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    
                                    // Etiqueta del rol (Chip)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: colorRol, borderRadius: BorderRadius.circular(8)),
                                      child: Text(item.rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                              
                              // Botones de acción
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