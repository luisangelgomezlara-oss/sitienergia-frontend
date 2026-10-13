import '../../domain/entities/session.dart';

class SessionModel extends Session {
  SessionModel({
    required super.token,
    required super.nombre,
    required super.rol,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      token: json['token'],
      nombre: json['nombre'],
      rol: json['rol'],
    );
  }
}