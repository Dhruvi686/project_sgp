import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllOrdersOverviewScreen extends StatefulWidget {
  const AllOrdersOverviewScreen({super.key});

  @override
  State<AllOrdersOverviewScreen> createState() =>
      _AllOrdersOverviewScreenState();
}

class _AllOrdersOverviewScreenState extends State<AllOrdersOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data();
    } catch (e) {
      return null;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
    final userId = order['userId'] as String? ?? '';
    final orderDate =
        (order['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = order['status'] as String? ?? 'pending';
    final totalAmount = order['totalAmount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'regular'
                            ? 'Regular Order'
                            : type == 'event'
                                ? 'Event Order'
                                : 'Coupon Purchase',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getUserDetails(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading user details...');
                          }
                          final userData = snapshot.data;
                          return Text(
                            'User: ${userData?['name'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? Colors.green
                        : status == 'pending'
                            ? Colors.orange
                            : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(orderDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (type != 'coupons') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$totalAmount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (type == 'event') ...[
              const SizedBox(height: 16),
              Text(
                'Event: ${order['eventName'] ?? 'Unknown Event'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Event Date: ${DateFormat('dd MMM yyyy').format((order['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${order['location'] ?? 'Not specified'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Guests: ${order['guestCount'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (type == 'coupons') ...[
              const SizedBox(height: 16),
              Text(
                'Package: ${order['packageType'] ?? 'Regular Food Monthly Package'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${order['duration'] ?? 1} Month${order['duration'] > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Price: ₹${order['price'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders Overview'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Regular Orders'),
            Tab(text: 'Event Orders'),
            Tab(text: 'Coupons'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Regular Orders Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('orderDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];
              if (orders.isEmpty) {
                return const Center(
                  child: Text('No regular orders found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final order = doc.data() as Map<String, dynamic>;
                  order['id'] = doc.id;
                  return _buildOrderCard(order, 'regular');
                },
              );
            },
          ),
          // Event Orders Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('event_orders')
                .orderBy('timestamp', descending: true) // Use the timestamp field for sorting
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data?.docs ?? [];
              if (events.isEmpty) {
                return const Center(
                  child: Text('No event orders found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final doc = events[index];
                  final event = doc.data() as Map<String, dynamic>;
                  event['id'] = doc.id;

                  // Build the event card
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty: ${event['facultyName'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Department: ${event['department'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Food Type: ${event['foodType'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Meals: ${event['meals']?.join(', ') ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start Date: ${DateFormat('dd MMM yyyy').format((event['startDate'] as Timestamp).toDate())}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'End Date: ${DateFormat('dd MMM yyyy').format((event['endDate'] as Timestamp).toDate())}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Price: ₹${event['totalPrice'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: event['status'] == 'approved_by_hod'
                                  ? Colors.green
                                  : event['status'] == 'pending'
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event['status']?.toUpperCase() ?? 'UNKNOWN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Coupons Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('coupons')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];
              if (orders.isEmpty) {
                return const Center(
                  child: Text('No coupons found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final order = doc.data() as Map<String, dynamic>;
                  order['id'] = doc.id;
                  return _buildOrderCard(order, 'coupons');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}