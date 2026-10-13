import '../entities/session.dart';

abstract class AuthRepository {
  Future<Session> login(String email, String password);
  Future<void> register(String nombre, String email, String telefono, String password);
}