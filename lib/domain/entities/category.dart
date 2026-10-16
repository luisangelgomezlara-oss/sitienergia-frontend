class Category {
  final int id;
  final String nombre;
  final String area;

  Category({
    required this.id,
    required this.nombre,
    required this.area,
  });

  // 👇 ESTE ES EL MÉTODO QUE FALTA. AGRÉGALO AQUÍ 👇
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nombre: json['nombre'],
      area: json['area'],
    );
  }
}