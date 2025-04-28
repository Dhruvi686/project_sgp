import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CouponHistoryScreen extends StatefulWidget {
  const CouponHistoryScreen({super.key});

  @override
  State<CouponHistoryScreen> createState() => _CouponHistoryScreenState();
}

class _CouponHistoryScreenState extends State<CouponHistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'expired'

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupon History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Coupons'),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Text('Active Coupons'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Coupons'),
              ),
              const PopupMenuItem(
                value: 'expired',
                child: Text('Expired Coupons'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final coupons = snapshot.data?.docs ?? [];
          
          // Filter coupons based on selection
          final filteredCoupons = coupons.where((doc) {
            final coupon = doc.data() as Map<String, dynamic>;
            final status = coupon['status'] as String? ?? 'pending';
            final expiryDate = (coupon['expiryDate'] as Timestamp).toDate();
            final isActive = status == 'active' && DateTime.now().isBefore(expiryDate);
            final isExpired = DateTime.now().isAfter(expiryDate);
            
            if (_selectedFilter == 'all') return true;
            if (_selectedFilter == 'active') return isActive;
            if (_selectedFilter == 'pending') return status == 'pending';
            if (_selectedFilter == 'expired') return isExpired;
            return true;
          }).toList();

          // Sort coupons by createdAt in descending order
          filteredCoupons.sort((a, b) {
            final aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
            final bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
            return bDate.compareTo(aDate);
          });

          if (filteredCoupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFilter == 'active' 
                        ? Icons.check_circle_outline 
                        : _selectedFilter == 'pending'
                            ? Icons.pending
                            : Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'all'
                        ? 'No coupons found'
                        : _selectedFilter == 'active'
                            ? 'No active coupons'
                            : _selectedFilter == 'pending'
                                ? 'No pending coupons'
                                : 'No expired coupons',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCoupons.length,
            itemBuilder: (context, index) {
              final coupon = filteredCoupons[index].data() as Map<String, dynamic>;
              final startDate = (coupon['purchaseDate'] as Timestamp).toDate();
              final expiryDate = (coupon['expiryDate'] as Timestamp).toDate();
              final status = coupon['status'] as String? ?? 'pending';
              final isActive = status == 'active' && DateTime.now().isBefore(expiryDate);
              final isExpired = DateTime.now().isAfter(expiryDate);
              final duration = coupon['duration'] ?? 1;
              final price = coupon['price'] ?? 0;
              final packageType = coupon['packageType'] ?? 'Regular Food Monthly Package';

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
                                  packageType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${duration} Month${duration > 1 ? 's' : ''} Package',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
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
                              color: status == 'active' 
                                  ? Colors.green 
                                  : status == 'pending'
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'active' 
                                  ? 'Active'
                                  : status == 'pending'
                                      ? 'Pending'
                                      : 'Expired',
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
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(startDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expiry Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(expiryDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹$price',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (isActive) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Days Remaining',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${expiryDate.difference(DateTime.now()).inDays} days',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Waiting for admin approval',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (expiryDate.difference(DateTime.now()).inDays) /
                              (duration * 30),
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 