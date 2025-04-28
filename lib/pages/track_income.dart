import 'package:flutter/material.dart';

class TrackIncomePage extends StatelessWidget {
  const TrackIncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final income = [
      {'date': 'April 1', 'amount': '₹2000'},
      {'date': 'April 2', 'amount': '₹3500'},
      {'date': 'April 3', 'amount': '₹1500'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Income'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: income.map((entry) {
          return Card(
            child: ListTile(
              title: Text('Date: ${entry['date']}'),
              subtitle: Text('Amount: ${entry['amount']}'),
              leading: const Icon(Icons.attach_money),
            ),
          );
        }).toList(),
      ),
    );
  }
}
