import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screens.dart';
import 'browse_inventory_screen.dart';
import 'admin_requests_screen.dart';
import 'my_requests_screen.dart';
import 'add_paint_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Center(child: Text("Error: Profile not found"));
        
        bool isAdmin = userData['role'] == 'Administrator';

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(isAdmin ? "Admin Console" : "Stock Operator"),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
               // CORRECT: Removed "const" and added "(isAdmin: isAdmin)"
_buildMenuCard(context, Icons.inventory_2, "Browse Stock", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrowseInventoryScreen(isAdmin: isAdmin)))),
                
                // Admin Tools
                if (isAdmin) ...[
                  _buildMenuCard(context, Icons.add_circle, "Add Paint", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPaintScreen()))),
                  _buildMenuCard(context, Icons.assignment_turned_in, "Review Requests", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRequestsScreen()))),
                ],
                
              
                // User Tools
                    if (!isAdmin) ...[
                    _buildMenuCard(
                    context, 
                    Icons.history, 
                    "My Requests", 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen()))
                    ),
                    ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: const Color(0xFF1A237E)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}