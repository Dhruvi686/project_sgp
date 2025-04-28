import 'package:app/pages/admin_dashboard.dart';
import 'package:app/pages/faculty_dashboard.dart';
import 'package:app/pages/hod_dashboard.dart';
import 'package:app/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();

  String _role = 'Faculty';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final auth = FirebaseAuth.instance;
        UserCredential userCred = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCred.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': _departmentController.text.trim(),
          'role': _role.toLowerCase(),
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')),
        );

        _navigateToDashboard(_role.toLowerCase());
      } on FirebaseAuthException catch (e) {
        String error = 'Authentication Error';
        if (e.code == 'email-already-in-use') {
          error = 'Email already in use';
        } else if (e.code == 'weak-password') {
          error = 'Weak password';
        } else if (e.code == 'invalid-email') {
          error = 'Invalid email';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else if (role == 'faculty') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FacultyDashboard()));
    } else if (role == 'hod') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HodDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'];
      if (role != null) _navigateToDashboard(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter your department' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['Admin', 'Faculty', 'HOD']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                      icon: const Icon(Icons.app_registration),
                      label: const Text('Register',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
