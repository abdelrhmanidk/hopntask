import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class ExportService {
  final LocalStorageService _localStorageService;

  ExportService({LocalStorageService? localStorageService})
      : _localStorageService = localStorageService ?? LocalStorageService();

  Future<void> exportToCSV() async {
    try {
      // Get expenses from local storage
      final expenses = await _localStorageService.getExpenses();
      
      // Create CSV content
      final csvContent = StringBuffer();
      
      // Add header
      csvContent.writeln('Date,Title,Category,Total,Items');
      
      // Add data rows
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (final expense in expenses) {
        final items = expense.items.map((item) => '${item['name']} (\$${item['price']})').join('; ');
        csvContent.writeln(
          '${dateFormat.format(expense.date)},'
          '${_escapeCsvField(expense.title)},'
          '${_escapeCsvField(expense.category.name)},'
          '${expense.total},'
          '${_escapeCsvField(items)}',
        );
      }
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/expenses_export.csv');
      
      // Write to file
      await file.writeAsString(csvContent.toString());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Expenses Export',
      );
    } catch (e) {
      print('Error exporting to CSV: $e');
      rethrow;
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Escape quotes by doubling them and wrap in quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
} 