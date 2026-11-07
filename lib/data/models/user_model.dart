import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.nombre,
    required super.email,
    required super.rol,
    required super.telefono,
    super.cedula,
    super.nic,
    required super.activo,
    super.especialidad,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'CLIENTE',
      telefono: json['telefono'] ?? '',
      cedula: json['cedula']?.toString(),
      nic: json['nic']?.toString(),
      activo: json['activo'] ?? true,
      especialidad: json['especialidad']?.toString(),
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
      'especialidad': especialidad,
    };
  }
}