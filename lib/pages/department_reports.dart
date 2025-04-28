import 'package:flutter/material.dart';

class DepartmentReportsPage extends StatelessWidget {
  const DepartmentReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'dept': 'CS', 'orders': '20', 'income': '₹10000'},
      {'dept': 'IT', 'orders': '15', 'income': '₹7500'},
      {'dept': 'Civil', 'orders': '10', 'income': '₹5000'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Reports'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: reports.map((report) {
          return Card(
            child: ListTile(
              title: Text('${report['dept']} Department'),
              subtitle: Text('Orders: ${report['orders']} | Income: ${report['income']}'),
              leading: const Icon(Icons.bar_chart),
            ),
          );
        }).toList(),
      ),
    );
  }
}
