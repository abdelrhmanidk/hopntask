import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:hopntask/screens/add_expense/views/add_expense.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hopntask/services/local_storage_service.dart';
import 'package:hopntask/services/chroma_service.dart';
import 'package:intl/intl.dart';

class ManualExpenseForm extends StatefulWidget {
  final Function(Expense) onExpenseAdded;

  const ManualExpenseForm({
    super.key,
    required this.onExpenseAdded,
  });

  @override
  State<ManualExpenseForm> createState() => _ManualExpenseFormState();
}

class _ManualExpenseFormState extends State<ManualExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _isLoading = false;
  bool _isIncome = false;
  bool _isSubmitting = false;
  final List<Map<String, String>> _items = [];
  final _localStorageService = LocalStorageService();
  final _chromaService = ChromaService();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: _selectedDate,
            mode: CupertinoDatePickerMode.date,
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDate) {
              setState(() => _selectedDate = newDate);
            },
          ),
        ),
      ),
    );
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty || _itemPriceController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please fill in both item name and price'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final price = double.tryParse(_itemPriceController.text);
    if (price == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a valid price'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _items.add({
        'name': _itemNameController.text,
        'price': price.toString(),
      });
      _itemNameController.clear();
      _itemPriceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    if (_selectedCategory == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please select a category'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final expense = Expense(
        id: const Uuid().v4(),
        title: _titleController.text,
        total: _isIncome ? -amount : amount,
        date: _selectedDate,
        category: _selectedCategory!,
        items: _items,
      );

      // Save using CreateExpenseBloc
      context.read<CreateExpenseBloc>().add(CreateExpense(expense));

      // Send to backend
      final requestBody = {
        'title': expense.title,
        'total': expense.total,
        'date': expense.date.toIso8601String().split('T')[0],
        'items': _items.map((item) => {
          'name': item['name'] ?? '',
          'price': double.tryParse(item['price'] ?? '0.0') ?? 0.0
        }).toList(),
        'raw_text': 'Manual Entry: ${expense.title} - ${expense.total} - ${expense.category.name}',
      };
      print('Sending request to backend: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('http://192.168.1.77:8007/receipts/store'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to store receipt: ${response.body}');
      }

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );

      // Notify parent and pop
      widget.onExpenseAdded(expense);
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting form: $e');
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Manual Expense'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Save'),
          onPressed: _isLoading ? null : _submitForm,
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {},
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // Type Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () => setState(() => _isIncome = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isIncome ? CupertinoColors.activeBlue.withOpacity(0.1) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  color: !_isIncome ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                                  fontWeight: !_isIncome ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () => setState(() => _isIncome = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isIncome ? CupertinoColors.activeBlue.withOpacity(0.1) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  color: _isIncome ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                                  fontWeight: _isIncome ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Basic Information Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _titleController,
                          placeholder: 'Store Name',
                          padding: const EdgeInsets.all(16),
                          style: const TextStyle(
                            color: CupertinoColors.label,
                          ),
                          decoration: null,
                          placeholderStyle: const TextStyle(
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey4,
                        ),
                        CupertinoTextField(
                          controller: _amountController,
                          placeholder: 'Total Amount',
                          padding: const EdgeInsets.all(16),
                          style: const TextStyle(
                            color: CupertinoColors.label,
                          ),
                          decoration: null,
                          placeholderStyle: const TextStyle(
                            color: CupertinoColors.systemGrey,
                          ),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: CupertinoColors.label,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date and Category Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    color: CupertinoColors.label,
                                    fontSize: 17,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      color: CupertinoColors.systemGrey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey4,
                        ),
                        BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
                          builder: (context, state) {
                            if (state is GetCategoriesSuccess) {
                              final categories = state.categories;
                              if (categories.isEmpty) {
                                return const Center(
                                  child: Text('No categories available'),
                                );
                              }
                              if (_selectedCategory == null) {
                                _selectedCategory = categories.first;
                              }
                              return GestureDetector(
                                onTap: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (BuildContext context) => Container(
                                      height: 216,
                                      padding: const EdgeInsets.only(top: 6.0),
                                      margin: EdgeInsets.only(
                                        bottom: MediaQuery.of(context).viewInsets.bottom,
                                      ),
                                      color: CupertinoColors.systemBackground.resolveFrom(context),
                                      child: SafeArea(
                                        top: false,
                                        child: CupertinoPicker(
                                          itemExtent: 32.0,
                                          onSelectedItemChanged: (int index) {
                                            setState(() {
                                              _selectedCategory = categories[index];
                                            });
                                          },
                                          children: categories.map((category) {
                                            return Center(
                                              child: Text(category.name),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Category',
                                        style: TextStyle(
                                          color: CupertinoColors.label,
                                          fontSize: 17,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            _selectedCategory?.name ?? 'Select Category',
                                            style: const TextStyle(
                                              color: CupertinoColors.systemGrey,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            CupertinoIcons.chevron_right,
                                            color: CupertinoColors.systemGrey,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const Center(child: CupertinoActivityIndicator());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey4,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: _itemNameController,
                                  placeholder: 'Item Name',
                                  padding: const EdgeInsets.all(12),
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                  ),
                                  decoration: null,
                                  placeholderStyle: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CupertinoTextField(
                                  controller: _itemPriceController,
                                  placeholder: 'Price',
                                  padding: const EdgeInsets.all(12),
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                  ),
                                  decoration: null,
                                  placeholderStyle: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        color: CupertinoColors.label,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton(
                                padding: const EdgeInsets.all(12),
                                color: CupertinoColors.activeBlue,
                                borderRadius: BorderRadius.circular(8),
                                onPressed: _addItem,
                                child: const Icon(
                                  CupertinoIcons.add,
                                  size: 20,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_items.isNotEmpty) ...[
                          Container(
                            height: 0.5,
                            color: CupertinoColors.systemGrey4,
                          ),
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name']!,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500,
                                                color: CupertinoColors.label,
                                              ),
                                            ),
                                            Text(
                                              '\$${item['price']}',
                                              style: const TextStyle(
                                                color: CupertinoColors.systemGrey,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _removeItem(index),
                                        child: const Icon(
                                          CupertinoIcons.delete,
                                          color: CupertinoColors.destructiveRed,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < _items.length - 1)
                                  Container(
                                    height: 0.5,
                                    color: CupertinoColors.systemGrey4,
                                  ),
                              ],
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 