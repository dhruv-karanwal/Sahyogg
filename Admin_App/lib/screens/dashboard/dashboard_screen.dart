import 'package:apps/controllers/lg_controller.dart';
import 'package:apps/controllers/ssh_controller.dart';
import 'package:apps/controllers/settings_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:apps/screens/dashboard/widgets/kpi_card.dart';
import 'package:apps/screens/dashboard/analytics_detail_screen.dart';
import 'package:apps/services/safe_zone_ingestion_service.dart';
import 'package:apps/services/resource_ingestion_service.dart';
import 'package:apps/services/sos_management_service.dart';
import 'package:apps/screens/broadcast_advisory_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String disasterType;
  const DashboardScreen({super.key, required this.disasterType});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _timeFilter = 'Live'; // Live, 1H, 24H, 7D
  
  // Initialize controllers
  late final SSHController _sshController;
  late final SettingsController _settingsController;
  late final LGController _lgController;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    _sshController = SSHController();
    _settingsController = SettingsController();
    _lgController = LGController(
      sshController: _sshController,
      settingsController: _settingsController,
    );
    
    // Auto-connect to LG if settings exist
    _autoConnectToLG();
  }
  
  Future<void> _autoConnectToLG() async {
    try {
      final settings = await _settingsController.loadSettings();
      final host = settings['host'] as String;
      final port = settings['port'] as int;
      final username = settings['username'] as String;
      final password = settings['password'] as String;
      
      await _lgController.connect(
        host: host,
        port: port,
        username: username,
        password: password,
      );
      
      if (mounted && _lgController.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Liquid Galaxy'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-connect to LG failed: $e');
    }
  }
  
  @override
  void dispose() {
    _lgController.disconnect();
    super.dispose();
  }

  // Firestore Streams
  Stream<QuerySnapshot> get _sosStream => FirebaseFirestore.instance
      .collection('Disasters')
      .doc('Flood')
      .collection('rescue_requests')
      .snapshots();

  Stream<QuerySnapshot> get _safeZonesStream => FirebaseFirestore.instance
      .collection('Disasters')
      .doc('Flood')
      .collection('safe_zones')
      .snapshots();

  Stream<QuerySnapshot> get _incomingSmsStream => FirebaseFirestore.instance
      .collection('Disasters')
      .doc('Flood')
      .collection('incoming_sms')
      .snapshots();

  Stream<QuerySnapshot> get _routesStream => FirebaseFirestore.instance
      .collection('floods')
      .doc('kerela-flood')
      .collection('routes')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildTimeFilters(),
                    const SizedBox(height: 24),
                    _buildKpiGrid(),
                    const SizedBox(height: 24),
                    _buildSmartInsights(),
                    const SizedBox(height: 24),
                    _buildLiveSosFeed(),
                    const SizedBox(height: 24),
                    _buildLiveSmsFeed(),
                    const SizedBox(height: 24),
                    _buildTopRiskZones(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics & Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Real-time disaster overview',
                style: TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildLGConnectionIndicator(),
      ],
    );
  }
  
  Widget _buildLGConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _lgController.isConnected 
          ? Colors.green.withOpacity(0.2) 
          : Colors.grey.withOpacity(0.2),
        border: Border.all(
          color: _lgController.isConnected ? Colors.green : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _lgController.isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: _lgController.isConnected
                ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4)]
                : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _lgController.isConnected ? 'LG CONNECTED' : 'LG OFFLINE',
            style: TextStyle(
              color: _lgController.isConnected ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _sosStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final count = snapshot.data!.docs.where((doc) { 
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            return status != 'RESOLVED';
        }).length;

        String level = 'LOW';
        Color color = Colors.green;

        if (count >= 60) {
          level = 'HIGH';
          color = Colors.red;
        } else if (count >= 20) {
          level = 'MEDIUM';
          color = Colors.orange;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$level RISK',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Live', '1H', '24H', '7D'];
    return Row(
      children: [
        _buildRiskBadge(),
        const Spacer(),
        PopupMenuButton<String>(
          initialValue: _timeFilter,
          onSelected: (String value) {
            setState(() {
              _timeFilter = value;
            });
          },
          color: const Color(0xFF141A26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (BuildContext context) {
            return filters.map((String choice) {
              final isSelected = _timeFilter == choice;
              return PopupMenuItem<String>(
                value: choice,
                child: Row(
                  children: [
                    Text(
                      choice,
                      style: TextStyle(
                        color: isSelected ? Colors.tealAccent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16, color: Colors.tealAccent),
                    ]
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
             _buildSosKpi(),
             _buildRiskZonesKpi(),
             _buildSheltersKpi(),
             _buildBlockedRoutesKpi(),
          ],
        );
      },
    );
  }
  
  Widget _buildSosKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              final count = snapshot.data?.docs.length ?? 0;
              
              return KpiCard(
                  title: 'Total SOS',
                  value: count.toString(),
                  icon: Icons.sos,
                  color: Colors.redAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('SOS Requests'),
              );
          },
      );
  }

  Widget _buildRiskZonesKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int highRiskCount = 0;
              
              if (snapshot.hasData) {
                  final Map<String, int> areaCounts = {};
                  for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final area = data['area'] ?? data['city'] ?? 'Unknown';
                      areaCounts[area] = (areaCounts[area] ?? 0) + 1;
                  }
                  
                  highRiskCount = areaCounts.values.where((c) => c >= 10).length;
              }

              return KpiCard(
                  title: 'High Risk Zones',
                  value: highRiskCount.toString(),
                  icon: Icons.warning_amber,
                  color: Colors.orangeAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('High Risk Zones'),
              );
          },
      );
  }

  Widget _buildSheltersKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _safeZonesStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int activeCount = 0;
              
              if (snapshot.hasData) {
                  activeCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] as String? ?? 'Open';
                      return status == 'Open' || status == 'Active' || status == 'ACTIVE';
                  }).length;
              }

              return KpiCard(
                  title: 'Active Shelters',
                  value: activeCount.toString(),
                  icon: Icons.shield_outlined,
                  color: Colors.greenAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('Active Shelters'),
              );
          },
      );
  }

  Widget _buildBlockedRoutesKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _routesStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int blockedCount = 0;
              
              if (snapshot.hasData) {
                  blockedCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isBlocked'] == true;
                  }).length;
              }

              return KpiCard(
                  title: 'Blocked Routes',
                  value: blockedCount.toString(),
                  icon: Icons.remove_road,
                  color: Colors.purpleAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('Blocked Routes'),
              );
          },
      );
  }

  void _navigateToDetail(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDetailScreen(
          type: type,
          disasterType: widget.disasterType,
          lgController: _lgController,
          sshController: _sshController,
        ),
      ),
    );
  }

  Widget _buildSmartInsights() {
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
               if(!snapshot.hasData) return const SizedBox.shrink();
               
               final docs = snapshot.data!.docs;
               final List<Widget> insights = [];
               
               if (docs.length > 50) {
                   insights.add(_buildInsightTile('High SOS Volume Detected', Icons.trending_up, Colors.red));
               }
               
               if (insights.isEmpty) {
                   return const SizedBox.shrink();
               }

               return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                       const Text('Smart Insights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       SingleChildScrollView(
                           scrollDirection: Axis.horizontal,
                           child: Row(children: insights),
                       ),
                   ],
               );
          },
      );
  }
  
  Widget _buildInsightTile(String text, IconData icon, Color color) {
      return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
              children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }

  Widget _buildLiveSosFeed() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('Live SOS Feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                  stream: _sosStream,
                  builder: (context, snapshot) {
                       if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                       if(snapshot.data!.docs.isEmpty) return const Text('No recent SOS requests', style: TextStyle(color: Colors.grey));
                       
                       final docs = snapshot.data!.docs;
                       docs.sort((a,b) {
                           final dataA = a.data() as Map<String, dynamic>;
                           final dataB = b.data() as Map<String, dynamic>;
                           
                           // 1. Sort by Priority (RED > ORANGE > YELLOW > WHITE)
                           final priorityA = _getPriorityValue(dataA['priority'] as String?);
                           final priorityB = _getPriorityValue(dataB['priority'] as String?);
                           
                           if (priorityA != priorityB) {
                             return priorityA.compareTo(priorityB); // Lower number = higher priority
                           }
                           
                           // 2. Sort by Timestamp (Newest first)
                           final tA = dataA['timestamp'] as Timestamp?;
                           final tB = dataB['timestamp'] as Timestamp?;
                           
                           if(tA == null) return 1; 
                           if(tB == null) return -1;
                           return tB.compareTo(tA);
                       });
                       
                       final latest = docs.take(5).toList();
                       
                       return Container(
                           decoration: BoxDecoration(
                               color: const Color(0xFF141A26),
                               borderRadius: BorderRadius.circular(16),
                           ),
                           child: ListView.separated(
                               padding: EdgeInsets.zero,
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               itemCount: latest.length,
                               separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                               itemBuilder: (context, index) {
                                   final data = latest[index].data() as Map<String, dynamic>;
                                   final area = data['area'] ?? data['city'] ?? 'Unknown Area';
                                   final priority = data['priority'] ?? 'MEDIUM';
                                   final status = data['status'] ?? 'PENDING';
                                   final time = _formatTimestamp(data['timestamp']);
                                   
                                   Color statusColor = Colors.grey;
                                   if (status == 'PENDING') statusColor = Colors.orange;
                                   if (status == 'RESOLVED') statusColor = Colors.green;
                                   
                                   Color avatarColor = Colors.grey;
                                   if (priority == 'RED') avatarColor = Colors.red;
                                   if (priority == 'ORANGE') avatarColor = Colors.orange;
                                   if (priority == 'YELLOW') avatarColor = Colors.yellow;
                                   if (priority == 'WHITE') avatarColor = Colors.white;

                                   return ListTile(
                                       leading: CircleAvatar(
                                           backgroundColor: avatarColor.withOpacity(0.2),
                                           child: Icon(Icons.sos, color: avatarColor, size: 18),
                                       ),
                                       title: Text(area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                       subtitle: Text('$priority • $time', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                       trailing: Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                           decoration: BoxDecoration(
                                               color: statusColor.withOpacity(0.2),
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(color: statusColor.withOpacity(0.5)),
                                           ),
                                           child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                       ),
                                   );
                               },
                           ),
                       );
                  },
              ),
          ],
      );
  }
  
  Widget _buildLiveSmsFeed() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Row(
                children: [
                  Icon(Icons.sms, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Raw Incoming SMS Feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                  stream: _incomingSmsStream,
                  builder: (context, snapshot) {
                       if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                       if(snapshot.data!.docs.isEmpty) return const Text('No incoming SMS records yet.', style: TextStyle(color: Colors.grey));
                       
                       final docs = snapshot.data!.docs;
                       docs.sort((a,b) {
                           final dataA = a.data() as Map<String, dynamic>;
                           final dataB = b.data() as Map<String, dynamic>;
                           
                           final tA = dataA['timestamp'] as Timestamp?;
                           final tB = dataB['timestamp'] as Timestamp?;
                           
                           if(tA == null && tB == null) return 0;
                           if(tA == null) return 1; 
                           if(tB == null) return -1;
                           return tB.compareTo(tA);
                       });
                       
                       // Show max 10 recent messages
                       final latest = docs.take(10).toList();
                       
                       return Container(
                           decoration: BoxDecoration(
                               color: const Color(0xFF141A26),
                               borderRadius: BorderRadius.circular(16),
                           ),
                           child: ListView.separated(
                               padding: EdgeInsets.zero,
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               itemCount: latest.length,
                               separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                               itemBuilder: (context, index) {
                                   final data = latest[index].data() as Map<String, dynamic>;
                                   final sender = data['sender'] ?? 'Unknown Sender';
                                   final body = data['body'] ?? '';
                                   final time = _formatTimestamp(data['timestamp']);

                                   return ListTile(
                                       leading: CircleAvatar(
                                           backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                           child: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 18),
                                       ),
                                       title: Text(sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                       subtitle: Padding(
                                         padding: const EdgeInsets.only(top: 4.0),
                                         child: Text(body, style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                                       ),
                                       trailing: Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                   );
                               },
                           ),
                       );
                  },
              ),
          ],
      );
  }

  String _formatTimestamp(dynamic timestamp) {
      if (timestamp == null) return 'Just now';
      if (timestamp is Timestamp) {
          final dt = timestamp.toDate();
          return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return 'Just now';
  }

  int _getPriorityValue(String? priority) {
    if (priority == null) return 2; // Default to Medium
    
    final p = priority.toUpperCase();
    if (p == 'RED') return 0;
    if (p == 'ORANGE') return 1;
    if (p == 'YELLOW') return 2;
    if (p == 'WHITE') return 3;
    
    return 2; // Default
  }

  Widget _buildTopRiskZones() {
       return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('Top Risk Zones', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                  stream: _sosStream,
                  builder: (context, snapshot) {
                      if(!snapshot.hasData) return const SizedBox.shrink();
                      
                       final Map<String, int> areaCounts = {};
                       for (var doc in snapshot.data!.docs) {
                           final data = doc.data() as Map<String, dynamic>;
                           final area = data['area'] ?? data['city'] ?? 'Unknown';
                           areaCounts[area] = (areaCounts[area] ?? 0) + 1;
                       }
                       
                       var sortedKeys = areaCounts.keys.toList(growable: false)
                        ..sort((k1, k2) => areaCounts[k2]!.compareTo(areaCounts[k1]!));
                        
                       final top5 = sortedKeys.take(5).toList();
                       
                       return SizedBox(
                           height: 120,
                           child: ListView.builder(
                               scrollDirection: Axis.horizontal,
                               itemCount: top5.length,
                               itemBuilder: (context, index) {
                                   final area = top5[index];
                                   final count = areaCounts[area]!;
                                   
                                   return Container(
                                       width: 140,
                                       margin: const EdgeInsets.only(right: 12),
                                       padding: const EdgeInsets.all(16),
                                       decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                               begin: Alignment.topLeft,
                                               end: Alignment.bottomRight,
                                               colors: [
                                                   Colors.red.withOpacity(0.2),
                                                   Colors.orange.withOpacity(0.1),
                                               ],
                                           ),
                                           borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                                       ),
                                       child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                               Text(area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                               const SizedBox(height: 8),
                                               Text('$count SOS', style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('Critical', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                                           ],
                                       ),
                                   );
                               },
                           ),
                       );
                  },
              ),
          ],
       );
  }

  Widget _buildQuickActions() {
      return Column(
        children: [
          Row(
              children: [
                  Expanded(child: _buildActionButton('Broadcast Alert', Icons.campaign, Colors.orange, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BroadcastAdvisoryScreen(disasterType: widget.disasterType)),
                      );
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Cast to LG', Icons.cast_connected, Colors.blue, () async {
                      if (!_lgController.isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please connect to Liquid Galaxy first'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Casting hotspots to Liquid Galaxy...')));
                  })),
                  const SizedBox(width: 12),
                    Expanded(child: _buildActionButton('Export Report', Icons.download, Colors.green, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting summary report...')));
                  })),
                  Expanded(child: _buildActionButton('Ingest Data', Icons.cloud_upload, Colors.teal, () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingesting authoritative safe zones & Volunteer Resources...')));
                      try {
                        final service = SafeZoneIngestionService(widget.disasterType);
                        final count = await service.ingestSafeZones();

                        // ALSO INGEST THE VOLUNTEER PUNE RESOURCES!
                        final resourceService = ResourceIngestionService();
                        final resourceCount = await resourceService.ingestPuneResources();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingested $count scenario zones & $resourceCount Pune resources!'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                             if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingestion failed: $e'), backgroundColor: Colors.red));
                            }
                          }
                      })),
                  ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionButton('Reset SOS DB', Icons.restore, Colors.orange, () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resetting SOS Database...')));
                    try {
                      final service = SOSManagementService(widget.disasterType);
                      await service.cleanupSOSRequests();
                      await service.seedRealisticSOSData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Database Cleaned & Rebuilt!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                       if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset failed: $e'), backgroundColor: Colors.red));
                      }
                    }
                  })),
                  const SizedBox(width: 12),
                    Expanded(child: _buildActionButton('Migrate SOS DB', Icons.upgrade, Colors.purple, () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Migrating Old SOS Tickets...')));
                      try {
                        final service = SOSManagementService(widget.disasterType);
                        await service.migrateOldSOSToNewPriorityTiers();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Legacy SOS DB Migrated!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                         if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Migration failed: $e'), backgroundColor: Colors.red));
                        }
                      }
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionButton('Refresh Data', Icons.refresh, Colors.tealAccent, () {
                       setState(() {}); // Trigger stream rebuild
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feed Refreshed Manually')));
                    })),
                ],
              ),
            ],
          );
      }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                  children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(height: 8),
                      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ],
              ),
          ),
      );
  }
}