import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:uuid/uuid.dart';

Future getCategoryCreation(BuildContext context) {
  // List of available icons with their FontAwesome equivalents
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

  return showDialog(
    context: context,
    builder: (ctx) {
      bool isExpended = false;
      String iconSelected = '';
      Color categoryColor = Colors.white;
      TextEditingController categoryNameController = TextEditingController();
      TextEditingController categoryIconController = TextEditingController();
      TextEditingController categoryColorController = TextEditingController();
      bool isLoading = false;
      Category category = Category.empty;

      return BlocProvider.value(
        value: context.read<CreateCategoryBloc>(),
        child: StatefulBuilder(
          builder: (ctx, setState) {
          return BlocListener<CreateCategoryBloc, CreateCategoryState>(
            listener: (context, state) {
              if(state is CreateCategorySuccess) {
                Navigator.pop(ctx, category);
              } else if (state is CreateCategoryLoading) {
                setState(() {
                  isLoading = true;
                });
              }
            },
            child: AlertDialog(
              title: const Text('Create a Category'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: categoryNameController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
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
                        final isSelected = iconSelected == _getIconName(icon['icon']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              iconSelected = _getIconName(icon['icon']);
                              categoryColor = icon['color'];
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
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: categoryColorController,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx2) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ColorPicker(
                                    pickerColor: categoryColor,
                                    onColorChanged: (value) {
                                      setState(() {
                                        categoryColor = value;
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx2);
                                        },
                                        style: TextButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        child: const Text(
                                          'Save Color',
                                          style: TextStyle(fontSize: 22, color: Colors.white),
                                        )),
                                  )
                                ],
                              ),
                            );
                          }
                        );
                      },
                      textAlignVertical: TextAlignVertical.center,
                      readOnly: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: categoryColor,
                        hintText: 'Color',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: kToolbarHeight,
                      child: isLoading == true
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : TextButton(
                            onPressed: () {
                              if (iconSelected.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select an icon'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              // Create Category Object and POP
                              setState(() {
                                category = Category(
                                  id: const Uuid().v1(),
                                  name: categoryNameController.text,
                                  icon: iconSelected,
                                  color: categoryColor.value.toString(),
                                );
                              });
                              
                              context.read<CreateCategoryBloc>().add(CreateCategory(
                                name: category.name,
                                icon: category.icon,
                                color: category.color,
                              ));
                            },
                            style: TextButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 22, color: Colors.white),
                            )
                          ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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