import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/volunteer_repository.dart';
import '../main.dart'; // For routing
import '../widgets/pastel_button.dart'; // Using standard app button

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({super.key});

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();
  String _selectedBloodGroup = 'O+';
  bool _isLoading = false;

  final List<String> _bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _registerVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = Provider.of<VolunteerRepository>(context, listen: false);
    
    // For this prototype, we are directly writing to the active 'vol_001' document
    // which is hardcoded across the demo's backend logic.
    final List<String> skills = _skillsController.text.split(',').map((s) => s.trim()).toList();
    
    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'skills': skills.isEmpty ? ['Search & Rescue', 'First Aid'] : skills,
      'bloodGroup': _selectedBloodGroup,
      'isOnDuty': false,
      'rating': 5.0,
      'totalMissions': 0,
      'dutyStartTime': null,
      'email': 'volunteer@sahyog.org',
      'volunteerId': 'VOL-NEW',
      'preferredDisasterType': 'Flood Relief',
      'operationRadius': 15.0,
      'hasVehicle': true,
      'isDeadManAlertEnabled': false,
      'isLocationSharingEnabled': true,
    };

    await FirebaseFirestore.instance.collection('volunteers').doc('vol_001').set(payload, SetOptions(merge: true));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Join Sahyog', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.volunteer_activism, size: 80, color: Color(0xFF6C9EEB)),
              const SizedBox(height: 24),
              Text(
                'Volunteer Registration',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step up to serve during critical disaster operations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.bloodtype),
                ),
                items: _bloodGroups.map((bg) {
                  return DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(color: Colors.black87)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBloodGroup = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _skillsController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Skills (comma separated)',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'e.g., First Aid, Driving, Swimming',
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.build),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C9EEB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _registerVolunteer,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'COMPLETE REGISTRATION',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
