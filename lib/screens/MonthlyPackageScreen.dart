import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'CouponHistoryScreen.dart';

class MonthlyPackagePage extends StatefulWidget {
  const MonthlyPackagePage({super.key});

  @override
  State<MonthlyPackagePage> createState() => _MonthlyPackagePageState();
}

class _MonthlyPackagePageState extends State<MonthlyPackagePage> {
  bool isLoading = false;
  Map<String, dynamic>? activeCoupon;
  int selectedDuration = 1;
  final List<int> availableDurations = [1, 3, 6, 12];
  DateTime? selectedStartDate;

  @override
  void initState() {
    super.initState();
    fetchCoupon();
  }

  Future<void> fetchCoupon() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final couponDoc = await FirebaseFirestore.instance.collection('coupons').doc(uid).get();

    if (couponDoc.exists) {
      final data = couponDoc.data()!;
      final expiry = (data['expiryDate'] as Timestamp).toDate();
      if (DateTime.now().isBefore(expiry)) {
        setState(() => activeCoupon = data);
      } else {
        // Update status to expired
        await FirebaseFirestore.instance.collection('coupons').doc(uid).update({
          'status': 'expired'
        });
      }
    }
  }

  void showCouponDetails() {
    if (activeCoupon == null) return;

    final formatter = DateFormat('dd MMM yyyy');
    final startDate = (activeCoupon!['purchaseDate'] as Timestamp).toDate();
    final expiryDate = (activeCoupon!['expiryDate'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Coupon Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Start Date: ${formatter.format(startDate)}'),
              Text('Expiry Date: ${formatter.format(expiryDate)}'),
              Text('Total Price: ₹1200'),
              const SizedBox(height: 10),
              Text('Package Type: Regular Food Monthly Package'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  int calculatePrice(int months) {
    return 1200 * months; // ₹1200 per month
  }

  Future<void> showDurationSelection() async {
    selectedStartDate = DateTime.now(); // Set default start date to today

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Package Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Start Date:'),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedStartDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(selectedStartDate!)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Duration:'),
                    const SizedBox(height: 10),
                    DropdownButton<int>(
                      value: selectedDuration,
                      isExpanded: true,
                      items: availableDurations.map((duration) {
                        return DropdownMenuItem<int>(
                          value: duration,
                          child: Text('$duration Month${duration > 1 ? 's' : ''} - ₹${calculatePrice(duration)}'),
                        );
                      }).toList(),
                      onChanged: (value) {
        setState(() {
                          selectedDuration = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package Summary:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text('Start Date: ${DateFormat('dd MMM yyyy').format(selectedStartDate!)}'),
                          Text('Duration: $selectedDuration Month${selectedDuration > 1 ? 's' : ''}'),
                          Text('Price per Month: ₹1200'),
                          const SizedBox(height: 8),
                          Text(
                            'Total Amount: ₹${calculatePrice(selectedDuration)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                TextButton(
                  child: const Text('Proceed to Payment'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedDuration);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((selectedMonths) {
      if (selectedMonths != null && selectedStartDate != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              duration: selectedMonths,
              startDate: selectedStartDate!,
              totalAmount: calculatePrice(selectedMonths),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Package')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CouponHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View All Coupons'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: showDurationSelection,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Purchase Monthly Package'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final int duration;
  final DateTime startDate;
  final int totalAmount;

  const PaymentScreen({
    super.key,
    required this.duration,
    required this.startDate,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> processPayment() async {
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Validate card details
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _nameController.text.isEmpty) {
        throw Exception('Please fill in all payment details');
      }

      // First check if user already has an active coupon
      final couponDoc = await FirebaseFirestore.instance.collection('coupons').doc(uid).get();
      if (couponDoc.exists) {
        final data = couponDoc.data()!;
        final expiry = (data['expiryDate'] as Timestamp).toDate();
        if (DateTime.now().isBefore(expiry)) {
          throw Exception('You already have an active coupon');
        }
      }

      // Create payment document first
      final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
      final paymentData = {
        'userId': uid,
        'amount': widget.totalAmount,
        'duration': widget.duration,
        'startDate': Timestamp.fromDate(widget.startDate),
        'paymentDate': Timestamp.now(),
        'status': 'completed',
        'paymentMethod': 'card',
        'cardLastFour': _cardNumberController.text.substring(_cardNumberController.text.length - 4),
        'cardholderName': _nameController.text,
        'createdAt': Timestamp.now(),
      };

      // Create coupon data
      final expiryDate = widget.startDate.add(Duration(days: 30 * widget.duration));
      final couponData = {
        'userId': uid,
        'purchaseDate': Timestamp.fromDate(widget.startDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'price': widget.totalAmount,
        'packageType': 'Regular Food Monthly Package',
        'duration': widget.duration,
        'paymentId': paymentRef.id,
      };

      // Try to create payment first
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(paymentRef, paymentData);
        });
        print('Payment created successfully');
      } catch (e) {
        print('Error creating payment: $e');
        throw Exception('Failed to create payment: $e');
      }

      // Then create coupon
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(FirebaseFirestore.instance.collection('coupons').doc(uid), couponData);
        });
        print('Coupon created successfully');
      } catch (e) {
        print('Error creating coupon: $e');
        // Try to delete the payment if coupon creation fails
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.delete(paymentRef);
          });
          print('Payment deleted after coupon creation failed');
        } catch (deleteError) {
          print('Error deleting payment after coupon creation failed: $deleteError');
        }
        throw Exception('Failed to create coupon: $e');
      }

      setState(() => isLoading = false);

      // Show payment success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Payment Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Package Duration: ${widget.duration} Month${widget.duration > 1 ? 's' : ''}'),
                Text('Start Date: ${DateFormat('dd MMM yyyy').format(widget.startDate)}'),
                Text('Expiry Date: ${DateFormat('dd MMM yyyy').format(expiryDate)}'),
                Text('Total Amount: ₹${widget.totalAmount}'),
                const SizedBox(height: 10),
                const Text('Your coupon has been created successfully! It will be activated after admin approval.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() => isLoading = false);
      String errorMessage = 'Error processing payment';
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. Please check your authentication status.';
      } else if (e.toString().contains('fill in all payment details')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('already have an active coupon')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Failed to create')) {
        errorMessage = e.toString();
      }
      
      print('Payment error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    const Text('Package Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                    Text('Duration: ${widget.duration} Month${widget.duration > 1 ? 's' : ''}'),
                    Text('Start Date: ${DateFormat('dd MMM yyyy').format(widget.startDate)}'),
                    Text('Total Amount: ₹${widget.totalAmount}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : processPayment,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text('Pay ₹${widget.totalAmount}'),
              ),
            ),
          ],
                  ),
      ),
    );
  }
}