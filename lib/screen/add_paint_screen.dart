import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddPaintScreen extends StatefulWidget {
  const AddPaintScreen({super.key});
  @override
  State<AddPaintScreen> createState() => _AddPaintScreenState();
}

class _AddPaintScreenState extends State<AddPaintScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  Color pickedColor = Colors.blue;

  void _savePaint() async {
    if (nameCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    
    // Converts the chosen color into a Hex Code like #1A237E to save to the database
    String hex = '#${pickedColor.value.toRadixString(16).substring(2, 8).toUpperCase()}';
    
    try {
      await FirebaseFirestore.instance.collection('paints').add({
        'name': nameCtrl.text.trim(),
        'hexColor': hex,
        'currentStock': int.parse(stockCtrl.text),
        'status': 'Available',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Paint", style: TextStyle(color: Colors.white)), 
        backgroundColor: const Color(0xFF1A237E), 
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Tap the box below to pick the paint color", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            // --- THE COLOR PICKER BUTTON ---
            InkWell(
              onTap: () => showDialog(
                context: context, 
                builder: (c) => AlertDialog(
                  content: SingleChildScrollView(child: ColorPicker(pickerColor: pickedColor, onColorChanged: (c) => setState(() => pickedColor = c))),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done"))],
                )
              ),
              child: Container(
                height: 100, 
                decoration: BoxDecoration(
                  color: pickedColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400, width: 2)
                ), 
                child: const Center(
                  child: Text("  CHOOSE COLOR  ", style: TextStyle(backgroundColor: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                )
              ),
            ),
            
            const SizedBox(height: 30),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Paint Name / Brand", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Stock Quantity", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), minimumSize: const Size.fromHeight(55)),
              onPressed: _savePaint, 
              child: const Text("SAVE TO DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
            )
          ],
        ),
      ),
    );
  }
}