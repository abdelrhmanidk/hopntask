import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hopntask/services/local_storage_service.dart';
import 'package:hopntask/models/category.dart';

// Events
abstract class CreateCategoryEvent extends Equatable {
  const CreateCategoryEvent();

  @override
  List<Object> get props => [];
}

class CreateCategory extends CreateCategoryEvent {
  final String name;
  final String icon;
  final String color;

  const CreateCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  List<Object> get props => [name, icon, color];
}

// States
abstract class CreateCategoryState extends Equatable {
  const CreateCategoryState();

  @override
  List<Object> get props => [];
}

class CreateCategoryInitial extends CreateCategoryState {}

class CreateCategoryLoading extends CreateCategoryState {}

class CreateCategorySuccess extends CreateCategoryState {
  final Category category;

  const CreateCategorySuccess(this.category);

  @override
  List<Object> get props => [category];
}

class CreateCategoryFailure extends CreateCategoryState {
  final String error;

  const CreateCategoryFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bloc
class CreateCategoryBloc extends Bloc<CreateCategoryEvent, CreateCategoryState> {
  final LocalStorageService expenseRepository;

  CreateCategoryBloc({required this.expenseRepository}) : super(CreateCategoryInitial()) {
    on<CreateCategory>(_onCreateCategory);
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CreateCategoryState> emit,
  ) async {
    try {
      emit(CreateCategoryLoading());
      await expenseRepository.addCategory(event.name);
      emit(CreateCategorySuccess(Category(
        id: event.name,
        name: event.name,
        icon: event.icon,
        color: event.color,
      )));
    } catch (e) {
      emit(CreateCategoryFailure(e.toString()));
    }
  }
} 