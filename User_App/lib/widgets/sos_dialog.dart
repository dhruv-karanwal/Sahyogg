import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

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

  Future<void> _submit() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.get('describe_emergency') ?? 'Please describe the emergency')),
      );
      return;
    }

    final int people = int.tryParse(_peopleController.text) ?? 1;
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ?? 'Unknown Config';

    widget.onSubmit({
      'description': _descriptionController.text.trim(),
      'peopleCount': people,
      'emergencyType': _selectedType,
      'phone': phone,
    });
  }

  Future<void> _sendOfflineSMS() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.get('describe_emergency') ?? 'Please describe the emergency')),
      );
      return;
    }

    final int people = int.tryParse(_peopleController.text) ?? 1;
    final prefs = await SharedPreferences.getInstance();
    final String phone = prefs.getString('userPhone') ?? 'Unknown Config';
    final String type = _selectedType;
    final String desc = _descriptionController.text.trim();

    final String message = 'SOS EMERGENCY\nType: $type\nPeople: $people\nPhone: $phone\nDesc: $desc';
    
    // Direct SMS to the Admin's physical phone number
    const String adminPhone = '+919420881915'; 
    
    final Telephony telephony = Telephony.instance;

    try {
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      
      if (permissionsGranted != null && permissionsGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('sms_bg') ?? 'Sending SOS SMS in background...')),
          );
        }
        
        await telephony.sendSms(
          to: adminPhone,
          message: message,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('sms_sent') ?? 'Offline SOS SMS Sent natively!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Close the dialog
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(loc.get('sms_denied') ?? 'SMS permission denied. Cannot send offline SOS.'), backgroundColor: Colors.orange),
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error sending SMS natively: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.sos, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          Text(loc.get('request_rescue') ?? 'Request Rescue', style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('provide_details') ?? 'Please provide details to help rescue teams prioritize.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            
            // Emergency Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(loc.get('emergency_type') ?? 'Emergency Type', Icons.category),
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
              decoration: _inputDecoration(loc.get('people_affected') ?? 'People Affected', Icons.group),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(loc.get('description') ?? 'Description (e.g. stranded on roof)', Icons.description),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.get('cancel') ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(loc.get('send_online') ?? 'SEND SOS (ONLINE)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _sendOfflineSMS,
                icon: const Icon(Icons.sms, color: Colors.orange),
                label: Text(loc.get('send_sms_offline') ?? 'SEND VIA SMS (OFFLINE)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          )
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
