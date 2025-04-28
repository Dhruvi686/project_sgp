import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllOrders extends StatelessWidget {
  const AdminAllOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Regular Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text("No regular orders found."));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final data = orders[index].data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text("Items: ${data['item']}"),
                        subtitle: Text(
                          "User: ${data['userId']}\nDate: ${date.toString()}",
                        ),
                        trailing: Text(
                          "₹${(data['price'] as num).toDouble().toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Event Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('event_orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final eventOrders = snapshot.data!.docs;

                if (eventOrders.isEmpty) {
                  return const Center(child: Text("No event orders found."));
                }

                return ListView.builder(
                  itemCount: eventOrders.length,
                  itemBuilder: (context, index) {
                    final data = eventOrders[index].data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text("Food Type: ${data['foodType']}"),
                        subtitle: Text(
                          "Meals: ${(data['meals'] as List).join(', ')}\n"
                          "Sweet: ${data['sweet']}\n"
                          "From: ${startDate.toString()} to ${endDate.toString()}\n"
                          "Status: ${data['status']}",
                        ),
                        trailing: Text(
                          "₹${(data['totalPrice'] as num).toDouble().toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
