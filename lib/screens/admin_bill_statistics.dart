import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBillStatisticsPage extends StatefulWidget {
  const AdminBillStatisticsPage({super.key});

  @override
  State<AdminBillStatisticsPage> createState() => _AdminBillStatisticsPageState();
}

class _AdminBillStatisticsPageState extends State<AdminBillStatisticsPage> {
  double regularTotal = 0;
  double eventTotal = 0;
  int couponCount = 0;
  double couponTotal = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    calculateStats();
  }

  Future<void> calculateStats() async {
    try {
      // Reset totals to avoid accumulation on hot reload
      regularTotal = 0;
      eventTotal = 0;
      couponCount = 0;
      couponTotal = 0;

      // Regular Orders Total
      final regularOrders = await FirebaseFirestore.instance.collection('orders').get();
      for (var doc in regularOrders.docs) {
        final data = doc.data();
        if (data.containsKey('totalPrice') && data['totalPrice'] is num) {
          regularTotal += (data['totalPrice'] as num).toDouble();
        }
      }

      // Event Orders Total (approved only)
      final eventOrders = await FirebaseFirestore.instance
          .collection('event_orders')
          .where('status', isEqualTo: 'approved_by_hod')
          .get();
      for (var doc in eventOrders.docs) {
        final data = doc.data();
        if (data.containsKey('totalPrice') && data['totalPrice'] is num) {
          eventTotal += (data['totalPrice'] as num).toDouble();
        }
      }

      // Monthly Coupons
      final coupons = await FirebaseFirestore.instance.collection('coupons').get();
      couponCount = coupons.docs.length;
      couponTotal = 0; // Reset couponTotal to avoid accumulation
      for (var doc in coupons.docs) {
        final data = doc.data();
        if (data.containsKey('price') && data['price'] is num) {
          couponTotal += (data['price'] as num).toDouble();
        } else {
          print('Warning: Missing or invalid price for coupon ${doc.id}');
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Statistics')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatTile(title: 'Total Regular Orders', amount: regularTotal),
                  StatTile(title: 'Total Event Orders', amount: eventTotal),
                  StatTile(title: 'Monthly Coupons Sold', amount: couponCount.toDouble(), isCount: true),
                  StatTile(title: 'Income from Coupons', amount: couponTotal),
                  const Divider(thickness: 1),
                  StatTile(
                    title: '💰 Total Earnings',
                    amount: regularTotal + eventTotal + couponTotal,
                    highlight: true,
                  ),
                ],
              ),
            ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String title;
  final double amount;
  final bool isCount;
  final bool highlight;

  const StatTile({
    super.key,
    required this.title,
    required this.amount,
    this.isCount = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.bar_chart, color: highlight ? Colors.green : Colors.teal),
      title: Text(title, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
      trailing: Text(
        isCount ? amount.toInt().toString() : '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: highlight ? 18 : 16,
          color: highlight ? Colors.green : Colors.black,
        ),
      ),
    );
  }
}
