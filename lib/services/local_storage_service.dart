import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hopntask/models/expense.dart';

class LocalStorageService {
  static const String _expensesFileName = 'expenses.json';
  static const String _categoriesFileName = 'categories.json';
  static const List<String> _defaultCategories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills',
    'Other'
  ];

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final categoriesFile = File('${directory.path}/$_categoriesFileName');

    if (!await categoriesFile.exists()) {
      await categoriesFile.writeAsString(jsonEncode(_defaultCategories));
    }
  }

  Future<List<String>> getCategories() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_categoriesFileName');

    if (!await file.exists()) {
      await file.writeAsString(jsonEncode(_defaultCategories));
      return _defaultCategories;
    }

    final contents = await file.readAsString();
    final List<dynamic> categories = jsonDecode(contents);
    return categories.map((e) => e.toString()).toList();
  }

  Future<void> addCategory(String category) async {
    final categories = await getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_categoriesFileName');
      await file.writeAsString(jsonEncode(categories));
    }
  }

  Future<List<Expense>> getExpenses() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_expensesFileName');

    if (!await file.exists()) {
      return [];
    }

    final contents = await file.readAsString();
    final List<dynamic> expensesJson = jsonDecode(contents);
    return expensesJson.map((json) => Expense.fromJson(json)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_expensesFileName');
    await file.writeAsString(jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await saveExpenses(expenses);
  }

  Future<void> deleteExpense(String id) async {
    final expenses = await getExpenses();
    expenses.removeWhere((expense) => expense.id == id);
    await saveExpenses(expenses);
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    final expenses = await getExpenses();
    final index = expenses.indexWhere((expense) => expense.id == updatedExpense.id);
    if (index != -1) {
      expenses[index] = updatedExpense;
      await saveExpenses(expenses);
    }
  }
} 