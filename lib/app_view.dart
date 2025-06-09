import 'package:flutter/cupertino.dart';
import 'package:hopntask/screens/home/views/home_screen.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: HomeScreen(),
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
      ),
    );
  }
}
