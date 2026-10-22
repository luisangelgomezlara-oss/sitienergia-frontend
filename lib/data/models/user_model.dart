import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.nombre,
    required super.rol,
    required super.telefono,
    required super.activo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      rol: json['rol'],
      telefono: json['telefono'] ?? '',
      activo: json['activo'],
    );
  }
}