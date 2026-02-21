import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../services/safe_zone_lg_service.dart';
import '../widgets/custom_glass_card.dart';

class ShelterListScreen extends StatefulWidget {
  final LGController lgController;
  final String disasterType;

  const ShelterListScreen({
    super.key,
    required this.lgController,
    required this.disasterType,
  });

  @override
  State<ShelterListScreen> createState() => _ShelterListScreenState();
}

class _ShelterListScreenState extends State<ShelterListScreen> {
  late SafeZoneLGService _lgService;
  bool _isCasting = false;

  @override
  void initState() {
    super.initState();
    _lgService = SafeZoneLGService(widget.lgController, widget.disasterType);
  }

  Future<void> _castAll() async {
    setState(() => _isCasting = true);
    try {
      await _lgService.castAllShelters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Casting ALL visible shelters to LG...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cast shelters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCasting = false);
    }
  }

  Future<void> _castStrategic() async {
    setState(() => _isCasting = true);
    try {
      await _lgService.castStrategicOverview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Launching Strategic Overview (High Altitude, Large Icons)...'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cast strategic overview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCasting = false);
    }
  }

  Future<void> _castShelter(String id, String name) async {
    try {
      await _lgService.castShelter(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Casting "$name" to LG...'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cast "$name": $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return Colors.greenAccent;
      case 'FULL': return Colors.orangeAccent;
      case 'CLOSED': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Shelter Visualization'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isCasting 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _castStrategic,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Strategic Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _castAll,
                    icon: const Icon(Icons.cast_connected),
                    label: const Text('Cast All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1c2e),
              const Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Disasters').doc(widget.disasterType).collection('safe_zones')
                .where('visibleToPublic', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return const Center(child: Text('No shelters found.', style: TextStyle(color: Colors.white70)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  final name = data['name'] ?? 'Unnamed Shelter';
                  final type = data['type'] ?? 'Shelter';
                  final district = data['district'] ?? 'N/A';
                  final status = data['status'] ?? 'OPEN';
                  final capacity = data['capacity']?.toString() ?? 'N/A';
                  final isClosed = status == 'CLOSED';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CustomGlassCard(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            type == 'Hospital' ? Icons.local_hospital 
                            : type == 'Relief Camp' ? Icons.holiday_village
                            : Icons.home,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('$type • $district', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.white60),
                                const SizedBox(width: 4),
                                Text('Cap: $capacity', style: const TextStyle(color: Colors.white60)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cast),
                          color: isClosed ? Colors.grey : Colors.lightBlueAccent,
                          tooltip: isClosed ? 'Cannot cast CLOSED shelter' : 'Cast to LG',
                          onPressed: isClosed ? null : () => _castShelter(id, name),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
