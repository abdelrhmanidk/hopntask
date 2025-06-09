import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/services/local_storage_service.dart';

// Events
abstract class GetExpensesEvent extends Equatable {
  const GetExpensesEvent();

  @override
  List<Object> get props => [];
}

class GetExpenses extends GetExpensesEvent {}

class SearchExpenses extends GetExpensesEvent {
  final String query;

  const SearchExpenses(this.query);

  @override
  List<Object> get props => [query];
}

// States
abstract class GetExpensesState extends Equatable {
  const GetExpensesState();

  @override
  List<Object> get props => [];
}

class GetExpensesInitial extends GetExpensesState {}

class GetExpensesLoading extends GetExpensesState {}

class GetExpensesSuccess extends GetExpensesState {
  final List<Expense> expenses;

  const GetExpensesSuccess(this.expenses);

  @override
  List<Object> get props => [expenses];
}

class GetExpensesFailure extends GetExpensesState {
  final String error;

  const GetExpensesFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bloc
class GetExpensesBloc extends Bloc<GetExpensesEvent, GetExpensesState> {
  final LocalStorageService expenseRepository;

  GetExpensesBloc({required this.expenseRepository}) : super(GetExpensesInitial()) {
    on<GetExpenses>(_onGetExpenses);
    on<SearchExpenses>(_onSearchExpenses);
  }

  Future<void> _onGetExpenses(
    GetExpenses event,
    Emitter<GetExpensesState> emit,
  ) async {
    try {
      emit(GetExpensesLoading());
      print('GetExpensesBloc: Starting to load expenses...');

      final expenses = await expenseRepository.getExpenses();
      print('GetExpensesBloc: Loaded ${expenses.length} expenses');
      if (expenses.isNotEmpty) {
        print('GetExpensesBloc: First expense - ${expenses.first.title} (${expenses.first.total})');
      }

      emit(GetExpensesSuccess(expenses));
      print('GetExpensesBloc: Emitted GetExpensesSuccess state');
    } catch (e) {
      print('GetExpensesBloc: Error loading expenses - $e');
      emit(GetExpensesFailure(e.toString()));
    }
  }

  Future<void> _onSearchExpenses(
    SearchExpenses event,
    Emitter<GetExpensesState> emit,
  ) async {
    try {
      emit(GetExpensesLoading());
      final expenses = await expenseRepository.getExpenses();
      final filteredExpenses = expenses.where((expense) {
        final title = expense.title.toLowerCase();
        final categoryName = expense.category.name.toLowerCase();
        final query = event.query.toLowerCase();
        return title.contains(query) || categoryName.contains(query);
      }).toList();
      emit(GetExpensesSuccess(filteredExpenses));
    } catch (e) {
      emit(GetExpensesFailure(e.toString()));
    }
  }
}
