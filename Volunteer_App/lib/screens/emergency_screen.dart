import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emergency_service.dart';
import '../services/location_service.dart';
import '../widgets/pastel_button.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSending = false;
  bool _isRecording = false;
  bool _hasVoiceNote = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSend({bool fromVoice = false}) async {
    final emergencyService = Provider.of<EmergencyService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    setState(() {
      _isSending = true;
      if (fromVoice) _hasVoiceNote = true;
    });

    await emergencyService.triggerEmergency(
      'vol_001', 
      locationService.currentLocation,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      hasVoiceNote: _hasVoiceNote,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _showConfirmation(context);
      _descriptionController.clear();
      _hasVoiceNote = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Flare', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.emergency_share, size: 80, color: Color(0xFFEB5757)),
            const SizedBox(height: 20),
            Text(
              'Situation Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFEB5757),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type your situation below or hold the button for voice relief.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 30),
            
            // Situation Input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), // Fix dark mode contrast
              decoration: InputDecoration(
                hintText: 'Enter situation details (e.g., Heavy flood at Sector 4)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEB5757), width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Giant Pulse Button
            _buildSOSButton(),
            
            const SizedBox(height: 40),
            _buildInstructionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPressStart: (_) => setState(() => _isRecording = true),
      onLongPressEnd: (_) {
        setState(() => _isRecording = false);
        _handleSend(fromVoice: true);
      },
      onTap: () => _handleSend(fromVoice: false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 220,
        width: 220,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red.shade900 : const Color(0xFFEB5757),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEB5757).withOpacity(0.4),
              blurRadius: _isRecording ? 40 : 25,
              spreadRadius: _isRecording ? 10 : 5,
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 6),
        ),
        child: Center(
          child: _isSending
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 6)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.mic : Icons.touch_app,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isRecording ? 'RECORDING...' : 'TAP TO SEND',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const Text(
                      'HOLD FOR VOICE',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your location, text, and voice recording are sent with HIGH PRIORITY to the Admin Center.',
              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('SOS Sent Successfully'),
          ],
        ),
        content: const Text(
          'Your emergency details have been broadcasted to all command units. Help is on the way.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
