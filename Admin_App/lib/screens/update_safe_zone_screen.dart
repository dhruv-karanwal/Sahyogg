import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateSafeZoneScreen extends StatefulWidget {
  final String disasterType;
  const UpdateSafeZoneScreen({super.key, required this.disasterType});

  @override
  State<UpdateSafeZoneScreen> createState() => _UpdateSafeZoneScreenState();
}

class _UpdateSafeZoneScreenState extends State<UpdateSafeZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'Relief Camp';
  String _selectedCategory = 'Primary Shelter';
  String _operationalStatus = 'Open';
  bool _isVisibleToPublic = true;
  bool _isSaving = false;
  // 0: None, 1: Auto-Detect, 2: Map Pick
  int _locationSource = 0; 

  final List<String> _types = ['Relief Camp', 'Shelter', 'Hospital', 'Assembly Point'];
  final List<String> _categories = ['Primary Shelter', 'Temporary Shelter', 'Medical Facility', 'Assembly Point'];
  final List<String> _operationalStatuses = ['Open', 'Temporarily Closed', 'Full'];

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _autoDetectLocation() {
    setState(() {
      _latController.text = '10.1071';
      _lngController.text = '76.3636';
      _locationSource = 1; // Auto-Detect
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location auto-detected (Mock)'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveSafeZone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final double lat = double.tryParse(_latController.text.trim()) ?? 0.0;
      final double lng = double.tryParse(_lngController.text.trim()) ?? 0.0;
      final int capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

      final data = {
        "name": _nameController.text.trim(),
        "type": _selectedType,
        "category": _selectedCategory,
        "lat": lat,
        "lng": lng,
        "capacity": capacity,
        "district": "Ernakulam", // Default/Mock as per requirements
        "city": "Aluva", // Default/Mock as per requirements
        "status": _operationalStatus == 'Open' ? 'ACTIVE' : _operationalStatus.toUpperCase(),
        "visibleToPublic": _isVisibleToPublic,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // Create a new document reference
      // Since this screen creates new zones (based on context), we use .doc() to generate a new ID.
      // If we need to support editing existing zones later, we would need an ID passed to the widget.
      await FirebaseFirestore.instance
          .collection('Disasters').doc(widget.disasterType).collection('safe_zones')
          .doc() // Auto-ID
          .set(data, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Safe Zone Saved & Synced to Firestore!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving Safe Zone: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Update Safe Zone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              theme.colorScheme.surface,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Safe Zone Name',
                          icon: Icons.place,
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          dropdownColor: const Color(0xFF1E1E1E),
                          decoration: _inputDecoration('Type', Icons.category),
                          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: const Color(0xFF1E1E1E),
                          decoration: _inputDecoration('Category', Icons.category_outlined),
                          items: _categories.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),

                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _capacityController,
                          label: 'Capacity (People)',
                          icon: Icons.people,
                          keyboardType: TextInputType.number,
                          helperText: 'Estimated maximum occupancy',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(controller: _latController, label: 'Lat', icon: Icons.map, keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(controller: _lngController, label: 'Lng', icon: Icons.map, keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _autoDetectLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Auto-Detect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Map Picker: Tap safely on simulating map')),
                                  );
                                  setState(() {
                                    _locationSource = 2; // Map Pick
                                  });
                                },
                                icon: const Icon(Icons.pin_drop),
                                label: const Text('Pick on Map'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_locationSource > 0) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_locationSource == 1 ? Colors.blue : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_locationSource == 1 ? Colors.blue : Colors.orange).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _locationSource == 1 ? Icons.auto_awesome : Icons.pin_drop,
                                  size: 16,
                                  color: _locationSource == 1 ? Colors.blue : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _locationSource == 1 
                                      ? 'Location set via Auto-Detect' 
                                      : 'Location selected on Map',
                                  style: TextStyle(
                                    color: _locationSource == 1 ? Colors.blue : Colors.orange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 16),
                         DropdownButtonFormField<String>(
                            value: _operationalStatus,
                            dropdownColor: const Color(0xFF1E1E1E),
                            decoration: _inputDecoration('Operational Status', Icons.info_outline),
                            items: _operationalStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _operationalStatus = v!),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Visible to Public', style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                              _isVisibleToPublic ? 'Visible on citizen apps' : 'Hidden (Authority only)',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            value: _isVisibleToPublic,
                            activeColor: Colors.green,
                            onChanged: (val) => setState(() => _isVisibleToPublic = val),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSafeZone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE & SYNC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Last updated by: Admin',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated at: ${DateTime.now().toString().split('.')[0]}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon).copyWith(helperText: helperText, helperStyle: const TextStyle(color: Colors.white38)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
