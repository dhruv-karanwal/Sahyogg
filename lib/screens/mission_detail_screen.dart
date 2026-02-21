import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class MissionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> missionData;

  const MissionDetailScreen({super.key, required this.missionData});

  Future<void> _launchDirections() async {
    final lat = missionData['lat'] ?? 18.5204;
    final lng = missionData['lng'] ?? 73.8567;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactAuthority() async {
    const url = 'tel:112'; // Mock emergency authority number
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = missionData['details'] ?? {};
    final score = (missionData['score'] ?? 50.0) as double;
    final isCritical = score >= 80;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          missionData['uniqueTitle'] ?? 'Mission Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: isCritical ? [
          IconButton(
            onPressed: () {
              // Critical Situation Alert
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Critical Status'),
                    ],
                  ),
                  content: const Text('This is a high-risk mission with a score above 80. Immediate coordination with local authorities is recommended.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _contactAuthority();
                      },
                      child: const Text('Call Authority'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.emergency_share, color: Colors.red),
          )
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Critical Warning Banner
            if (isCritical) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'CRITICAL SITUATION: High Priority Rescue Required.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _contactAuthority,
                      child: const Text('CONTACT NOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 1. Location & Navigation Card
            _buildSectionHeader('Location & Navigation'),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFF6C9EEB).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF6C9EEB),
                      child: Icon(Icons.location_on, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            missionData['areaName'] ?? 'Target Area',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text('Exact coordinates locked.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _launchDirections,
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.directions, color: Color(0xFF6C9EEB)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Casualty & Damage Report
            _buildSectionHeader('Damage & Casualty Report'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Alive', '${details['peopleAlive'] ?? 0}', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Injured', '${details['peopleInjured'] ?? 0}', Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Damage', details['damageLevel'] ?? 'High', Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Operational Logistics
            _buildSectionHeader('Operational Logistics'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.fastfood_outlined, 'Food Facility', details['foodFacility'] ?? 'Pending'),
            _buildDetailRow(Icons.alt_route_outlined, 'Road Blockage', details['roadBlockage'] ?? 'None'),
            _buildDetailRow(Icons.inventory_2_outlined, 'Logistics', details['logisticsStatus'] ?? 'Ready'),
            const SizedBox(height: 24),

            // 4. Medical & Support
            _buildSectionHeader('Medical & Support'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildResourceChip('First Aid', details['firstAid'] == 'Provided'),
                _buildResourceChip('Ambulance', details['ambulanceNearby'] == 'Yes'),
                _buildResourceChip('Nearest Help: ${details['nearestHelp']}', true),
              ],
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C9EEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Mission List', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String label, bool isAvailable) {
    return Chip(
      avatar: Icon(isAvailable ? Icons.check_circle : Icons.error_outline, size: 16, color: isAvailable ? Colors.green : Colors.orange),
      label: Text(label),
      backgroundColor: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
