import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FacultyPaymentHistory extends StatelessWidget {
  const FacultyPaymentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your payment history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('facultyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No payment history available.'));
          }

          // Sort the documents by orderDate in memory
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aDate = (a.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
              final bDate = (b.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            });

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderDate = (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    'Order #${doc.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(orderDate),
                  ),
                  trailing: Text(
                    '₹${data['totalAmount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['name'] ?? 'Unknown Item'),
                                    Text('₹${item['price']} x ${item['quantity']}'),
                                  ],
                                ),
                              )),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${data['totalAmount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showReceiptPreview(context, data, doc.id, orderDate),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Download Receipt'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showReceiptPreview(BuildContext context, Map<String, dynamic> data, String orderId, DateTime orderDate) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Order ID: $orderId'),
                        pw.Text('Date: ${DateFormat('dd MMM yyyy, HH:mm').format(orderDate)}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Faculty: ${data['facultyName']}'),
                        pw.Text('Department: ${data['department']}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...List<Map<String, dynamic>>.from(data['items'] ?? []).map((item) {
                      final quantity = item['quantity'] ?? 1;
                      final price = item['price'] ?? 0;
                      final total = quantity * price;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(item['name'] ?? 'Unknown Item'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(quantity.toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('₹$price'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('₹$total'),
                          ),
                        ],
                      );
                    }),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('₹${data['totalAmount']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('Thank you for your order!', style: pw.TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        ),
      );

      // Show the PDF preview dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Receipt Preview'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => pdf.save(),
                        name: 'Receipt_$orderId.pdf',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      final directory = await getTemporaryDirectory();
                      final file = File('${directory.path}/receipt_$orderId.pdf');
                      final pdfBytes = await pdf.save();
                      await file.writeAsBytes(pdfBytes);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Receipt saved to: ${file.path}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) => pdf.save(),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 