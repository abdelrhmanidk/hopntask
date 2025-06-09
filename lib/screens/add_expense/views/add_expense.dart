import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddExpense extends StatefulWidget {
  final Expense? initialExpense;

  const AddExpense({
    super.key,
    this.initialExpense,
  });

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late Category _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialExpense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.initialExpense?.total.toString() ?? '',
    );
    _selectedDate = widget.initialExpense?.date ?? DateTime.now();
    _selectedCategory = widget.initialExpense?.category ?? 
      Category(
        id: '1',
        name: 'Food',
        color: Colors.blue.value.toString(),
        icon: 'food',
      );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if(state is CreateExpenseSuccess) {
          Navigator.pop(context, widget.initialExpense);
        } else if(state is CreateExpenseLoading) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
          ),
          body: BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
            builder: (context, state) {
              if (state is GetCategoriesSuccess) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Add Expenses",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          controller: _amountController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              FontAwesomeIcons.dollarSign,
                              size: 16,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      TextFormField(
                        controller: _titleController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      TextFormField(
                        controller: _titleController,
                        textAlignVertical: TextAlignVertical.center,
                        readOnly: true,
                        onTap: () {},
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _selectedCategory == Category.empty ? Colors.white : Color(int.parse(_selectedCategory.color)),
                          prefixIcon: _selectedCategory == Category.empty
                            ? const Icon(
                                FontAwesomeIcons.list,
                                size: 16,
                                color: Colors.grey,
                              )
                            : _selectedCategory.icon.isNotEmpty
                              ? Icon(
                                  _getFontAwesomeIcon(_selectedCategory.icon),
                                  size: 16,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  FontAwesomeIcons.list,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              var newCategory = await getCategoryCreation(context);
                              setState(() {
                                _selectedCategory = newCategory;
                              });
                            },
                            icon: const Icon(
                              FontAwesomeIcons.plus,
                              size: 16,
                              color: Colors.grey,
                            )
                          ),
                          hintText: 'Category',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), borderSide: BorderSide.none),
                        ),
                      ),
                      Container(
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.builder(
                            itemCount: state.categories.length,
                            itemBuilder: (context, int i) {
                              return Card(
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = state.categories[i];
                                    });
                                  },
                                  leading: state.categories[i].icon.isNotEmpty
                                    ? Icon(
                                        _getFontAwesomeIcon(state.categories[i].icon),
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : const Icon(
                                        FontAwesomeIcons.list,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                  title: Text(state.categories[i].name),
                                  tileColor: Color(int.parse(state.categories[i].color)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          )
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: _titleController,
                        textAlignVertical: TextAlignVertical.center,
                        readOnly: true,
                        onTap: () async {
                          DateTime? newDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));

                          if (newDate != null) {
                            setState(() {
                              _selectedDate = newDate;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            FontAwesomeIcons.clock,
                            size: 16,
                            color: Colors.grey,
                          ),
                          hintText: 'Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: kToolbarHeight,
                        child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TextButton(
                              onPressed: () {
                                setState(() {
                                  widget.initialExpense?.total = double.parse(_amountController.text);
                                  widget.initialExpense?.title = _titleController.text;
                                  widget.initialExpense?.date = _selectedDate;
                                  widget.initialExpense?.category = _selectedCategory;
                                });

                                context.read<CreateExpenseBloc>().add(CreateExpense(widget.initialExpense!));
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Add Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Future<Category> getCategoryCreation(BuildContext context) async {
    // TODO: Implement category creation dialog
    return Category.empty;
  }

  IconData _getFontAwesomeIcon(String iconName) {
    switch (iconName) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'shopping-bag':
        return FontAwesomeIcons.shoppingBag;
      case 'car':
        return FontAwesomeIcons.car;
      case 'film':
        return FontAwesomeIcons.film;
      case 'file-invoice-dollar':
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'heartbeat':
        return FontAwesomeIcons.heartbeat;
      case 'plane':
        return FontAwesomeIcons.plane;
      case 'graduation-cap':
        return FontAwesomeIcons.graduationCap;
      default:
        return FontAwesomeIcons.question;
    }
  }
}
