import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopntask/data/local_expense_repo.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:hopntask/screens/home/views/main_screen.dart';
import 'package:hopntask/screens/chat_screen.dart';
import 'package:hopntask/screens/settings_screen.dart';
import 'package:hopntask/widgets/animated_fab.dart';
import '../../stats/stats.dart';
import 'package:provider/provider.dart';
import 'package:hopntask/services/ocr_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  late Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetExpensesBloc, GetExpensesState>(
      builder: (context, state) {
        if(state is GetExpensesSuccess) {
          return Scaffold(
            bottomNavigationBar: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BottomNavigationBar(
                onTap: (value) {
                  setState(() {
                    index = value;
                  });
                },
                showSelectedLabels: false,
                showUnselectedLabels: false,
                elevation: 3,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.house, color: index == 0 ? selectedItem : unselectedItem),
                    label: 'Home'
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.chartLine, color: index == 1 ? selectedItem : unselectedItem),
                    label: 'Stats'
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.message, color: index == 2 ? selectedItem : unselectedItem),
                    label: 'Chat'
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.gear, color: index == 3 ? selectedItem : unselectedItem),
                    label: 'Settings'
                  ),
                ]
              ),
            ),
            floatingActionButton: index == 0 ? AnimatedFAB(
              onExpenseAdded: (expense) {
                setState(() {
                  state.expenses.insert(0, expense);
                });
              },
              ocrService: RepositoryProvider.of<OCRService>(context),
            ) : null,
            body: index == 0 
              ? MainScreen(state.expenses)
              : index == 1
                ? const StatScreen()
                : index == 2
                  ? const ChatScreen()
                  : const SettingsScreen(),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    );
  }
}
