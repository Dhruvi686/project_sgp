// lib/screens/hod_dashboard.dart
import 'package:app/pages/login_page.dart';
import 'package:app/screens/hod_event_approval.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HodDashboard extends StatelessWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hod Dashboard'),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.event_available),
            label: const Text("Approve Event Orders"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HODEventOrdersScreen()),
              );
            },
          ),
          // Add other buttons like "Profile", "Logout" etc. if needed
        ],
      ),
    );
  }
}
