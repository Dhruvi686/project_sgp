import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewCouponPage extends StatelessWidget {
  const ViewCouponPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("My Monthly Coupon")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('coupons').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("You don't have any active coupons."));
          }

          final data = snapshot.data!;
          final activatedAt = (data['activatedAt'] as Timestamp).toDate();
          final expiresAt = (data['expiresAt'] as Timestamp).toDate();
          final status = data['status'] ?? 'unknown';
          final price = data['price'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              color: Colors.orange[100],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Coupon Value: ₹$price",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("Activated On: ${DateFormat.yMMMMd().format(activatedAt)}"),
                    Text("Expires On: ${DateFormat.yMMMMd().format(expiresAt)}"),
                    SizedBox(height: 10),
                    Text("Status: ${status.toUpperCase()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == "expired" ? Colors.red : Colors.green,
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
