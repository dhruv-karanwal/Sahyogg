import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../advisory_screen.dart';

class LiveAdvisoryBanner extends StatefulWidget {
  final String disasterType;
  const LiveAdvisoryBanner({super.key, required this.disasterType});

  @override
  State<LiveAdvisoryBanner> createState() => _LiveAdvisoryBannerState();
}

class _LiveAdvisoryBannerState extends State<LiveAdvisoryBanner>
    with SingleTickerProviderStateMixin {
  // State
  Map<dynamic, dynamic>? _currentAdvisory;
  bool _isVisible = false;
  bool _isCompact = false;
  Timer? _compactTimer;
  int _lastTimestamp = 0;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // Animation
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _listenToAdvisories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _compactTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToAdvisories() {
    print('LiveAdvisoryBanner: Initializing Firestore listener...');
    
    // Listen to the 'current' document in the 'advisories' subcollection under 'Disasters/disasterType'
    // This matches what we updated the Admin App to write to.
    final advisoryRef = FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('advisories').doc('current');
    
    // Note: We use snapshots() for Firestore
    _subscription = advisoryRef.snapshots().listen((snapshot) {
      if (!mounted) return;
      print('LiveAdvisoryBanner: Received event from Firestore: ${snapshot.exists ? snapshot.data() : "Doc not found"}');

      if (!snapshot.exists || snapshot.data() == null) {
        print('LiveAdvisoryBanner: Doc does not exist or data is null');
        _hide();
        return;
      }

      final data = snapshot.data()!;
      
      // Active check
      bool isActive = false;
      final dynamic isActiveRaw = data['isActive'];
      if (isActiveRaw is bool) {
        isActive = isActiveRaw;
      } else if (isActiveRaw is String) {
        isActive = isActiveRaw.toLowerCase() == 'true';
      }

      if (!isActive) {
        print('LiveAdvisoryBanner: Advisory is inactive');
        _hide();
        return;
      }

      // Timestamp check
      // Firestore returns a Timestamp object usually
      final dynamic tsRaw = data['timestamp'];
      int timestamp = 0;
      
      if (tsRaw is Timestamp) {
        timestamp = tsRaw.millisecondsSinceEpoch;
      } else if (tsRaw is int) {
        timestamp = tsRaw;
      } else if (tsRaw is String) {
        // Try parsing ISO string or int string
        timestamp = int.tryParse(tsRaw) ?? DateTime.tryParse(tsRaw)?.millisecondsSinceEpoch ?? 0;
      }

      print('LiveAdvisoryBanner: Timestamp processed: $timestamp, Last: $_lastTimestamp');

      if (timestamp > _lastTimestamp) {
        // New advisory
        print('LiveAdvisoryBanner: New content detected!');
        _lastTimestamp = timestamp;
        
        // Ensure data is ready for display (convert Timestamp to int if needed for other methods)
        // We can just pass the raw map, but our build method expects 'timestamp' to be int or convertible.
        // Let's normalize it to int for consistency in UI.
        final displayData = Map<String, dynamic>.from(data);
        displayData['timestamp'] = timestamp;

        _showFull(displayData);
      } else {
        // Same advisory
        if (!_isVisible) {
           _lastTimestamp = timestamp;
           final displayData = Map<String, dynamic>.from(data);
           displayData['timestamp'] = timestamp;
          _showFull(displayData);
        } else {
           // Just update content
           if (mounted) {
              final displayData = Map<String, dynamic>.from(data);
              displayData['timestamp'] = timestamp;
              setState(() {
                _currentAdvisory = displayData;
              });
           }
        }
      }
    }, onError: (e) {
      print('LiveAdvisoryBanner: Error in listener: $e');
    });
  }

  void _hide() {
    if (!_isVisible) return;
    if (mounted) {
      setState(() => _isVisible = false);
      _fadeController.reverse();
    }
  }

  void _showFull(Map<dynamic, dynamic> data) {
    _compactTimer?.cancel();
    if (mounted) {
      setState(() {
        _currentAdvisory = data;
        _isVisible = true;
        _isCompact = false;
      });
      _fadeController.forward();

      // Start 10s timer
      _compactTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => _isCompact = true);
        }
      });
    }
  }
  
  void _dismissManually() {
      if (mounted) setState(() => _isCompact = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentAdvisory == null) return const SizedBox.shrink();

    final type = (_currentAdvisory!['type'] ?? 'Information').toString();
    final message = (_currentAdvisory!['message'] ?? '').toString();
    final colors = _getColors(type);

    return SizeTransition(
        sizeFactor: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
        axisAlignment: 1.0,
        child: GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => AdvisoryScreen(disasterType: widget.disasterType)));
          },
          onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) { // Swipe Up
                   _dismissManually();
              }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            // Compact: Centered Pill. Full: Full width card
            margin: _isCompact 
                ? const EdgeInsets.symmetric(horizontal: 40, vertical: 8)
                : const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(_isCompact ? 30 : 12),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(_isCompact ? 30 : 12),
                child: _isCompact
                    ? _buildCompactContent(type, message, colors.text)
                    : _buildFullContent(type, message, colors.text),
            ),
          ),
        ));
  }
  
  Widget _buildFullContent(String type, String message, Color textColor) {
      // Parse timestamp for display
      final dynamic tsRaw = _currentAdvisory!['timestamp'];
      int timestamp = 0;
          if (tsRaw is int) {
            timestamp = tsRaw;
          } else if (tsRaw is num) {
            timestamp = tsRaw.toInt();
          } else if (tsRaw is String) {
            timestamp = int.tryParse(tsRaw) ?? 0;
          }
      
      // If seconds, convert to ms
      if (timestamp > 0 && timestamp < 1000000000000) {
        timestamp = timestamp * 1000;
      }
      
      final date = timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : DateTime.now();
      final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

      return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                   Icon(Icons.warning_amber_rounded, color: textColor, size: 28),
                   const SizedBox(width: 12),
                   Expanded(
                       child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                               Text(
                                   type.toUpperCase(),
                                   style: TextStyle(
                                       color: textColor,
                                       fontWeight: FontWeight.bold,
                                       fontSize: 14,
                                       letterSpacing: 1.0,
                                   ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                   message,
                                   style: TextStyle(color: textColor, fontSize: 13, height: 1.3),
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                               ),
                           ],
                       ),
                   ),
                   const SizedBox(width: 8),
                   Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                           // Close button
                           GestureDetector(
                               onTap: _dismissManually,
                               child: Container(
                                   padding: const EdgeInsets.all(4),
                                   decoration: BoxDecoration(
                                       color: Colors.white.withOpacity(0.2),
                                       shape: BoxShape.circle
                                   ),
                                   child: Icon(Icons.close, color: textColor, size: 16)
                               ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                               timeStr,
                               style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11),
                           ),
                       ],
                   )
              ],
          ),
      );
  }
  
  Widget _buildCompactContent(String type, String message, Color textColor) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          alignment: Alignment.center,
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(Icons.warning_amber_rounded, color: textColor, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(
                          "${type.toUpperCase()}: $message",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                      ),
                  ),
              ],
          ),
      );
  }

  ({Color background, Color text, Color shadow}) _getColors(String type) {
    switch (type) {
      case 'Evacuation':
        return (
          background: Colors.red.shade700,
          text: Colors.white,
          shadow: Colors.red.withOpacity(0.5)
        );
      case 'Warning':
        return (
          background: Colors.orange.shade800,
          text: Colors.white,
          shadow: Colors.orange.withOpacity(0.5)
        );
      case 'All Clear':
        return (
          background: Colors.green.shade700,
          text: Colors.white,
          shadow: Colors.green.withOpacity(0.5)
        );
      case 'Information':
      default:
        return (
          background: Colors.blue.shade700,
          text: Colors.white,
          shadow: Colors.blue.withOpacity(0.5)
        );
    }
  }
}
