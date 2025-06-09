import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:hopntask/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:hopntask/screens/add_expense/views/add_expense.dart';
import 'package:hopntask/screens/add_expense/views/manual_expense_form.dart';
import 'package:hopntask/data/local_expense_repo.dart';
import 'package:hopntask/services/receipt_processor.dart';
import 'package:hopntask/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/services/local_storage_service.dart';

class AnimatedFAB extends StatefulWidget {
  final Function(Expense) onExpenseAdded;
  final OCRService ocrService;

  const AnimatedFAB({
    super.key,
    required this.onExpenseAdded,
    required this.ocrService,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isProcessing = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _handleReceiptCapture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _handleReceiptCapture(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Manual Entry'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualExpenseForm(
                      onExpenseAdded: widget.onExpenseAdded,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReceiptCapture(ImageSource source) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isExpanded = false;
      _controller.reverse();
    });

    try {
      final imageFile = await widget.ocrService.pickImage(
        source: source,
        context: context,
      );
      if (imageFile == null) {
        print('No image selected');
        return;
      }

      print('Image picked successfully: ${imageFile.path}');
      
      if (!mounted) return;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      print('Processing receipt...');
      final expense = await widget.ocrService.processReceipt(imageFile);
      print('Receipt processed successfully');

      if (!mounted) return;
      
      // Hide loading indicator
      Navigator.pop(context);

      // Get all categories from the BLoC
      final allCategoriesState = BlocProvider.of<GetCategoriesBloc>(context).state;
      List<Category> allCategories = [];
      if (allCategoriesState is GetCategoriesSuccess) {
        allCategories = allCategoriesState.categories;
      }
      // Ensure the suggested category is in the list, or add it if not
      if (!allCategories.contains(expense.category)) {
        allCategories.add(expense.category); // Add suggested category if it's new
      }
      // Sort categories to put suggested at top, then alphabetically
      allCategories.sort((a, b) {
        if (a.isSuggested && !b.isSuggested) return -1;
        if (!a.isSuggested && b.isSuggested) return 1;
        return a.name.compareTo(b.name);
      });

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          Expense currentExpense = expense; // Use a mutable copy for the sheet's state

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInSheet) {
              return DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Image preview
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      // Receipt details
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Vendor', currentExpense.title),
                              _buildDetailRow('Total', '\$${currentExpense.total.toStringAsFixed(2)}'),
                              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(currentExpense.date)),
                              // Category dropdown
                              _buildCategoryDropdown(context, currentExpense.category, allCategories, (newCategory) {
                                setStateInSheet(() { // Use setStateInSheet to update state within the sheet
                                  currentExpense.category = newCategory;
                                });
                              }),
                              if (currentExpense.time != null) ...[
                                const SizedBox(height: 16),
                                _buildDetailRow('Time', currentExpense.time!),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        widget.onExpenseAdded(currentExpense); // Pass the potentially updated expense
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Add Expense'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e, stackTrace) {
      print('Error in _handleReceiptCapture: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        Navigator.pop(context); // Hide loading indicator
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to process receipt: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded) ...[
                _buildActionButton(
                  icon: FontAwesomeIcons.camera,
                  label: 'Take Photo',
                  onTap: () {
                    _toggleExpanded();
                    _handleReceiptCapture(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: FontAwesomeIcons.image,
                  label: 'Gallery',
                  onTap: () {
                    _toggleExpanded();
                    _handleReceiptCapture(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  label: 'Manual Entry',
                  onTap: () {
                    _toggleExpanded();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ManualExpenseForm(
                          onExpenseAdded: widget.onExpenseAdded,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleExpanded,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _rotateAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * pi,
                        child: Icon(
                          _isExpanded ? CupertinoIcons.xmark : CupertinoIcons.plus,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: CupertinoColors.activeBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.label,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, Category initialCategory, List<Category> allCategories, Function(Category) onChanged) {
    return BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
      builder: (context, state) {
        // Use default categories if none are provided
        final categories = state is GetCategoriesSuccess 
            ? state.categories 
            : Category.defaultCategories;
        print('Building category dropdown with ${categories.length} categories'); // Debug print
        print('Categories: ${categories.map((c) => c.name).join(', ')}'); // Debug print

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      print('Opening category selection modal'); // Debug print
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Select Category',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    print('Building category item: ${category.name} with icon: ${category.icon}'); // Debug print
                                    return GestureDetector(
                                      onTap: () {
                                        print('Selected category: ${category.name}'); // Debug print
                                        onChanged(category);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(category.color)).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: initialCategory.id == category.id
                                                ? Color(int.parse(category.color))
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _getFontAwesomeIcon(category.icon),
                                              size: 24,
                                              color: Color(int.parse(category.color)),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              category.name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(int.parse(category.color)),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(int.parse(initialCategory.color)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(int.parse(initialCategory.color)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (initialCategory.icon.isNotEmpty)
                            Icon(
                              _getFontAwesomeIcon(initialCategory.icon),
                              size: 20,
                              color: Color(int.parse(initialCategory.color)),
                            )
                          else
                            const Icon(Icons.category, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            initialCategory.name.isEmpty ? 'Select Category' : initialCategory.name,
                            style: TextStyle(
                              color: Color(int.parse(initialCategory.color)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Color(int.parse(initialCategory.color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFontAwesomeIcon(String iconName) {
    print('Getting icon for: $iconName'); // Debug print
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
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'shopping':
        return FontAwesomeIcons.shoppingBag;
      case 'transport':
        return FontAwesomeIcons.car;
      case 'entertainment':
        return FontAwesomeIcons.film;
      case 'bills':
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'health':
        return FontAwesomeIcons.heartbeat;
      case 'travel':
        return FontAwesomeIcons.plane;
      case 'education':
        return FontAwesomeIcons.graduationCap;
      default:
        print('Unknown icon name: $iconName'); // Debug print
        return FontAwesomeIcons.question;
    }
  }

  Future<Category?> getCategoryCreation(BuildContext context) async {
    final nameController = TextEditingController();
    String selectedIcon = 'utensils'; // Default icon
    Color selectedColor = const Color(0xFFFF9500); // Default iOS Orange
    bool isLoading = false;

    // List of available icons
    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'Food', 'icon': FontAwesomeIcons.utensils, 'color': const Color(0xFFFF9500)},
      {'name': 'Shopping', 'icon': FontAwesomeIcons.shoppingBag, 'color': const Color(0xFF5856D6)},
      {'name': 'Transport', 'icon': FontAwesomeIcons.car, 'color': const Color(0xFF34C759)},
      {'name': 'Entertainment', 'icon': FontAwesomeIcons.film, 'color': const Color(0xFFFF2D55)},
      {'name': 'Bills', 'icon': FontAwesomeIcons.fileInvoiceDollar, 'color': const Color(0xFF007AFF)},
      {'name': 'Health', 'icon': FontAwesomeIcons.heartbeat, 'color': const Color(0xFF5AC8FA)},
      {'name': 'Travel', 'icon': FontAwesomeIcons.plane, 'color': const Color(0xFFFF3B30)},
      {'name': 'Education', 'icon': FontAwesomeIcons.graduationCap, 'color': const Color(0xFFAF52DE)},
    ];

    return showDialog<Category>(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => CreateCategoryBloc(
          expenseRepository: LocalStorageService(),
        ),
        child: BlocListener<CreateCategoryBloc, CreateCategoryState>(
          listener: (context, state) {
            if (state is CreateCategorySuccess) {
              Navigator.pop(context, state.category);
            } else if (state is CreateCategoryLoading) {
              isLoading = true;
            }
          },
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Create Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                      controller: nameController,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIcon == _getIconName(icon['icon']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = _getIconName(icon['icon']);
                              selectedColor = icon['color'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: icon['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? icon['color'] : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon['icon'],
                              color: icon['color'],
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: isLoading ? null : () {
                            if (nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a category name'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            context.read<CreateCategoryBloc>().add(
                              CreateCategory(
                                name: nameController.text,
                                color: selectedColor.value.toString(),
                                icon: selectedIcon,
                              ),
                            );
                          },
                          child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == FontAwesomeIcons.utensils) return 'utensils';
    if (icon == FontAwesomeIcons.shoppingBag) return 'shopping-bag';
    if (icon == FontAwesomeIcons.car) return 'car';
    if (icon == FontAwesomeIcons.film) return 'film';
    if (icon == FontAwesomeIcons.fileInvoiceDollar) return 'file-invoice-dollar';
    if (icon == FontAwesomeIcons.heartbeat) return 'heartbeat';
    if (icon == FontAwesomeIcons.plane) return 'plane';
    if (icon == FontAwesomeIcons.graduationCap) return 'graduation-cap';
    return 'utensils';
  }
} 