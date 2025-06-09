import 'package:equatable/equatable.dart';

class Receipt extends Equatable {
  final String id;
  final String vendor;
  final double total;
  final DateTime date;
  final String category;
  final String imagePath;
  final Map<String, dynamic> extractedData;

  const Receipt({
    required this.id,
    required this.vendor,
    required this.total,
    required this.date,
    required this.category,
    required this.imagePath,
    required this.extractedData,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      vendor: json['vendor'] as String,
      total: (json['total'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      imagePath: json['imagePath'] as String,
      extractedData: json['extractedData'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendor,
      'total': total,
      'date': date.toIso8601String(),
      'category': category,
      'imagePath': imagePath,
      'extractedData': extractedData,
    };
  }

  @override
  List<Object?> get props => [id, vendor, total, date, category, imagePath, extractedData];
} 