import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/services/chroma_service.dart';
import 'package:http/http.dart' as http;

class OCRService {
  final _imagePicker = ImagePicker();
  final ChromaService _chromaService;
  final _uuid = const Uuid();
  final String _backendUrl = 'http://192.168.1.77:8005'; // Update this if needed

  OCRService({ChromaService? chromaService})
      : _chromaService = chromaService ?? ChromaService();

  Future<File?> pickImage({
    required ImageSource source,
    required BuildContext context,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (file == null) return null;
      return File(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
      return null;
    }
  }

  Future<Expense> processReceipt(File imageFile) async {
    try {
      print('Starting receipt processing...');

      // Step 1: Health check
      try {
        final healthResponse = await http.get(Uri.parse('$_backendUrl/health'));
        if (healthResponse.statusCode != 200) {
          throw Exception('Backend health check failed: ${healthResponse.statusCode}');
        }
        print('Backend health check passed');
      } catch (e) {
        print('Backend health check failed: $e');
        throw Exception('Cannot connect to backend server. Please make sure it is running.');
      }

      // Step 2: Read image as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('Image converted to base64');

      // Step 3: Send to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/process-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'image': base64Image}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );

      if (response.statusCode != 200) {
        print('Backend error: ${response.statusCode} - ${response.body}');
        throw Exception('Backend error: ${response.statusCode}');
      }

      final result = jsonDecode(response.body);
      print('Received response from backend: $result');

      // ✅ Safe date parsing
      final rawDate = result['date'];
      final parsedDate = (rawDate != null && rawDate != 'Unknown')
          ? DateTime.tryParse(rawDate) ?? DateTime.now()
          : DateTime.now();

      final expense = Expense(
        id: _uuid.v4(),
        title: result['vendor_name'] ?? 'Unknown Vendor',
        total: (result['total_amount'] as num?)?.toDouble() ?? 0.0,
        date: parsedDate,
        category: Category.empty,
        items: [],
      );

      // Step 4: Try to store in ChromaDB
      try {
        await _chromaService.addReceipt(
          id: expense.id,
          vendor: expense.title,
          total: expense.total,
          date: expense.date,
          items: expense.items,
          category: expense.category.name,
        );
        print('Successfully stored receipt in ChromaDB');
      } catch (e) {
        print('Warning: Failed to store receipt in ChromaDB: $e');
      }

      return expense;
    } catch (e) {
      print('Error processing receipt: $e');
      rethrow;
    }
  }
}
