import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  // --- Helper to convert Hex to Color ---
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

  // --- Core Transaction Logic ---
  Future<void> _makeDecision(BuildContext context, String requestId, String paintId, int requestedQty, bool isApproved) async {
    final db = FirebaseFirestore.instance;
    final paintRef = db.collection('paints').doc(paintId);
    final requestRef = db.collection('requests').doc(requestId);

    try {
      await db.runTransaction((transaction) async {
        if (isApproved) {
          DocumentSnapshot paintDoc = await transaction.get(paintRef);
          int currentStock = paintDoc.get('currentStock') ?? 0;
          
          if (currentStock < requestedQty) {
            throw Exception("Not enough stock in the warehouse!");
          }
          // Deduct the stock
          transaction.update(paintRef, {'currentStock': currentStock - requestedQty});
        }
        
        // Update request status
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

  // --- Confirmation Pop-up for Rejecting ---
  void _confirmReject(BuildContext context, String requestId, String paintId, int requestedQty) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Rejection"),
          content: const Text("Are you sure you want to reject this paint request?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                _makeDecision(context, requestId, paintId, requestedQty, false);
              },
              child: const Text("Reject Request", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Approvals"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
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
              String paintId = req['paintId']; 
              String userId = req['userId']; // Get the user's ID from the request

              // --- NEW: Fetch BOTH the Paint Color and the User's Name simultaneously ---
              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('paints').doc(paintId).get(),
                  FirebaseFirestore.instance.collection('users').doc(userId).get(),
                ]),
                builder: (context, dualSnapshot) {
                  if (!dualSnapshot.hasData) return const Card(child: ListTile(title: Text("Loading details...")));

                  // Extract Data
                  var paintData = dualSnapshot.data![0].data() as Map<String, dynamic>?;
                  var userData = dualSnapshot.data![1].data() as Map<String, dynamic>?;

                  String hexColor = paintData != null && paintData.containsKey('hexColor') ? paintData['hexColor'] : '#CCCCCC';
                  
                  // Extract the user's name (fallback to "Unknown Staff" if missing)
                  String operatorName = userData != null && userData.containsKey('name') ? userData['name'] : 'Unknown Staff';

                  return Card(
                    elevation: 2,
                    child: ListTile(
                      // Paint Color Swatch
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _hexToColor(hexColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                      ),
                      title: Text("${req['paintName']} (Qty: ${req['requestedQty']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      
                      // --- NEW: Show the Operator's name in the subtitle ---
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Requested by: $operatorName", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                          const Text("Waiting for Admin review", style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                      
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 35), 
                            onPressed: () => _makeDecision(context, req.id, req['paintId'], req['requestedQty'], true)
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 35), 
                            onPressed: () => _confirmReject(context, req.id, req['paintId'], req['requestedQty'])
                          ),
                        ],
                      ),
                    ),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}