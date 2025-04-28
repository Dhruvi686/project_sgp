class EventOrder {
  final String userId;
  final String facultyName;
  final String foodType;
  final List<String> meals;
  final String sweet;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final DateTime timestamp;
  final String status;

  EventOrder({
    required this.userId,
    required this.facultyName,
    required this.foodType,
    required this.meals,
    required this.sweet,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'facultyName': facultyName,
      'foodType': foodType,
      'meals': meals,
      'sweet': sweet,
      'startDate': startDate,
      'endDate': endDate,
      'totalPrice': totalPrice,
      'timestamp': timestamp,
      'status': status,
    };
  }
}
