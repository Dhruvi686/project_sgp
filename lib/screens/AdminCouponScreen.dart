import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'active': 0,
    'expired': 0,
  };
  WillPopCallback? _backCallback;
  bool _isLoading = true;
  ModalRoute? _route;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add back button listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _route = ModalRoute.of(context);
        _backCallback = () async {
          Navigator.of(context).pop();
          return true;
        };
        _route?.addScopedWillPopCallback(_backCallback!);
      }
    });
  }

  @override
  void dispose() {
    if (_backCallback != null && _route != null) {
      _route!.removeScopedWillPopCallback(_backCallback!);
    }
    _searchController.dispose();
    super.dispose();
  }

  void _updateStats(List<QueryDocumentSnapshot> coupons) {
    if (!mounted) return;
    
    final newStats = {
      'total': coupons.length,
      'pending': coupons.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'pending';
      }).length,
      'active': coupons.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'active';
      }).length,
      'expired': coupons.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'expired';
      }).length,
    };

    if (mounted) {
      setState(() {
        _stats = newStats;
      });
    }
  }

  Future<void> updateCouponStatus(String couponId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(couponId)
          .update({'status': status});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
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

  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final paymentDoc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .get();
      return paymentDoc.data();
    } catch (e) {
      return null;
    }
  }

  Widget _buildEmptyState() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Coupon Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CouponSearchDelegate(),
              );
            },
          ),
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
                value: 'pending',
                child: Text('Pending Coupons'),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Text('Active Coupons'),
              ),
              const PopupMenuItem(
                value: 'expired',
                child: Text('Expired Coupons'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Total', _stats['total']!, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Pending', _stats['pending']!, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Active', _stats['active']!, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Expired', _stats['expired']!, Colors.red),
              ],
            ),
          ),
          // Coupons List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('coupons')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  _errorMessage = 'Error: ${snapshot.error}';
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                _isLoading = false;
                final coupons = snapshot.data?.docs ?? [];
                
                // Update stats
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateStats(coupons);
                });
                
                // Filter coupons based on selection
                final filteredCoupons = coupons.where((doc) {
                  final coupon = doc.data() as Map<String, dynamic>;
                  final status = coupon['status'] as String? ?? 'pending';
                  final expiryDate = (coupon['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final isExpired = DateTime.now().isAfter(expiryDate);
                  
                  if (_selectedFilter == 'all') return true;
                  if (_selectedFilter == 'pending') return status == 'pending';
                  if (_selectedFilter == 'active') return status == 'active' && !isExpired;
                  if (_selectedFilter == 'expired') return isExpired;
                  return true;
                }).toList();

                if (filteredCoupons.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCoupons.length,
                  itemBuilder: (context, index) {
                    final doc = filteredCoupons[index];
                    final coupon = doc.data() as Map<String, dynamic>;
                    final startDate = (coupon['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final expiryDate = (coupon['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final status = coupon['status'] as String? ?? 'pending';
                    final isExpired = DateTime.now().isAfter(expiryDate);
                    final duration = coupon['duration'] ?? 1;
                    final price = coupon['price'] ?? 0;
                    final packageType = coupon['packageType'] ?? 'Regular Food Monthly Package';
                    final userId = coupon['userId'] as String? ?? '';
                    final paymentId = coupon['paymentId'] as String? ?? '';

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
                                      const SizedBox(height: 4),
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: getUserDetails(userId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Text('Loading user details...');
                                          }
                                          final userData = snapshot.data;
                                          return Text(
                                            'User: ${userData?['name'] ?? 'Unknown'} (${userData?['email'] ?? userId})',
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
                                if (status == 'pending') ...[
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => updateCouponStatus(doc.id, 'active'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => updateCouponStatus(doc.id, 'expired'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            if (paymentId.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: getPaymentDetails(paymentId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading payment details...');
                                  }
                                  final paymentData = snapshot.data;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payment Details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Method: ${paymentData?['paymentMethod'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Card: **** **** **** ${paymentData?['cardLastFour'] ?? '****'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Date: ${DateFormat('dd MMM yyyy').format((paymentData?['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupons')
          .where('userId', isEqualTo: query)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final coupons = snapshot.data?.docs ?? [];
        if (coupons.isEmpty) {
          return const Center(child: Text('No coupons found for this user'));
        }

        return ListView.builder(
          itemCount: coupons.length,
          itemBuilder: (context, index) {
            final coupon = coupons[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Coupon ID: ${coupons[index].id}'),
              subtitle: Text('Status: ${coupon['status']}'),
              onTap: () {
                close(context, coupons[index].id);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
} 