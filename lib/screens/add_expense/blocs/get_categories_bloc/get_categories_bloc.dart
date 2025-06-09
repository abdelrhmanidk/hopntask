import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/services/local_storage_service.dart';

// Events
abstract class GetCategoriesEvent extends Equatable {
  const GetCategoriesEvent();

  @override
  List<Object> get props => [];
}

class GetCategories extends GetCategoriesEvent {}

// States
abstract class GetCategoriesState extends Equatable {
  const GetCategoriesState();

  @override
  List<Object> get props => [];
}

class GetCategoriesInitial extends GetCategoriesState {}

class GetCategoriesLoading extends GetCategoriesState {}

class GetCategoriesSuccess extends GetCategoriesState {
  final List<Category> categories;

  const GetCategoriesSuccess(this.categories);

  @override
  List<Object> get props => [categories];
}

class GetCategoriesFailure extends GetCategoriesState {
  final String error;

  const GetCategoriesFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bloc
class GetCategoriesBloc extends Bloc<GetCategoriesEvent, GetCategoriesState> {
  final LocalStorageService expenseRepository;

  GetCategoriesBloc({required this.expenseRepository}) : super(GetCategoriesInitial()) {
    on<GetCategories>(_onGetCategories);
  }

  Future<void> _onGetCategories(
    GetCategories event,
    Emitter<GetCategoriesState> emit,
  ) async {
    try {
      emit(GetCategoriesLoading());
      final categoryNames = await expenseRepository.getCategories();
      final categories = categoryNames.map((name) => Category(
        id: name,
        name: name,
        color: '0xFF000000',
        icon: 'category',
      )).toList();
      emit(GetCategoriesSuccess(categories));
    } catch (e) {
      emit(GetCategoriesFailure(e.toString()));
    }
  }
} 