import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hopntask/models/expense.dart';
import 'package:hopntask/models/category.dart';
import 'package:hopntask/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptProcessor {
  final OCRService _ocrService;

  ReceiptProcessor(this._ocrService);

  Future<File?> pickImage({
    required ImageSource source,
    required BuildContext context,
  }) async {
    return await _ocrService.pickImage(
      source: source,
      context: context,
    );
  }

  Future<Expense> processReceipt(File imageFile) async {
    try {
      return await _ocrService.processReceipt(imageFile);
    } catch (e) {
      print('Error in ReceiptProcessor: $e');
      rethrow;
    }
  }

  void dispose() {
    // No explicit dispose needed
  }
} 