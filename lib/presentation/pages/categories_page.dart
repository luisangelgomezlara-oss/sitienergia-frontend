import 'package:flutter/material.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/category.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';

class CategoriesPage extends StatefulWidget {
  final Session session;
  const CategoriesPage({super.key, required this.session});
  @override State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> items = [];
  bool loading = true;
  @override void initState() { super.initState(); refresh(); }
  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  
  Future<void> refresh() async {
    try { final data = await CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()).getCategories(widget.session.token); if (mounted) setState(() { items = data; loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); message(e); } }
  }
  
  Future<void> form({Category? item}) async {
    final name = TextEditingController(text: item?.nombre ?? '');
    final area = TextEditingController(text: item?.area ?? '');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(item == null ? 'Nueva categoría' : 'Editar categoría'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')), const SizedBox(height: 10), TextField(controller: area, decoration: const InputDecoration(labelText: 'Área'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar'))]));
    if (ok != true) return;
    try { final repo = CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()); if (item == null) { await repo.createCategory(widget.session.token, name.text, area.text); } else { await repo.updateCategory(widget.session.token, item.id, name.text, area.text); } refresh(); } catch (e) { message(e); }
  }
  
  Future<void> deactivateCategory(Category item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Desactivar categoría'), content: Text('¿Desactivar "${item.nombre}"?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar'))]));
    if (ok == true) { try { await CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()).deleteCategory(widget.session.token, item.id); refresh(); } catch (e) { message(e); } }
  }
  
  @override
  Widget build(BuildContext context) => loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
    Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => form(), icon: const Icon(Icons.add), label: const Text('Nueva categoría'))),
    const SizedBox(height: 10),
    ...items.map((item) => Card(child: ListTile(leading: const Icon(Icons.label_outline), title: Text(item.nombre), subtitle: Text(item.area), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => form(item: item)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => deactivateCategory(item))]))))
  ]));
}