class ShoppingItem {
  final String name;
  final int quantity;
  final String? location;
  final String? category;
  final bool isCompleted;

  const ShoppingItem({
    required this.name,
    this.quantity = 1,
    this.location,
    this.category,
    this.isCompleted = false,
  });

  // copyWith メソッドも忘れずに更新してください
  ShoppingItem copyWith({
    String? name,
    int? quantity,
    String? location,
    String? category,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}