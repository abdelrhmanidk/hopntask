import 'package:flutter/cupertino.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Health'),
      ),
      child: SafeArea(
        child: Center(
          child: Text(
            'Health Features Coming Soon',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
} 