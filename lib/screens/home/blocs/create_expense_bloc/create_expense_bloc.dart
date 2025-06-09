import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/services/local_storage_service.dart';

// Events
abstract class CreateExpenseEvent extends Equatable {
  const CreateExpenseEvent();

  @override
  List<Object> get props => [];
}

class CreateExpense extends CreateExpenseEvent {
  final String title;
  final double total;
  final Category category;
  final List<Map<String, String>> items;
  final String? imagePath;
  final String? ocrText;

  const CreateExpense({
    required this.title,
    required this.total,
    required this.category,
    required this.items,
    this.imagePath,
    this.ocrText,
  });

  @override
  List<Object> get props => [title, total, category, items, imagePath ?? '', ocrText ?? ''];
}

// States
abstract class CreateExpenseState extends Equatable {
  const CreateExpenseState();

  @override
  List<Object> get props => [];
}

class CreateExpenseInitial extends CreateExpenseState {}

class CreateExpenseLoading extends CreateExpenseState {}

class CreateExpenseSuccess extends CreateExpenseState {
  final Expense expense;

  const CreateExpenseSuccess(this.expense);

  @override
  List<Object> get props => [expense];
}

class CreateExpenseFailure extends CreateExpenseState {
  final String error;

  const CreateExpenseFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bloc
class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  final LocalStorageService expenseRepository;

  CreateExpenseBloc({required this.expenseRepository}) : super(CreateExpenseInitial()) {
    on<CreateExpense>(_onCreateExpense);
  }

  Future<void> _onCreateExpense(
    CreateExpense event,
    Emitter<CreateExpenseState> emit,
  ) async {
    try {
      emit(CreateExpenseLoading());

      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title,
        total: event.total,
        date: DateTime.now(),
        category: event.category,
        items: event.items,
      );

      await expenseRepository.addExpense(expense);
      emit(CreateExpenseSuccess(expense));
    } catch (e) {
      emit(CreateExpenseFailure(e.toString()));
    }
  }
} 