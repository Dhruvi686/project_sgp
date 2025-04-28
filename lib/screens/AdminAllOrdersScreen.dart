import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // for date formatting

class AdminAllOrdersPage extends StatefulWidget {
  const AdminAllOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminAllOrdersPageState createState() => _AdminAllOrdersPageState();
}

class _AdminAllOrdersPageState extends State<AdminAllOrdersPage> {
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchEventOrders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('event_orders')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCoupons() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('coupons') // ✅ Correct collection name
        .orderBy('activatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Orders & Coupons")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🧾 Regular Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No regular orders found.');
                }

                return Column(
                  children: snapshot.data!.map((order) {
                    return Card(
                      child: ListTile(
                        title: Text("Faculty: ${order['facultyName'] ?? 'N/A'}"),
                        subtitle: Text("Total: ₹${order['totalPrice'] ?? 0} | Status: ${order['status'] ?? 'N/A'}"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("🎉 Event Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchEventOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No event orders found.');
                }

                return Column(
                  children: snapshot.data!.map((event) {
                    return Card(
                      child: ListTile(
                        title: Text("Faculty: ${event['facultyName'] ?? 'N/A'}"),
                        subtitle: Text("Type: ${event['foodType'] ?? 'N/A'} | Status: ${event['status'] ?? 'N/A'}"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("📅 Monthly Coupons", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchCoupons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No coupons found.');
                }

                return Column(
                  children: snapshot.data!.map((coupon) {
                    final activatedAt = (coupon['activatedAt'] as Timestamp?)?.toDate();
                    final expiresAt = (coupon['expiresAt'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        title: Text("Faculty: ${coupon['facultyName'] ?? 'N/A'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Coupon ID: ${coupon['couponId'] ?? 'N/A'}"),
                            Text("Activated: ${activatedAt != null ? dateFormat.format(activatedAt) : 'N/A'}"),
                            Text("Expires: ${expiresAt != null ? dateFormat.format(expiresAt) : 'N/A'}"),
                            Text("Status: ${coupon['status'] ?? 'N/A'}"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
