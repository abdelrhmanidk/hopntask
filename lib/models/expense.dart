import 'package:hopntask/models/category.dart';

class Expense {
  final String id;
  String title;
  double total;
  DateTime date;
  Category category;
  List<Map<String, String>> items;
  String? time;

  Expense({
    required this.id,
    required this.title,
    required this.total,
    required this.date,
    required this.category,
    required this.items,
    this.time,
  });

  static Expense get empty => Expense(id: '', title: '', total: 0.0, date: DateTime.now(), category: Category.empty, items: [], time: null);

  // Create a copy of the expense with optional updates
  Expense copyWith({
    String? id,
    String? title,
    double? total,
    DateTime? date,
    Category? category,
    List<Map<String, String>>? items,
    String? time,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      total: total ?? this.total,
      date: date ?? this.date,
      category: category ?? this.category,
      items: items ?? this.items,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'total': total,
      'date': date.toIso8601String(),
      'category': category.toJson(),
      'items': items,
      'time': time,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      total: json['total'].toDouble(),
      date: DateTime.parse(json['date']),
      category: Category.fromJson(json['category']),
      items: List<Map<String, String>>.from(json['items']),
      time: json['time'],
    );
  }
} 