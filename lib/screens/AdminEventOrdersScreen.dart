import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AdminEventOrdersScreen extends StatelessWidget {
  const AdminEventOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Approved Event Orders')),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getApprovedEventOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final orders = snapshot.data!;
          if (orders.isEmpty)
            return Center(child: Text("No approved event orders."));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['facultyName'] ?? 'Unknown'),
                subtitle: Text(
                  "Meals: ${data['meals'].join(', ')}\nFood Type: ${data['foodType']}\nPrice: ₹${data['totalPrice']}",
                ),
                trailing: Text(data['status']),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<DocumentSnapshot>> getApprovedEventOrders() {
    return FirebaseFirestore.instance
        .collection('event_orders')
        .where('status', isEqualTo: 'approved_by_hod')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
