import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'faculty_payment_history.dart';

class FacultyMenuView extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String department;

  const FacultyMenuView({
    Key? key,
    required this.facultyId,
    required this.facultyName,
    required this.department,
  }) : super(key: key);

  @override
  State<FacultyMenuView> createState() => _FacultyMenuViewState();
}

class _FacultyMenuViewState extends State<FacultyMenuView> {
  final List<Map<String, dynamic>> _selectedItems = [];
  double _totalAmount = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Menu'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => _showOrderSummary(),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_menu')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No menu items available for today'));
          }

          // Get the latest menu document
          final doc = snapshot.data!.docs.first;
          final items = doc['items'] as List<dynamic>;
          final price = doc['price'];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemName = items[index].toString();
                    final isSelected = _selectedItems.any((item) => item['name'] == itemName);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(itemName),
                        subtitle: Text('Price: ₹$price'),
                        trailing: IconButton(
                          icon: Icon(
                            isSelected ? Icons.check_circle : Icons.check_circle_outline,
                            color: isSelected ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.removeWhere((item) => item['name'] == itemName);
                              } else {
                                _selectedItems.add({
                                  'name': itemName,
                                  'price': price,
                                  'quantity': 1,
                                });
                              }
                              _calculateTotal();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _isLoading ? 'Processing...' : 'Book Now (₹$_totalAmount)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleItemSelection(Map<String, dynamic> item, String itemId) {
    setState(() {
      if (_selectedItems.any((i) => i['id'] == itemId)) {
        _selectedItems.removeWhere((i) => i['id'] == itemId);
      } else {
        _selectedItems.add({
          ...item,
          'id': itemId,
          'quantity': 1,
        });
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _selectedItems.fold(
      0,
      (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)),
    );
  }

  void _showItemDetails(Map<String, dynamic> item, String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['category'] ?? 'Uncategorized',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['description'] ?? 'No description available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '₹${item['price'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleItemSelection(item, itemId);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedItems.any((i) => i['id'] == itemId)
                          ? 'Remove from Order'
                          : 'Add to Order',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._selectedItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${item['price'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (item['quantity'] > 1) {
                                      item['quantity']--;
                                    } else {
                                      _selectedItems.remove(item);
                                    }
                                    _calculateTotal();
                                  });
                                  Navigator.pop(context);
                                  _showOrderSummary();
                                },
                              ),
                              Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    item['quantity']++;
                                    _calculateTotal();
                                  });
                                  Navigator.pop(context);
                                  _showOrderSummary();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹$_totalAmount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_isLoading ? 'Processing...' : 'Place Order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create order document in Firebase
      final orderData = {
        'facultyId': user.uid,
        'facultyName': widget.facultyName,
        'department': widget.department,
        'items': _selectedItems.map((item) => {
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
        }).toList(),
        'totalAmount': _totalAmount,
        'status': 'pending',
        'orderDate': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending',
      };

      // Add order to Firestore
      final orderRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      // Generate receipt
      final receiptData = {
        'orderId': orderRef.id,
        'facultyName': widget.facultyName,
        'department': widget.department,
        'items': _selectedItems.map((item) => {
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
        }).toList(),
        'totalAmount': _totalAmount,
        'date': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // Store receipt in Firebase
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(orderRef.id)
          .set(receiptData);

      // Show success message and navigate to payment history
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        
        // Clear selection
        setState(() {
          _selectedItems.clear();
          _totalAmount = 0;
          _isLoading = false;
        });

        // Navigate to payment history
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FacultyPaymentHistory(),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error placing order: $e'); // For debugging
    }
  }
}

class FacultyOrderHistory extends StatelessWidget {
  const FacultyOrderHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your order history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid) // Filter by logged-in user
            .orderBy('timestamp', descending: true) // Sort by latest orders
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>;
              final date = (data['timestamp'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    'Items: ${items.map((item) => item['name']).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: ${date.toString()}\n'
                    'Total Price: ₹${data['totalPrice'].toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    data['status'].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: data['status'] == 'approved'
                          ? Colors.green
                          : Colors.orange,
                    ),
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
