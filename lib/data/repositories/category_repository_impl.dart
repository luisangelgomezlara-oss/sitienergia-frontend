import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDatasource remoteDatasource;
  CategoryRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Category>> getCategories(String token) => remoteDatasource.getCategories(token);
  @override
  Future<void> createCategory(String token, String nombre, String area) => remoteDatasource.createCategory(token, nombre, area);
  @override
  Future<void> updateCategory(String token, int id, String nombre, String area) => remoteDatasource.updateCategory(token, id, nombre, area);
  @override
  Future<void> deleteCategory(String token, int id) => remoteDatasource.deleteCategory(token, id);
}