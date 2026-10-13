import 'package:flutter/material.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';

class UsersPage extends StatefulWidget {
  final Session session;
  const UsersPage({super.key, required this.session});
  @override State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> items = [];
  bool loading = true;
  @override void initState() { super.initState(); refresh(); }
  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  
  Future<void> refresh() async {
    try { final data = await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).getUsers(widget.session.token); if (mounted) setState(() { items = data; loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); message(e); } }
  }
  
  Future<void> edit(User item) async {
    final name = TextEditingController(text: item.nombre);
    final phone = TextEditingController(text: item.telefono);
    String role = item.rol;
    bool active = item.activo;
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(title: const Text('Editar usuario'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')), const SizedBox(height: 10), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono')), const SizedBox(height: 10), DropdownButton<String>(value: role, isExpanded: true, items: const [DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')), DropdownMenuItem(value: 'USER', child: Text('USER'))], onChanged: (val) { if (val != null) setDialog(() => role = val); }), SwitchListTile(title: const Text('Activo'), value: active, onChanged: (val) => setDialog(() => active = val), contentPadding: EdgeInsets.zero)]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar'))])));
    if (ok == true) { try { await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).updateUser(widget.session.token, item.id, name.text, role, phone.text, active); refresh(); } catch (e) { message(e); } }
  }
  
  Future<void> deactivateUser(User item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Desactivar usuario'), content: Text('¿Desactivar "${item.nombre}"?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar'))]));
    if (ok == true) { try { await UserRepositoryImpl(remoteDatasource: UserRemoteDatasource()).deleteUser(widget.session.token, item.id); refresh(); } catch (e) { message(e); } }
  }
  
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: refresh, 
      child: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          ...items.map((item) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(item.nombre[0])), 
              title: Text(item.nombre), 
              subtitle: Text('${item.telefono} • ${item.rol}'), 
              trailing: Row(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  IconButton(tooltip: 'Editar', onPressed: () => edit(item), icon: const Icon(Icons.edit_outlined)), 
                  IconButton(tooltip: 'Desactivar', onPressed: item.activo ? () => deactivateUser(item) : null, icon: const Icon(Icons.delete_outline, color: Colors.red))
                ]
              )
            )
          ))
        ]
      )
    );
  }
}