import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/services/local_storage_service.dart';

// Events
abstract class CreateExpenseEvent extends Equatable {
  const CreateExpenseEvent();

  @override
  List<Object> get props => [];
}

class CreateExpense extends CreateExpenseEvent {
  final Expense expense;

  const CreateExpense(this.expense);

  @override
  List<Object> get props => [expense];
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
      await expenseRepository.addExpense(event.expense);
      emit(CreateExpenseSuccess(event.expense));
    } catch (e) {
      emit(CreateExpenseFailure(e.toString()));
    }
  }
} 