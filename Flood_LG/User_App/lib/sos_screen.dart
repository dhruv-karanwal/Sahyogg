import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'services/sos_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _sending = false;

  String? _trackerDocId;

  Future<void> sendSOS() async {
    try {
      setState(() => _sending = true);
      
      // 1. Check Permissions (Simplified for brevity, assuming existing logic or service handles it if moved to service. 
      // But SOSService expects lat/lng. So I still need geolocator here.)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled';
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw 'Location permission denied';

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final docId = await SOSService().sendSOS(
        latitude: position.latitude,
        longitude: position.longitude,
        userId: SOSService().currentUserId,
      );

      setState(() {
        _trackerDocId = docId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Sent! Tracking status...'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red.shade900,
      ),
      body: Center(
        child: _trackerDocId == null
          ? ElevatedButton(
              onPressed: _sending ? null : sendSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SEND SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: SOSService().listenToSOS(_trackerDocId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const Text('Request not found');
                
                final status = data['status'] ?? 'PENDING';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 80, color: status == 'ACKNOWLEDGED' ? Colors.green : Colors.orange),
                    const SizedBox(height: 16),
                    Text('Status: $status', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Help is being coordinated.', style: TextStyle(color: Colors.grey)),
                  ],
                );
              },
            ),
      ),
    );
  }
}
