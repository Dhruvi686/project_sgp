// lib/screens/admin_notifications.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsPage extends StatelessWidget {
  const AdminNotificationsPage({super.key});

  Future<void> markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('admin_notifications').doc(docId).update({'read': true});
  }

  Future<void> deleteNotification(String docId) async {
    await FirebaseFirestore.instance.collection('admin_notifications').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Notifications')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(data['message'] ?? ''),
                  subtitle: Text(data['timestamp'].toDate().toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!(data['read'] ?? false))
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => markAsRead(doc.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteNotification(doc.id),
                      ),
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
