import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/session.dart';

class CategoriaItem {
  final int id;
  final String nombre;
  final String area;
  final bool activa;

  CategoriaItem({
    required this.id,
    required this.nombre,
    required this.area,
    required this.activa,
  });

  factory CategoriaItem.fromJson(Map<String, dynamic> json) {
    return CategoriaItem(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      area: json['area'] ?? 'REDES ELECTRICAS',
      activa: json['activa'] ?? true,
    );
  }
}

class CategoriesPage extends StatefulWidget {
  final Session session;
  const CategoriesPage({super.key, required this.session});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<CategoriaItem> items = [];
  List<CategoriaItem> filteredItems = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  // Ajusta la ruta final si tu backend usa otro nombre como /api/incident-categories
  final String baseUrl = 'https://sitienergia-backend.onrender.com/api/categorias'; 
  
  final _formKey = GlobalKey<FormState>();
  String _nuevoNombre = '';
  String _nuevaArea = 'REDES ELECTRICAS'; // Valor por defecto del Dropdown
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCategorias);
    refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void message(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));

  void _filterCategorias() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((c) =>
        c.nombre.toLowerCase().contains(query) ||
        c.area.toLowerCase().contains(query)
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
        final list = data.map((item) => CategoriaItem.fromJson(item)).toList();
        if (mounted) {
          setState(() {
            items = list;
            filteredItems = list;
            loading = false;
            _filterCategorias();
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) { setState(() => loading = false); message(e); }
    }
  }

  Future<void> _crearCategoria() async {
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
          'area': _nuevaArea, // Se envía directamente lo seleccionado en el filtro
          'activa': true,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría creada exitosamente'), backgroundColor: Colors.green),
        );
        refresh();
      } else {
        throw Exception('Error al crear. Código: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _mostrarFormularioCreacion() {
    _nuevaArea = 'REDES ELECTRICAS'; // Reiniciar valor al abrir
    
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
                      const Text('Nueva Categoría', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff176b87))),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre de la Falla', border: OutlineInputBorder()),
                        onSaved: (val) => _nuevoNombre = val ?? '',
                        validator: (val) => val!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // --- DROPDOWN PARA EL ÁREA (CREACIÓN) ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _nuevaArea,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'REDES ELECTRICAS', child: Text('REDES ELECTRICAS')),
                              DropdownMenuItem(value: 'OBRAS CIVILES', child: Text('OBRAS CIVILES')),
                              DropdownMenuItem(value: 'COMERCIAL', child: Text('COMERCIAL')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => _nuevaArea = val);
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff176b87)),
                          onPressed: _isCreating ? null : () async {
                            setModalState(() => _isCreating = true);
                            await _crearCategoria();
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

  Future<void> edit(CategoriaItem item) async {
    final name = TextEditingController(text: item.nombre);
    String area = item.area;
    bool active = item.activa;
    
    // Validar que el área actual esté dentro de las opciones, sino asignar por defecto
    if (!['REDES ELECTRICAS', 'OBRAS CIVILES', 'COMERCIAL'].contains(area)) {
      area = 'REDES ELECTRICAS';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff176b87))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre de la Falla', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                
                // --- DROPDOWN PARA EL ÁREA (EDICIÓN) ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: area,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'REDES ELECTRICAS', child: Text('REDES ELECTRICAS')),
                        DropdownMenuItem(value: 'OBRAS CIVILES', child: Text('OBRAS CIVILES')),
                        DropdownMenuItem(value: 'COMERCIAL', child: Text('COMERCIAL')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialog(() => area = val);
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Categoría Activa'), 
                  value: active, 
                  onChanged: (val) => setDialog(() => active = val), 
                  contentPadding: EdgeInsets.zero
                )
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
            'area': area,
            'activa': active,
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

  Future<void> deactivateCategory(CategoriaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar/Desactivar'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${item.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar')
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
          throw Exception('Error al eliminar');
        }
      } catch (e) { message(e); }
    }
  }

  Color _getColorPorArea(String area) {
    if (area.contains('REDES')) return Colors.blue;
    if (area.contains('OBRAS')) return Colors.orange;
    if (area.contains('COMERCIAL')) return Colors.green;
    return Colors.blueGrey;
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
            tooltip: 'Crear Categoría',
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
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final inicial = item.nombre.isNotEmpty ? item.nombre[0].toUpperCase() : '?';
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
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: colorArea.withOpacity(0.15),
                                child: Text(inicial, style: TextStyle(color: colorArea, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nombre, 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: item.activa ? Colors.black87 : Colors.grey,
                                        decoration: item.activa ? TextDecoration.none : TextDecoration.lineThrough
                                      )
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: colorArea, borderRadius: BorderRadius.circular(8)),
                                      child: Text(item.area, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(tooltip: 'Editar', onPressed: () => edit(item), icon: const Icon(Icons.edit, color: Color(0xff176b87))),
                                  IconButton(tooltip: 'Eliminar', onPressed: () => deactivateCategory(item), icon: Icon(Icons.delete, color: Colors.red[400]))
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