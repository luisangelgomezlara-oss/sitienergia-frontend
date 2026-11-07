class User {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String telefono;
  final String? cedula;
  final String? nic;
  final bool activo;
  final String? especialidad; // <-- Campo añadido

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.telefono,
    this.cedula,
    this.nic,
    required this.activo,
    this.especialidad,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'CLIENTE',
      telefono: json['telefono'] ?? '',
      cedula: json['cedula'],
      nic: json['nic'],
      activo: json['activo'] ?? true,
      especialidad: json['especialidad'], // <-- Mapeo desde el JSON del backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'telefono': telefono,
      'cedula': cedula,
      'nic': nic,
      'activo': activo,
      'especialidad': especialidad, // <-- Envío hacia el backend
    };
  }
}