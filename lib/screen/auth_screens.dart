import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool isLoading = false;
Future<void> login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter both email and password."), 
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1. Log the user in
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailCtrl.text.trim(), 
          password: passCtrl.text.trim()
      );
      
      // 2. Quickly grab their name from the database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      
      String userName = "Staff"; 
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        userName = data.containsKey('name') ? data['name'] : "Staff";
      }
      
      if (mounted) {
        // --- THE LOGIN SUCCESS MESSAGE ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Success! Welcome, $userName.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.green, // Makes the banner green for success
            behavior: SnackBarBehavior.floating, // Makes it float above the bottom edge
            duration: const Duration(seconds: 2), // Disappears quickly so it isn't annoying
          )
        );

        // 3. Send them to the Dashboard
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login Failed. Please check your credentials."), 
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.inventory, size: 80, color: Color(0xFF1A237E)),
              const SizedBox(height: 20),
              const Text(" Paint Inventory Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 20),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              isLoading ? const CircularProgressIndicator() : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), minimumSize: const Size.fromHeight(50)),
                onPressed: login, 
                child: const Text("LOGIN", style: TextStyle(color: Colors.white,fontSize: 20)),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("New User? Register Here"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
// --- REGISTER SCREEN ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  
  // Default selection
  String role = 'User'; 
  bool isLoading = false;

  Future<void> register() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please fill all fields. Password must be 6+ chars."),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1. Create the account in Firebase Auth
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(), 
          password: passCtrl.text.trim()
      );
      
      // 2. Save the user's role and details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'role': role,
      });
      
      if (mounted) {
        // --- NEW: Display the Success Message! ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration Successful! You can now log in.", style: TextStyle(fontWeight: FontWeight.bold)), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Makes it pop up slightly above the bottom
          )
        );
        
        // 3. Send them to the Login Screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.group_add, size: 60, color: Color(0xFF1A237E)),
                  const SizedBox(height: 10),
                  const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  const SizedBox(height: 25),

                  // --- NEW PREMIUM ROLE SELECTOR DESIGN ---
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("1. SELECT ACCOUNT TYPE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // STOCK USER BUTTON
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => role = 'User'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: role == 'User' ? const Color(0xFF1A237E) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: role == 'User' ? const Color(0xFF1A237E) : Colors.grey.shade300, width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.person, color: role == 'User' ? Colors.white : Colors.grey[600]),
                                const SizedBox(height: 5),
                                Text("User", style: TextStyle(fontWeight: FontWeight.bold, color: role == 'User' ? Colors.white : Colors.grey[800])),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // ADMINISTRATOR BUTTON
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => role = 'Administrator'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: role == 'Administrator' ? const Color(0xFF1A237E) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: role == 'Administrator' ? const Color(0xFF1A237E) : Colors.grey.shade300, width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.admin_panel_settings, color: role == 'Administrator' ? Colors.white : Colors.grey[600]),
                                const SizedBox(height: 5),
                                Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, color: role == 'Administrator' ? Colors.white : Colors.grey[800])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // --- TEXT FIELDS ---
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("2. USER DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
                  const SizedBox(height: 15),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: " Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 15),
                  TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 25),
                  
                  // --- ACTIONS ---
                  isLoading ? const CircularProgressIndicator() : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), minimumSize: const Size.fromHeight(55)),
                    onPressed: register, 
                    child: const Text("REGISTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF1A237E))),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}