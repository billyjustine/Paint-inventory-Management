import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrowseInventoryScreen extends StatelessWidget {
  final bool isAdmin; 

  const BrowseInventoryScreen({super.key, required this.isAdmin});

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey; 
    }
  }

  // --- NEW: Function to handle Admin Restocking ---
  void _handleRestock(BuildContext context, DocumentSnapshot paintDoc) {
    final TextEditingController qtyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Restock: ${paintDoc['name']}"),
        content: TextField(
          controller: qtyController, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: "How many units arrived?")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              int qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              int currentStock = paintDoc['currentStock'] ?? 0;

              // Add the new delivery to the current stock
              await FirebaseFirestore.instance.collection('paints').doc(paintDoc.id).update({
                'currentStock': currentStock + qty
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Warehouse restocked successfully!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Add Inventory", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Existing Checkout / Request Logic
  void _handlePaintAction(BuildContext context, DocumentSnapshot paintDoc) {
    final TextEditingController qtyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

              int currentStock = paintDoc['currentStock'] ?? 0;

              if (qty > currentStock) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Only $currentStock units available!"), 
                  backgroundColor: Colors.red
                ));
                return;
              }

              if (isAdmin) {
                await FirebaseFirestore.instance.collection('paints').doc(paintDoc.id).update({
                  'currentStock': currentStock - qty
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock directly updated!"), backgroundColor: Colors.green));
                }
              } else {
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
            child: Text(isAdmin ? "Deduct Stock" : "Send to Admin", style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Stock"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
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
              var data = paint.data() as Map<String, dynamic>;
              
              String hexColor = data.containsKey('hexColor') ? data['hexColor'] : '#CCCCCC'; 
              int currentStock = data['currentStock'] ?? 0;
              bool isOutOfStock = currentStock <= 0;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _hexToColor(hexColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2), 
                    ),
                  ),
                  title: Text(paint['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(
                    isOutOfStock ? "Out of Stock" : "Available Stock: $currentStock", 
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  
                  // --- NEW: Separate UI for Admin vs User ---
                  trailing: isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Restock Button (Only Admins see this)
                          IconButton(
                            icon: const Icon(Icons.add_box, color: Colors.blue, size: 32),
                            onPressed: () => _handleRestock(context, paint),
                            tooltip: 'Restock Paint',
                          ),
                          const SizedBox(width: 8),
                          // Checkout Button
                          ElevatedButton(
                            onPressed: isOutOfStock ? null : () => _handlePaintAction(context, paint),
                            child: const Text("Checkout"),
                          ),
                        ],
                      )
                    // User UI (Only sees the Request button)
                    : ElevatedButton(
                        onPressed: isOutOfStock ? null : () => _handlePaintAction(context, paint),
                        child: const Text("Request"),
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