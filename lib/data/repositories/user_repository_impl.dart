import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource remoteDatasource;

  UserRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<User>> getUsers(String token) {
    return remoteDatasource.getUsers(token);
  }

  @override
  Future<void> updateUser(String token, int id, String nombre, String rol, String telefono, bool activo) {
    return remoteDatasource.updateUser(token, id, nombre, rol, telefono, activo);
  }

  @override
  Future<void> deleteUser(String token, int id) {
    return remoteDatasource.deleteUser(token, id);
  }
}