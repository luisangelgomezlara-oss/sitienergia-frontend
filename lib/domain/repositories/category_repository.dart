import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories(String token);
  Future<void> createCategory(String token, String nombre, String area);
  Future<void> updateCategory(String token, int id, String nombre, String area);
  Future<void> deleteCategory(String token, int id);
}