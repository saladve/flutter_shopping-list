import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String? location;
  final String? category;
  final bool isCompleted;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.location,
    this.category,
    this.isCompleted = false,
  });

  // copyWith メソッドも忘れずに更新してください
  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? location,
    String? category,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ShoppingItem.fromFirestore(
      Map<String, dynamic> data,
      String id,
      ) {
    return ShoppingItem(
      id: id,
      name: data['name'] ?? 'No Name',
      quantity: data['quantity'] ?? 1,
      location: data['location'],
      category: data['category'],
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // 💡 Firestoreに書き込むためのMap変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'location': location,
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.now(), // 作成日時を追加
    };
  }
}