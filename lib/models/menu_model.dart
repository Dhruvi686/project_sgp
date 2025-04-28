// lib/models/menu_model.dart
class DailyMenu {
  final String id;
  final String item;
  final double price;

  DailyMenu({required this.id, required this.item, required this.price});

  factory DailyMenu.fromMap(Map<String, dynamic> map, String docId) {
    return DailyMenu(
      id: docId,
      item: map['item'],
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'price': price,
    };
  }
}
