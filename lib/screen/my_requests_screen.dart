import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // You may need to run: flutter pub add intl

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Paint Requests', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only fetch requests made by the currently logged-in user
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven't made any paint requests yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Fetch the documents and sort them locally (newest first)
          // Doing this locally prevents you from needing to set up complex Firebase Indexes right now
          var requests = snapshot.data!.docs.toList();
          requests.sort((a, b) {
            Timestamp? timeA = a['timestamp'] as Timestamp?;
            Timestamp? timeB = b['timestamp'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA); // Descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var req = requests[index];
              String status = req['status'] ?? 'Pending';
              int qty = req['requestedQty'] ?? 0;
              String paintName = req['paintName'] ?? 'Unknown Paint';
              
              // Handle the timestamp formatting safely
              Timestamp? ts = req['timestamp'] as Timestamp?;
              String dateString = ts != null 
                  ? DateFormat('MMM dd, yyyy - hh:mm a').format(ts.toDate()) 
                  : 'Just now';

              // Dynamic color coding for the UI
              Color statusColor;
              IconData statusIcon;
              if (status == 'Approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'Rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              } else {
                statusColor = Colors.orange;
                statusIcon = Icons.access_time_filled;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              paintName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Requested Quantity: $qty units", style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("Date: $dateString", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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