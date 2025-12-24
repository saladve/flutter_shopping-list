import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseRecord {
  final String id;
  final String name;
  final double price;
  final String location;
  final DateTime purchaseDate;
  final int quantity;
  final String? notes;
  final String? category;

  const PurchaseRecord({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.purchaseDate,
    this.quantity = 1,
    this.notes,
    this.category,
  });

  PurchaseRecord copyWith({
    String? id,
    String? name,
    double? price,
    String? location,
    DateTime? purchaseDate,
    int? quantity,
    String? notes,
    String? category,
  }) {
    return PurchaseRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      location: location ?? this.location,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  factory PurchaseRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return PurchaseRecord(
      id: id,
      name: data['name'] ?? 'No Name',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      purchaseDate: data['purchaseDate'] is Timestamp
          ? (data['purchaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'location': location,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'quantity': quantity,
      'notes': notes,
      'category': category,
      'createdAt': Timestamp.now(),
    };
  }
}
