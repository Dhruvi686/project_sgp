import 'package:flutter/material.dart';

class GenerateBillsPage extends StatelessWidget {
  const GenerateBillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> departments = ['CS', 'IT', 'Mech', 'Civil'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bills'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: departments.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('${departments[index]} Department'),
              subtitle: const Text('Monthly Bill: ₹5000'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {},
                child: const Text('Generate'),
              ),
            ),
          );
        },
      ),
    );
  }
}
