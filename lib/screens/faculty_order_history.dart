import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventOrdersScreen extends StatefulWidget {
  @override
  _EventOrdersScreenState createState() => _EventOrdersScreenState();
}

class _EventOrdersScreenState extends State<EventOrdersScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found."));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['timestamp'] as Timestamp).toDate();
                    final items = data['items'] as List<dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text("Items: ${items.map((item) => item['name']).join(', ')}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${DateFormat.yMMMd().format(date)}"),
                            Text("Total Price: ₹${data['totalPrice']}"),
                            Text("Status: ${data['status']}"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                  .where('userId', isEqualTo: currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No event orders found."));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final startDate = data['startDate'] != null
                        ? (data['startDate'] as Timestamp).toDate()
                        : null;
                    final endDate = data['endDate'] != null
                        ? (data['endDate'] as Timestamp).toDate()
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text("Food Type: ${data['foodType']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Meals: ${(data['meals'] as List).join(', ')}"),
                            Text("Sweet: ${data['sweet']}"),
                            if (startDate != null && endDate != null)
                              Text(
                                "From: ${DateFormat.yMMMd().format(startDate)} to ${DateFormat.yMMMd().format(endDate)}",
                              ),
                            Text("Status: ${data['status']}"),
                            Text("Total Price: ₹${data['totalPrice']}"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
