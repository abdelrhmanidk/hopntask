import '../models/category.dart';
import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<void> createCategory(Category category);
  Future<void> createExpense(Expense expense);
  Future<List<Category>> getCategories();
  Future<List<Expense>> getExpenses();
} 