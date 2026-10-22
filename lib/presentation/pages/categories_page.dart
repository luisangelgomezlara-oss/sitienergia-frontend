import 'package:flutter/material.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/category.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';

class CategoriesPage extends StatefulWidget {
  final Session session;
  const CategoriesPage({super.key, required this.session});
  @override 
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> items = [];
  List<Category> filteredItems = []; // Para el buscador
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override 
  void initState() { 
    super.initState(); 
    _searchController.addListener(_filterCategories);
    refresh(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  
  // --- Lógica del buscador ---
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((c) => 
        c.nombre.toLowerCase().contains(query) || 
        c.area.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> refresh() async {
    try { 
      final data = await CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()).getCategories(widget.session.token); 
      if (mounted) {
        setState(() { 
          items = data; 
          filteredItems = data;
          loading = false; 
          _filterCategories(); // Mantiene el filtro si hay texto
        }); 
      }
    }
    catch (e) { 
      if (mounted) { setState(() => loading = false); message(e); } 
    }
  }
  
  Future<void> form({Category? item}) async {
    final name = TextEditingController(text: item?.nombre ?? '');
    final area = TextEditingController(text: item?.area ?? '');
    
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? 'Nueva categoría' : 'Editar categoría', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff176b87))), 
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre de la falla', border: OutlineInputBorder())), 
            const SizedBox(height: 16), 
            TextField(controller: area, decoration: const InputDecoration(labelText: 'Área responsable', border: OutlineInputBorder()))
          ]
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), 
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff176b87)),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Guardar')
          )
        ]
      )
    );
    
    if (ok != true) return;
    try { 
      final repo = CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()); 
      if (item == null) { 
        await repo.createCategory(widget.session.token, name.text, area.text); 
      } else { 
        await repo.updateCategory(widget.session.token, item.id, name.text, area.text); 
      } 
      refresh(); 
    } catch (e) { 
      message(e); 
    }
  }
  
  Future<void> deactivateCategory(Category item) async {
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desactivar categoría'), 
        content: Text('¿Desactivar la categoría "${item.nombre}"?'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), 
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Desactivar')
          )
        ]
      )
    );
    
    if (ok == true) { 
      try { 
        await CategoryRepositoryImpl(remoteDatasource: CategoryRemoteDatasource()).deleteCategory(widget.session.token, item.id); 
        refresh(); 
      } catch (e) { 
        message(e); 
      } 
    }
  }

  // --- Helpers visuales ---
  Color _getColorPorArea(String area) {
    final a = area.toLowerCase();
    if (a.contains('redes') || a.contains('electrica') || a.contains('tensión')) return Colors.blue;
    if (a.contains('obras') || a.contains('civil')) return Colors.orange;
    if (a.contains('comercial') || a.contains('medidor')) return Colors.green;
    return Colors.purple; // Por defecto
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff176b87),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Categoría',
            onPressed: () => form(),
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
                    hintText: 'Buscar categoría...',
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
              
              // --- Lista de Categorías ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh, 
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), 
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final inicial = item.nombre.isNotEmpty ? item.nombre[0].toUpperCase() : 'C';
                      final colorArea = _getColorPorArea(item.area);

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
                              // Avatar Dinámico
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: colorArea.withOpacity(0.15),
                                child: Text(inicial, style: TextStyle(color: colorArea, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              
                              // Info de la Categoría
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: colorArea, borderRadius: BorderRadius.circular(8)),
                                      child: Text(item.area.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                              
                              // Botones de acción
                              Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Color(0xff176b87)), onPressed: () => form(item: item)), 
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deactivateCategory(item))
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