import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  // THE PROCESS: Admin makes a decision
  Future<void> _makeDecision(BuildContext context, String requestId, String paintId, int requestedQty, bool isApproved) async {
    final db = FirebaseFirestore.instance;
    final paintRef = db.collection('paints').doc(paintId);
    final requestRef = db.collection('requests').doc(requestId);

    try {
      await db.runTransaction((transaction) async {
        if (isApproved) {
          // Check if there is enough paint in the warehouse
          DocumentSnapshot paintDoc = await transaction.get(paintRef);
          int currentStock = paintDoc.get('currentStock') ?? 0;
          
          if (currentStock < requestedQty) {
            throw Exception("Not enough stock in the warehouse!");
          }
          
          // Deduct the stock!
          transaction.update(paintRef, {'currentStock': currentStock - requestedQty});
        }
        
        // Change the status so the User can see the result
        transaction.update(requestRef, {'status': isApproved ? 'Approved' : 'Rejected'});
      });
      
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isApproved ? "Approved! Stock deducted." : "Request Rejected.")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Approvals"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        // Only show requests that are waiting for an answer
        stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'Pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var requests = snapshot.data!.docs;

          if (requests.isEmpty) return const Center(child: Text("No pending requests right now."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var req = requests[index];
              return Card(
                child: ListTile(
                  title: Text("${req['paintName']} (Qty: ${req['requestedQty']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Text("Waiting for Admin review", style: TextStyle(color: Colors.orange)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Approve Button
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 35), 
                        onPressed: () => _makeDecision(context, req.id, req['paintId'], req['requestedQty'], true)
                      ),
                      // Reject Button
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 35), 
                        onPressed: () => _makeDecision(context, req.id, req['paintId'], req['requestedQty'], false)
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