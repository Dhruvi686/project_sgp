// lib/pages/faculty_dashboard.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/screens/faculty_menu_view.dart';
import 'package:app/screens/faculty_order_history.dart';
import 'package:app/screens/faculty_book_food.dart';
import 'package:app/screens/faculty_payment_history.dart';
class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(
              context,
              Icons.restaurant_menu,
              'View Today\'s Menu',
              FacultyMenuView(
                facultyId: user.uid,
                facultyName: user.displayName ?? 'Faculty',
                department: _userData?['department'] ?? 'Unknown Department',
              ),
            ),
            _buildTile(
              context,
              Icons.shopping_cart,
              'Book Food',
              const BookFoodScreen(),
            ),
            _buildTile(
              context,
              Icons.history,
              'Order History',
              EventOrdersScreen(),
            ),
            _buildTile(
              context,
              Icons.payment,
              'Payment Info',
              const FacultyPaymentHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String label, Widget targetPage) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
