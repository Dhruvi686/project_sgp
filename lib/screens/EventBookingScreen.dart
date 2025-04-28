import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventBookingScreen extends StatefulWidget {
  const EventBookingScreen({super.key});

  @override
  State<EventBookingScreen> createState() => _EventBookingScreenState();
}

class _EventBookingScreenState extends State<EventBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String foodType = 'Regular';
  String sweet = '';
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedMeals = [];
  double mealPrice = 50.0;

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void toggleMeal(String meal) {
    setState(() {
      if (selectedMeals.contains(meal)) {
        selectedMeals.remove(meal);
      } else {
        selectedMeals.add(meal);
      }
    });
  }

  double get totalPrice {
    if (startDate == null || endDate == null || selectedMeals.isEmpty) return 0;
    int days = endDate!.difference(startDate!).inDays + 1;
    return days * selectedMeals.length * mealPrice;
  }

  Future<void> placeEventOrder() async {
    if (!_formKey.currentState!.validate() ||
        startDate == null ||
        endDate == null ||
        selectedMeals.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userData = (await FirebaseFirestore.instance.collection('users').doc(user!.uid).get()).data();

    // Check for overlapping events
    final overlappingEvents = await FirebaseFirestore.instance
        .collection('event_orders')
        .where('userId', isEqualTo: user!.uid)
        .get();

    for (var doc in overlappingEvents.docs) {
      final data = doc.data();
      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();

      final overlaps = startDate!.isBefore(existingEnd.add(const Duration(days: 1))) &&
                       endDate!.isAfter(existingStart.subtract(const Duration(days: 1)));

      if (overlaps) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have an event booked in this date range!')),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection('event_orders').add({
      'userId': user.uid,
      'facultyName': userData?['name'] ?? '',
      'department': userData?['department'] ?? '',
      'foodType': foodType,
      'sweet': sweet,
      'startDate': startDate,
      'endDate': endDate,
      'meals': selectedMeals,
      'status': 'pending_hod_approval',
      'timestamp': Timestamp.now(),
      'totalPrice': totalPrice,
      'expired': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event order placed successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Event Food')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField(
                value: foodType,
                decoration: const InputDecoration(labelText: 'Select Food Type'),
                items: ['Regular', 'Punjabi', 'Gujarati'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => foodType = val!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Sweet requirement'),
                onChanged: (val) => sweet = val,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, true),
                      child: Text(startDate == null
                          ? 'Start Date'
                          : DateFormat('dd/MM/yyyy').format(startDate!)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickDate(context, false),
                      child: Text(endDate == null
                          ? 'End Date'
                          : DateFormat('dd/MM/yyyy').format(endDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Select Meals:'),
              CheckboxListTile(
                value: selectedMeals.contains('Breakfast'),
                title: const Text('Breakfast'),
                onChanged: (_) => toggleMeal('Breakfast'),
              ),
              CheckboxListTile(
                value: selectedMeals.contains('Lunch'),
                title: const Text('Lunch'),
                onChanged: (_) => toggleMeal('Lunch'),
              ),
              CheckboxListTile(
                value: selectedMeals.contains('Dinner'),
                title: const Text('Dinner'),
                onChanged: (_) => toggleMeal('Dinner'),
              ),
              const SizedBox(height: 10),
              Text('Total Price: ₹${totalPrice.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: placeEventOrder,
                child: const Text('Place Event Order'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
