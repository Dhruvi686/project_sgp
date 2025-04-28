import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminMenuUpdate extends StatefulWidget {
  const AdminMenuUpdate({super.key});

  @override
  State<AdminMenuUpdate> createState() => _AdminMenuUpdateState();
}

class _AdminMenuUpdateState extends State<AdminMenuUpdate> {
  final TextEditingController _priceController = TextEditingController();
  final List<TextEditingController> _itemControllers = [TextEditingController()];
  String? docId; // used for editing the latest menu

  @override
  void initState() {
    super.initState();
    _loadLatestMenu();
  }

  Future<void> _loadLatestMenu() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('daily_menu')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();
      docId = doc.id;

      final List<dynamic> items = data['items'] ?? [];
      final price = data['price'];

      _priceController.text = price.toString();
      _itemControllers.clear();
      for (var item in items) {
        _itemControllers.add(TextEditingController(text: item));
      }
      setState(() {});
    }
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
    });
  }

  void _removeItemField(int index) {
    setState(() {
      _itemControllers.removeAt(index);
    });
  }

  Future<void> _saveMenu() async {
    final items = _itemControllers.map((c) => c.text.trim()).where((i) => i.isNotEmpty).toList();
    final price = double.tryParse(_priceController.text.trim());

    if (items.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid menu and price')));
      return;
    }

    final menuData = {
      'items': items,
      'price': price,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (docId != null) {
      await FirebaseFirestore.instance.collection('daily_menu').doc(docId).update(menuData);
    } else {
      await FirebaseFirestore.instance.collection('daily_menu').add(menuData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu saved successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Today's Menu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Menu Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._itemControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Item ${index + 1}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: _itemControllers.length > 1
                        ? () => _removeItemField(index)
                        : null,
                  )
                ],
              );
            }),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addItemField,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Menu Price'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMenu,
              child: const Text('Save Menu'),
            )
          ],
        ),
      ),
    );
  }
}
