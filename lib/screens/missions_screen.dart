import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/mission_service.dart';
import '../services/dispatch_service.dart';
import '../services/volunteer_repository.dart';
import '../models/volunteer_model.dart';
import '../models/mission_model.dart';
import '../widgets/mission_card.dart';

import '../screens/mission_detail_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  String _selectedPriority = 'All';

  int _getPriorityValue(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'critical':
        return 3;
      case 'moderate':
      case 'medium':
        return 2;
      case 'low':
      case 'least':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionService = Provider.of<MissionService>(context);
    final dispatchService = Provider.of<DispatchService>(context);
    final volunteerRepo = Provider.of<VolunteerRepository>(context);
    const volunteerId = 'vol_001';

    return StreamBuilder<VolunteerModel>(
      stream: volunteerRepo.getVolunteerProfile(volunteerId),
      builder: (context, vSnapshot) {
        if (!vSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final volunteer = vSnapshot.data!;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final navNotifier = Provider.of<ValueNotifier<int>>(context, listen: false);
                  navNotifier.value = 0; // Go back to Dashboard
                },
              ),
              title: const Text('Missions', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list_rounded),
                  onSelected: (val) => setState(() => _selectedPriority = val),
                  itemBuilder: (context) => ['All', 'High', 'Moderate', 'Low'].map((p) => 
                    PopupMenuItem(value: p, child: Text(p))
                  ).toList(),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Available'),
                  Tab(text: 'My Active'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildAvailableMissions(context, missionService, dispatchService, volunteer),
                _buildMyActiveMissions(context, missionService, dispatchService, volunteerId),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAvailableMissions(
    BuildContext context, 
    MissionService missionService, 
    DispatchService dispatchService,
    VolunteerModel volunteer
  ) {
    final locationService = Provider.of<LocationService>(context);

    return StreamBuilder<LatLng>(
      stream: locationService.locationStream,
      builder: (context, locSnapshot) {
        final currentPos = locSnapshot.data ?? locationService.currentLocation;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: missionService.getRescueRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No active rescue requests'));
            }

            // 1. Initial Processing (Filter by status, then score + Unique Name)
            var processed = snapshot.data!
              .where((r) => r['status'] != 'accepted') // DON'T SHOW ACCEPTED MISSIONS
              .map((r) {
                final score = dispatchService.calculatePriorityScore(r, currentPos);
                final uniqueTitle = dispatchService.generateMissionName(r);
                return {
                  ...r,
                  'score': score,
                  'uniqueTitle': uniqueTitle,
                  'details': dispatchService.generateDetailedMetadata(r),
                };
              }).toList();

            // 2. Skill Filter
            var filtered = dispatchService.filterRequestsBySkills(processed, volunteer.skills);

            // 3. Priority Filter (Manual)
            if (_selectedPriority != 'All') {
              filtered = filtered.where((r) {
                final score = r['score'] as double;
                if (_selectedPriority == 'High') return score >= 70;
                if (_selectedPriority == 'Moderate') return score >= 40 && score < 70;
                if (_selectedPriority == 'Low') return score < 40;
                return true;
              }).toList();
            }

            // 4. Dynamic Sorting (Default: Newest First | Filtered: Priority Score)
            if (_selectedPriority == 'All') {
              filtered.sort((a, b) {
                final aTime = a['timestamp'];
                final bTime = b['timestamp'];
                
                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime); // Newest first
                }
                return 0;
              });
            } else {
              filtered.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
            }

            if (filtered.isEmpty) {
              return const Center(child: Text('No matching missions found'));
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final request = filtered[index];
                return MissionCard(
                  request: request,
                  onTap: () => _confirmAccept(context, missionService, volunteer.id, request),
                );
              },
            );
          },
        );
      }
    );
  }

  Widget _buildMyActiveMissions(
    BuildContext context, 
    MissionService service, 
    DispatchService dispatchService,
    String volunteerId
  ) {
    final volunteerRepo = Provider.of<VolunteerRepository>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    final currentPos = locationService.currentLocation;

    return StreamBuilder<List<MissionModel>>(
      stream: service.getActiveMissions(volunteerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('You have no active missions'));
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.getRescueRequests(),
          builder: (context, reqSnapshot) {
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final mission = snapshot.data![index];
                final isInProgress = mission.status == MissionStatus.in_progress;
                
                // Find matching rescue request to get positional data & titles
                Map<String, dynamic>? baseRequest;
                if (reqSnapshot.hasData && reqSnapshot.data != null) {
                  try {
                    baseRequest = reqSnapshot.data!.firstWhere(
                      (r) => r['id'] == mission.rescueRequestId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (baseRequest.isEmpty) baseRequest = null;
                  } catch (_) {
                    baseRequest = null;
                  }
                }

                final score = baseRequest != null 
                    ? dispatchService.calculatePriorityScore(baseRequest, currentPos) 
                    : 50.0;
                
                final title = baseRequest != null 
                    ? dispatchService.generateMissionName(baseRequest) 
                    : 'Mission #${mission.id.length > 5 ? mission.id.substring(0, 5) : mission.id}';
                
                final fullData = {
                  ... (baseRequest ?? {}),
                  'score': score,
                  'uniqueTitle': title,
                  'details': baseRequest != null 
                      ? dispatchService.generateDetailedMetadata(baseRequest) 
                      : dispatchService.generateDetailedMetadata({}),
                };

                return MissionCard(
                  request: fullData,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MissionDetailScreen(missionData: fullData)),
                    );
                  },
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInProgress ? const Color(0xFF6FCF97) : const Color(0xFF6C9EEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          if (mission.status == MissionStatus.assigned) {
                            await service.updateMissionStatus(mission.id, MissionStatus.in_progress);
                          } else if (mission.status == MissionStatus.in_progress) {
                            await service.updateMissionStatus(mission.id, MissionStatus.completed);
                            await volunteerRepo.incrementMissions(volunteerId);
                            _showSuccessDialog(context);
                          }
                        },
                        child: Text(
                          isInProgress ? 'Complete' : 'Start',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isInProgress ? Colors.green : Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mission Accomplished!'),
        content: const Text('Great job, volunteer. Your stats have been updated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _confirmAccept(BuildContext context, MissionService service, String vId, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Accept Mission?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('By accepting, you agree to help with "${request['title']}". Your location will be shared with the citizen.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      service.acceptMission(vId, request['id']);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mission Accepted!')),
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
