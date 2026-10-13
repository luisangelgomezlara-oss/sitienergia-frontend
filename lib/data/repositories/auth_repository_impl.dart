import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Session> login(String email, String password) {
    return remoteDatasource.login(email, password);
  }

  @override
  Future<void> register(String nombre, String email, String telefono, String password) {
    return remoteDatasource.register(nombre, email, telefono, password);
  }
}