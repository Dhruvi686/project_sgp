import 'package:app/screens/EventBookingScreen.dart';
import 'package:flutter/material.dart';
import 'MonthlyPackageScreen.dart';
import 'ViewCouponPage.dart'; // ✅ Import this for the coupon page

class BookFoodScreen extends StatelessWidget {
  const BookFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Food')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonthlyPackagePage()),
              );
            },
            child: const Text('Monthly Package'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to Event Booking Screen
            },
            child: const Text('For Any Event'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventBookingScreen()),
    );
  },
  child: const Text('For Any Event'),
),
          const SizedBox(height: 30),

          // 🔽 NEW: View My Coupon Button
          ElevatedButton.icon(
            icon: Icon(Icons.card_giftcard),
            label: Text("View My Coupon"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewCouponPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
