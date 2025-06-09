import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hopntask/app.dart';
import 'package:hopntask/data/local_expense_repo.dart';
import 'package:hopntask/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:hopntask/services/database_service.dart';
import 'package:hopntask/services/ocr_service.dart';
import 'package:hopntask/services/chat_service.dart';
import 'package:hopntask/services/export_service.dart';
import 'package:hopntask/services/local_storage_service.dart';
import 'simple_bloc_observer.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize services
  final databaseService = DatabaseService();
  final ocrService = OCRService();
  final localExpenseRepo = LocalExpenseRepo();
  final chatService = ChatService();
  final exportService = ExportService();

  // Set up BLoC observer
  Bloc.observer = SimpleBlocObserver();
  
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DatabaseService>(create: (context) => databaseService),
        RepositoryProvider<OCRService>(create: (context) => ocrService),
        RepositoryProvider<LocalExpenseRepo>(create: (context) => localExpenseRepo),
        RepositoryProvider<ChatService>(create: (context) => chatService),
        RepositoryProvider<ExportService>(create: (context) => exportService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GetExpensesBloc>(
            create: (context) => GetExpensesBloc(
              expenseRepository: LocalStorageService(),
            )..add(GetExpenses()),
          ),
          BlocProvider<GetCategoriesBloc>(
            create: (context) => GetCategoriesBloc(
              expenseRepository: LocalStorageService(),
            )..add(GetCategories()),
          ),
          BlocProvider<CreateCategoryBloc>(
            create: (context) => CreateCategoryBloc(
              expenseRepository: LocalStorageService(),
            ),
          ),
          BlocProvider<CreateExpenseBloc>(
            create: (context) => CreateExpenseBloc(
              expenseRepository: LocalStorageService(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}