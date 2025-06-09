import '../models/category.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../services/chroma_service.dart';
import '../services/local_storage_service.dart';

class LocalExpenseRepo implements ExpenseRepository {
  final List<Expense> _expenses = [];
  final List<Category> _categories = [];
  final ChromaService _chromaService;
  final LocalStorageService _localStorageService;

  LocalExpenseRepo({
    ChromaService? chromaService,
    LocalStorageService? localStorageService,
  }) : _chromaService = chromaService ?? ChromaService(),
       _localStorageService = localStorageService ?? LocalStorageService() {
    print('Initializing LocalExpenseRepo with default categories'); // Debug print
    // Initialize with default categories
    _categories.addAll(Category.defaultCategories);
    print('Added ${_categories.length} default categories'); // Debug print
    
    // Load expenses from local storage
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _localStorageService.getExpenses();
      _expenses.clear();
      _expenses.addAll(expenses);
      print('Loaded ${expenses.length} expenses from local storage'); // Debug print
    } catch (e) {
      print('Error loading expenses from local storage: $e'); // Debug print
    }
  }

  @override
  Future<void> createCategory(Category category) async {
    print('Creating new category: ${category.name}'); // Debug print
    _categories.add(category);
    print('Total categories after creation: ${_categories.length}'); // Debug print
  }

  @override
  Future<void> createExpense(Expense expense) async {
    print('Creating new expense: ${expense.title}'); // Debug print
    _expenses.insert(0, expense); // Add new expense at the beginning
    
    // Save to local storage
    try {
      await _localStorageService.addExpense(expense);
      print('Successfully saved expense to local storage'); // Debug print
    } catch (e) {
      print('Error saving expense to local storage: $e'); // Debug print
    }
    
    // Save to ChromaDB
    try {
      await _chromaService.addReceipt(
        id: expense.id,
        vendor: expense.title,
        total: expense.total,
        date: expense.date,
        items: expense.items,
        category: expense.category.name,
      );
      print('Successfully saved expense to ChromaDB'); // Debug print
    } catch (e) {
      print('Error saving expense to ChromaDB: $e'); // Debug print
      // Continue with local storage even if ChromaDB fails
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    print('Getting categories, count: ${_categories.length}'); // Debug print
    if (_categories.isEmpty) {
      print('No categories found, returning default categories'); // Debug print
      return Category.defaultCategories;
    }
    return _categories;
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      // Try to get expenses from ChromaDB first
      final chromaExpenses = await _chromaService.getAllReceipts();
      if (chromaExpenses.isNotEmpty) {
        print('Found ${chromaExpenses.length} expenses in ChromaDB'); // Debug print
        final expenses = chromaExpenses.map((data) => Expense(
          id: data['id'] as String,
          title: data['vendor'] as String,
          total: (data['total'] as num).toDouble(),
          date: DateTime.parse(data['date'] as String),
          category: _categories.firstWhere(
            (c) => c.name == data['category'],
            orElse: () => Category.defaultCategories.first,
          ),
          items: List<Map<String, String>>.from(
            (data['items'] as List).map(
              (item) => Map<String, String>.from(item as Map),
            ),
          ),
        )).toList();
        
        // Update local storage with ChromaDB data
        await _localStorageService.saveExpenses(expenses);
        _expenses.clear();
        _expenses.addAll(expenses);
        
        return expenses;
      }
    } catch (e) {
      print('Error getting expenses from ChromaDB: $e'); // Debug print
    }
    
    // If ChromaDB fails or is empty, use local storage
    print('Using local storage for expenses'); // Debug print
    return _expenses;
  }

  // Search for similar expenses
  Future<List<Expense>> searchSimilarExpenses(String query) async {
    try {
      final results = await _chromaService.searchReceipts(query);
      return results.map((data) => Expense(
        id: data['id'] as String,
        title: data['vendor'] as String,
        total: (data['total'] as num).toDouble(),
        date: DateTime.parse(data['date'] as String),
        category: _categories.firstWhere(
          (c) => c.name == data['category'],
          orElse: () => Category.defaultCategories.first,
        ),
        items: List<Map<String, String>>.from(
          (data['items'] as List).map(
            (item) => Map<String, String>.from(item as Map),
          ),
        ),
      )).toList();
    } catch (e) {
      print('Error searching expenses: $e'); // Debug print
      return [];
    }
  }
} 