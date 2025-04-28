import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'faculty_dashboard.dart';
import 'hod_dashboard.dart';
import 'admin_dashboard.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final role = doc.data()?['role'];

        if (role == 'faculty') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const FacultyDashboard()));
        } else if (role == 'hod') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HodDashboard()));
        } else if (role == 'admin') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🍽️ Network food image (mess theme)
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/1046/1046784.png', // Free food icon
              height: 130,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 100),
            ),
            const SizedBox(height: 30),
            const Text(
              'College Mess Food Order System',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Ordering made easy for faculty and admins!',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }
}
