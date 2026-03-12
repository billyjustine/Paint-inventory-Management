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
  Color pickedColor = const Color(0xFF1A237E); // Default color
  bool _isLoading = false;

  // --- LOGIC: SAVE TO FIREBASE ---
  void _handleSave() async {
    // 1. Basic Validation
    if (nameCtrl.text.trim().isEmpty || stockCtrl.text.trim().isEmpty) {
      _showSnackBar("Please fill out all fields", isError: true);
      return;
    }

    int? stockValue = int.tryParse(stockCtrl.text.trim());
    if (stockValue == null) {
      _showSnackBar("Please enter a valid number for initial stock", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Convert color to Hex String
    String hex = '#${pickedColor.value.toRadixString(16).substring(2, 8).toUpperCase()}';

    try {
      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('paints').add({
        'name': nameCtrl.text.trim(),
        'hexColor': hex,
        'currentStock': stockValue,
        'status': 'Available',
      });

      // 3. Show Success Message
      _showSnackBar("Paint saved successfully!", isError: false);

      // 4. Clear the form for the next entry
      nameCtrl.clear();
      stockCtrl.clear();
      setState(() {
        pickedColor = const Color(0xFF1A237E);
      });
    } catch (e) {
      _showSnackBar("Error saving to database: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: COLOR PICKER DIALOG ---
  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Paint Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            enableAlpha: false,
            onColorChanged: (color) => setState(() => pickedColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- LOGIC: CUSTOM SNACKBAR ---
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Clean background for the card to pop
      appBar: AppBar(
        title: const Text("Inventory", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.format_paint_rounded, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Add New Paint",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 24),
                    child: Divider(height: 1, thickness: 1),
                  ),

                  // --- INPUT FIELDS ---
                  _buildTextField(
                    controller: nameCtrl,
                    label: "Paint Name / Brand",
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: stockCtrl,
                    label: "Initial Stock",
                    icon: Icons.inventory_2_rounded,
                    isNumber: true,
                  ),
                  const SizedBox(height: 24),

                  // --- COLOR PICKER ROW ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Paint Color",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        InkWell(
                          onTap: _openColorPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: pickedColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: pickedColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.touch_app_rounded, size: 20, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- ACTION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              "Add to Inventory",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to keep the code clean and consistent
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
      ),
    );
  }
}