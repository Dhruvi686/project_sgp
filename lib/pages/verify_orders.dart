import 'package:flutter/material.dart';

class VerifyOrdersPage extends StatelessWidget {
  const VerifyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> orders = [
      {'id': '001', 'name': 'Lunch for CS Dept', 'status': 'Pending'},
      {'id': '002', 'name': 'Guest Dinner', 'status': 'Pending'},
      {'id': '003', 'name': 'Function Buffet', 'status': 'Approved'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Orders'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(order['name']!),
              subtitle: Text('Status: ${order['status']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}