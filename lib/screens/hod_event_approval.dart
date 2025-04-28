import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HODEventOrdersScreen extends StatelessWidget {
  const HODEventOrdersScreen({super.key});

  Future<void> approveOrder(String docId) async {
    await FirebaseFirestore.instance.collection('event_orders').doc(docId).update({
      'status': 'approved_by_hod',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Event Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('event_orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No event orders available.'));
          }

          // Separate pending and approved orders
          final pendingOrders = docs.where((doc) => doc['status'] == 'pending_hod_approval').toList();
          final approvedOrders = docs.where((doc) => doc['status'] == 'approved_by_hod').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '🔶 Pending Approvals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (pendingOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('No pending orders.'),
                ),
              ...pendingOrders.map((doc) => EventOrderTile(
                    doc: doc,
                    onApprove: () => approveOrder(doc.id),
                  )),
              const SizedBox(height: 24),
              const Text(
                '✅ Approved Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (approvedOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('No approved orders.'),
                ),
              ...approvedOrders.map((doc) => EventOrderTile(
                    doc: doc,
                    onApprove: null,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class EventOrderTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback? onApprove;

  const EventOrderTile({super.key, required this.doc, this.onApprove});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final dateRange =
        '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('${data['facultyName']} (${data['department']})'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Food: ${data['foodType']} | Sweet: ${data['sweet']}'),
            Text('Meals: ${List<String>.from(data['meals']).join(', ')}'),
            Text('Dates: $dateRange'),
            Text('Total: ₹${data['totalPrice']}'),
            Text('Status: ${data['status']}'),
          ],
        ),
        trailing: onApprove != null
            ? ElevatedButton(onPressed: onApprove, child: const Text('Approve'))
            : null,
      ),
    );
  }
}
