import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<Receipt> _receipts = [];

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final databaseService = context.read<DatabaseService>();
    final receipts = await databaseService.getAllReceipts();
    setState(() {
      _receipts = receipts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final databaseService = context.read<DatabaseService>();
              final csv = await databaseService.exportToCsv();
              // TODO: Implement file saving
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export functionality coming soon')),
                );
              }
            },
          ),
        ],
      ),
      body: _receipts.isEmpty
          ? const Center(
              child: Text('No receipts yet. Tap the camera button to add one.'),
            )
          : ListView.builder(
              itemCount: _receipts.length,
              itemBuilder: (context, index) {
                final receipt = _receipts[index];
                return Dismissible(
                  key: Key(receipt.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    final databaseService = context.read<DatabaseService>();
                    await databaseService.deleteReceipt(receipt.id);
                    setState(() {
                      _receipts.removeAt(index);
                    });
                  },
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(receipt.vendor),
                    subtitle: Text(
                      '${receipt.category} - ${receipt.date.toString().split(' ')[0]}',
                    ),
                    trailing: Text(
                      '\$${receipt.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // TODO: Show receipt details
                    },
                  ),
                );
              },
            ),
    );
  }
} 