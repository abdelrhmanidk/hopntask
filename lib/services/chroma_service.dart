import 'package:http/http.dart' as http;
import 'dart:convert';

class ChromaService {
  final String baseUrl;
  final String collectionName;
  final Map<String, String> headers;
  final http.Client _client = http.Client();
  bool _isConnected = false;

  ChromaService({
    this.baseUrl = 'http://192.168.1.77:8007',
    this.collectionName = 'receipts',
    Map<String, String>? headers,
  }) : headers = headers ?? {
    'Content-Type': 'application/json',
  };

  Future<bool> _checkConnection() async {
    if (_isConnected) return true;
    
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      print('ChromaDB connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  // Add a receipt to the collection
  Future<void> addReceipt({
    required String id,
    required String vendor,
    required double total,
    required DateTime date,
    required List<Map<String, String>> items,
    required String category,
  }) async {
    if (!await _checkConnection()) {
      print('ChromaDB not connected, skipping receipt storage');
      return;
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/receipts/store'),
        headers: headers,
        body: jsonEncode({
          'id': id,
          'title': vendor,
          'total': total,
          'date': date.toIso8601String(),
          'category': category,
          'items': items,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add receipt: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding receipt to ChromaDB: $e');
      rethrow;
    }
  }

  // Search for similar receipts
  Future<List<Map<String, dynamic>>> searchReceipts(String query) async {
    if (!await _checkConnection()) {
      print('ChromaDB not connected, returning empty results');
      return [];
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/receipts/search'),
        headers: headers,
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to search receipts: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } catch (e) {
      print('Error searching receipts in ChromaDB: $e');
      return [];
    }
  }

  // Get all receipts
  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    if (!await _checkConnection()) {
      print('ChromaDB not connected, returning empty results');
      return [];
    }

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/receipts'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get receipts: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['receipts']);
    } catch (e) {
      print('Error getting receipts from ChromaDB: $e');
      return [];
    }
  }

  // Delete a receipt
  Future<void> deleteReceipt(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/receipts/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete receipt: ${response.body}');
    }
  }
} 