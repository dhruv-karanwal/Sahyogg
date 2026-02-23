import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/volunteer_repository.dart';
import '../models/volunteer_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi', 'Marathi'];

  @override
  void dispose() {
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _updateProfile(String volunteerId, Map<String, dynamic> data) async {
    final repo = Provider.of<VolunteerRepository>(context, listen: false);
    await repo.updateProfile(volunteerId, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final volunteerRepo = Provider.of<VolunteerRepository>(context);
    const volunteerId = 'vol_001';

    return StreamBuilder<VolunteerModel>(
      stream: volunteerRepo.getVolunteerProfile(volunteerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final volunteer = snapshot.data!;
        
        // Initialize controllers if empty
        if (_phoneController.text.isEmpty) _phoneController.text = volunteer.phone;
        if (_emailController.text.isEmpty) _emailController.text = volunteer.email;
        if (_emergencyNameController.text.isEmpty) _emergencyNameController.text = volunteer.emergencyContactName;
        if (_emergencyPhoneController.text.isEmpty) _emergencyPhoneController.text = volunteer.emergencyContactPhone;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Operational Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.qr_code_scanner, color: Colors.blue)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactHeader(context, volunteer),
                const SizedBox(height: 24),
                
                // 1. Basic Info
                _buildSectionHeader('BASIC INFORMATION'),
                _buildBasicInfo(context, volunteerId),
                
                const SizedBox(height: 24),
                
                // 2. Skills & Proficiency
                _buildSectionHeader('SKILLS & PROFICIENCY'),
                _buildSkillsSection(context, volunteer),
                
                const SizedBox(height: 24),
                
                // 3. Availability & Preferences
                _buildSectionHeader('AVAILABILITY & LOGISTICS'),
                _buildAvailabilitySection(context, volunteerId, volunteer),
                
                const SizedBox(height: 24),
                
                // 4. Safety Settings
                _buildSectionHeader('SAFETY & PROTOCOLS'),
                _buildSafetySection(context, volunteerId, volunteer),
                
                const SizedBox(height: 24),
                
                // 5. App Settings
                _buildSectionHeader('APP SETTINGS'),
                _buildAppSettings(context),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'App Version 1.0.0-HACKATHON',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, VolunteerModel volunteer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6C9EEB).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C9EEB).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6C9EEB),
            child: Text(
              volunteer.name.substring(0, 1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  volunteer.volunteerId,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bloodtype, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(volunteer.bloodGroup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, String volunteerId) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileEditField('Phone Number', _phoneController, Icons.phone, 'phone', volunteerId),
            const Divider(),
            _buildProfileEditField('Email Address', _emailController, Icons.email, 'email', volunteerId),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditField(String label, TextEditingController controller, IconData icon, String field, String volunteerId) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade400, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      subtitle: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        onSubmitted: (val) => _updateProfile(volunteerId, {field: val}),
      ),
      trailing: const Icon(Icons.edit, size: 16, color: Colors.blue),
    );
  }

  Widget _buildSkillsSection(BuildContext context, VolunteerModel volunteer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: volunteer.skills.map((skill) => _buildSkillChip(skill, volunteer)).toList(),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {}, // Add skill dialog
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Skill', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill, VolunteerModel volunteer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: Colors.green, size: 14),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(BuildContext context, String volunteerId, VolunteerModel volunteer) {
    const textStyle = TextStyle(color: Colors.black87);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.emergency_outlined, color: Colors.orangeAccent),
              title: const Text('Preferred Disaster', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: Text(volunteer.preferredDisasterType, style: textStyle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.radar, color: Colors.blueAccent),
              title: const Text('Operation Radius', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: Text('${volunteer.operationRadius.toInt()} km', style: textStyle),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: volunteer.operationRadius,
                  min: 5,
                  max: 50,
                  onChanged: (val) => _updateProfile(volunteerId, {'operationRadius': val}),
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.directions_car_filled_outlined, color: Colors.purpleAccent),
              title: const Text('Vehicle Available', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              value: volunteer.hasVehicle,
              onChanged: (val) => _updateProfile(volunteerId, {'hasVehicle': val}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetySection(BuildContext context, String volunteerId, VolunteerModel volunteer) {
    const textStyle = TextStyle(color: Colors.black87);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.contact_phone_outlined, color: Colors.redAccent),
              title: const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: Text(volunteer.emergencyContactName.isEmpty ? 'Not Set' : '${volunteer.emergencyContactName} (${volunteer.emergencyContactPhone})', style: textStyle),
              onTap: () => _showEmergencyDialog(context, volunteerId),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.health_and_safety_outlined, color: Colors.teal),
              title: const Text('Dead-Man Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: const Text('Auto-SOS if inactive during mission', style: TextStyle(fontSize: 10, color: Colors.black54)),
              value: volunteer.isDeadManAlertEnabled,
              onChanged: (val) => _updateProfile(volunteerId, {'isDeadManAlertEnabled': val}),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.share_location_outlined, color: Colors.blue),
              title: const Text('Location Sharing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              value: volunteer.isLocationSharingEnabled,
              onChanged: (val) => _updateProfile(volunteerId, {'isLocationSharingEnabled': val}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.language, color: Colors.blueGrey),
        title: const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: DropdownButton<String>(
          value: _selectedLanguage,
          underline: const SizedBox(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 13),
          items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (val) => setState(() => _selectedLanguage = val!),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context, String volunteerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(labelText: 'Name'),
              style: const TextStyle(color: Colors.black87),
            ),
            TextField(
              controller: _emergencyPhoneController, 
              decoration: const InputDecoration(labelText: 'Phone'),
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _updateProfile(volunteerId, {
                'emergencyContactName': _emergencyNameController.text,
                'emergencyContactPhone': _emergencyPhoneController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
