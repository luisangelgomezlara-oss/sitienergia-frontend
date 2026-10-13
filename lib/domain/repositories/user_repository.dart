import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers(String token);
  Future<void> updateUser(String token, int id, String nombre, String rol, String telefono, bool activo);
  Future<void> deleteUser(String token, int id);
}