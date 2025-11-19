import 'package:flutter/foundation.dart';

@immutable
class ShoppingItem {
  final String name;
  final int quantity;
  final bool isCompleted;

  const ShoppingItem({
    required this.name,
    this.quantity = 1,
    this.isCompleted = false,
  });

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
