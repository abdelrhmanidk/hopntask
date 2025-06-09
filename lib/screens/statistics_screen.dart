import 'package:flutter/cupertino.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Statistics'),
      ),
      child: SafeArea(
        child: Center(
          child: Text(
            'Statistics Coming Soon',
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