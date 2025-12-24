import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String? location;
  final String? category;
  final DateTime? dueDate;
  final bool isCompleted;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.location,
    this.category,
    this.dueDate,
    this.isCompleted = false,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? location,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ShoppingItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ShoppingItem(
      id: id,
      name: data['name'] ?? 'No Name',
      quantity: data['quantity'] ?? 1,
      location: data['location'],
      category: data['category'],
      dueDate: data['dueDate'] is Timestamp
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'location': location,
      'category': category,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.now(),
    };
  }
}
