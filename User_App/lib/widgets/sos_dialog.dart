import 'package:flutter/material.dart';

class SOSDialog extends StatefulWidget {
  final Function(Map<String, dynamic> data) onSubmit;
  final bool isSending;

  const SOSDialog({
    super.key,
    required this.onSubmit,
    this.isSending = false,
  });

  @override
  State<SOSDialog> createState() => _SOSDialogState();
}

class _SOSDialogState extends State<SOSDialog> {
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController(text: '1');
  String _selectedType = 'Trapped';
  
  final List<String> _types = [
    'Trapped',
    'Medical Emergency',
    'Flooded House',
    'Evacuation Needed',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the emergency')),
      );
      return;
    }

    final int people = int.tryParse(_peopleController.text) ?? 1;

    widget.onSubmit({
      'description': _descriptionController.text.trim(),
      'peopleCount': people,
      'emergencyType': _selectedType,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.sos, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          const Text('Request Rescue', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide details to help rescue teams prioritize.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            
            // Emergency Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Emergency Type', Icons.category),
              items: _types.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t),
              )).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),

            // Number of People
            TextField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('People Affected', Icons.group),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description (e.g. stranded on roof)', Icons.description),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isSending)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SEND SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white60, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}
