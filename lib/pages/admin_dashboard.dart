// lib/pages/admin_dashboard.dart

import 'package:app/notification_service.dart';
import 'package:app/screens/AdminAllOrdersScreen.dart';
import 'package:app/screens/admin_bill_statistics.dart';
import 'package:app/screens/admin_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/screens/AdminCouponScreen.dart';
import 'package:app/screens/AllOrdersOverviewScreen.dart';

import 'track_income.dart';
import 'generate_bills.dart';
import 'department_reports.dart';
import 'package:app/screens/admin_menu_update.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
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
              Icons.add_box,
              'Add Today\'s Menu',
              const AdminMenuUpdate(),
            ),
           
           
           _buildTile(
              context,
              Icons.bar_chart,
              'Bill Statistics',
              const AdminBillStatisticsPage(), // <-- This is the new screen you added
            ),

            
            _buildTile(
              context,
              Icons.card_giftcard,
              'Coupon Management',
              const AdminCouponScreen(),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllOrdersOverviewScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 48,
                      color: const Color(0xFF009688), // Updated color
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All Orders Overview',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF009688)), // Updated color
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
