import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrowseInventoryScreen extends StatelessWidget {
  final bool isAdmin; // --- NEW: Tells the screen if the user is an Admin ---

  const BrowseInventoryScreen({super.key, required this.isAdmin});

  void _handlePaintAction(BuildContext context, DocumentSnapshot paintDoc) {
    final TextEditingController qtyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Changes the title based on role
        title: Text(isAdmin ? "Admin Checkout: ${paintDoc['name']}" : "Request: ${paintDoc['name']}"),
        content: TextField(
          controller: qtyController, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: "How many units do you need?")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              int qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              if (isAdmin) {
                // --- ADMIN LOGIC: Instantly deduct the stock ---
                int currentStock = paintDoc['currentStock'] ?? 0;
                if (currentStock < qty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough stock!"), backgroundColor: Colors.red));
                  return;
                }
                await FirebaseFirestore.instance.collection('paints').doc(paintDoc.id).update({
                  'currentStock': currentStock - qty
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock directly updated!"), backgroundColor: Colors.green));
                }
              } else {
                // --- USER LOGIC: Send a Pending Request ---
                await FirebaseFirestore.instance.collection('requests').add({
                  'paintId': paintDoc.id,
                  'paintName': paintDoc['name'],
                  'userId': FirebaseAuth.instance.currentUser!.uid,
                  'requestedQty': qty,
                  'status': 'Pending', 
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent to Admin!"), backgroundColor: Colors.green));
                }
              }
            },
            // Changes the button text based on role
            child: Text(isAdmin ? "Deduct Stock" : "Send to Admin", style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Warehouse Stock"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('paints').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var paints = snapshot.data!.docs;
          if (paints.isEmpty) return const Center(child: Text("Warehouse is empty."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: paints.length,
            itemBuilder: (context, index) {
              var paint = paints[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(paint['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("Available Stock: ${paint['currentStock']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton(
                    onPressed: () => _handlePaintAction(context, paint),
                    // Changes the main list button based on role
                    child: Text(isAdmin ? "Quick Checkout" : "Request"),
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