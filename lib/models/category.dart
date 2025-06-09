class Category {
  final String id;
  final String name;
  final String color;
  final String icon;
  final bool isSuggested;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isSuggested = false,
  });

  static Category get empty => Category(
    id: '',
    name: '',
    color: '0xFF000000',
    icon: '',
    isSuggested: false,
  );

  static List<Category> get defaultCategories => [
    Category(
      id: '1',
      name: 'Food & Dining',
      color: '0xFFFF9500', // iOS Orange
      icon: 'utensils',
      isSuggested: true,
    ),
    Category(
      id: '2',
      name: 'Shopping',
      color: '0xFF5856D6', // iOS Purple
      icon: 'shopping-bag',
      isSuggested: true,
    ),
    Category(
      id: '3',
      name: 'Transportation',
      color: '0xFF34C759', // iOS Green
      icon: 'car',
      isSuggested: true,
    ),
    Category(
      id: '4',
      name: 'Entertainment',
      color: '0xFFFF2D55', // iOS Pink
      icon: 'film',
      isSuggested: true,
    ),
    Category(
      id: '5',
      name: 'Bills & Utilities',
      color: '0xFF007AFF', // iOS Blue
      icon: 'file-invoice-dollar',
      isSuggested: true,
    ),
    Category(
      id: '6',
      name: 'Health & Fitness',
      color: '0xFF5AC8FA', // iOS Light Blue
      icon: 'heartbeat',
      isSuggested: true,
    ),
    Category(
      id: '7',
      name: 'Travel',
      color: '0xFFFF3B30', // iOS Red
      icon: 'plane',
      isSuggested: true,
    ),
    Category(
      id: '8',
      name: 'Education',
      color: '0xFFAF52DE', // iOS Deep Purple
      icon: 'graduation-cap',
      isSuggested: true,
    ),
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'isSuggested': isSuggested,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      isSuggested: json['isSuggested'] as bool? ?? false,
    );
  }
} 