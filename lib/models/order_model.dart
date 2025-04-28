// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodOrder {
  final String id;
  final String userId;
  final String item;
  final double price;
  final DateTime date;

  FoodOrder({
    required this.id,
    required this.userId,
    required this.item,
    required this.price,
    required this.date,
  });

  factory FoodOrder.fromMap(Map<String, dynamic> map, String docId) {
    return FoodOrder(
      id: docId,
      userId: map['userId'],
      item: map['item'],
      price: (map['price'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'item': item,
      'price': price,
      'date': Timestamp.fromDate(date),
    };
  }
}
