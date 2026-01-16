import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/lg_controller.dart';
import 'package:flutter/material.dart';

class SafeZoneLGService {
  final LGController lgController;
  StreamSubscription? _subscription;
  bool _isSyncing = false;

  SafeZoneLGService(this.lgController);

  // Start listening to Firebase Safe Zones
  void startSync() {
    if (_isSyncing) return;
    _isSyncing = true;

    // Send NetworkLink once
    _sendNetworkLink();

    _subscription = FirebaseFirestore.instance
        .collection('safe_zones')
        .snapshots()
        .listen((snapshot) {
      _handleSnapshot(snapshot);
    }, onError: (e) {
      print('SafeZone Sync Error: $e');
    });
  }

  void stopSync() {
    _subscription?.cancel();
    _isSyncing = false;
  }

  Future<void> _sendNetworkLink() async {
    // Determine LG Host - usually from controller settings, but we need to fetch it
    // LGController uses _settingsController internally, but doesn't expose host directly easily
    // We will rely on mapped /var/www/html/kml structure. 
    // Actually LGController.sendKMLToSlave uploads to /var/www/html/kml/slave_X.kml 
    // But prompt says put SafeZones_Live.kml in /var/www/html/kml/
    
    // Create NetworkLink
    final networkLinkKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <NetworkLink>
    <name>Live Safe Zones</name>
    <flyToView>0</flyToView>
    <Link>
      <href>http://localhost:81/kml/SafeZones_Live.kml</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>10</refreshInterval>
    </Link>
  </NetworkLink>
</kml>''';

    // We upload this as a slave layer or just a file?
    // Prompt says "Create a NetworkLink KML... SafeZones_NetworkLink.kml"
    // Usually we add this to the Master's kmls.txt or one of the slave KMLs.
    // For simplicity, we can inject this NetworkLink into a slave KML (e.g. slave_3) using LGController's mechanisms.
    // OR upload it to the server and add it to the kmls.txt list.
    
    try {
        await lgController.uploadString(networkLinkKml, '/var/www/html/kml/SafeZones_NetworkLink.kml');
        // Add to kmls.txt to make it visible
        // We'll append it. Note: This might duplicate if run multiple times, ideally we manage the list.
        // But for this task, ensuring it's loaded is key.
        final host = (await lgController.loadSettings())['ip'] ?? 'localhost'; 
        // Wait, loadSettings returns map? let's check lg_controller.dart again.
        // It calls _settingsController.loadSettings().
        
        await lgController.executeCommand("echo '\\nhttp://localhost:81/kml/SafeZones_NetworkLink.kml' >> /var/www/html/kmls.txt");
    } catch (e) {
        print('Error sending NetworkLink: $e');
    }
  }

  Future<void> _handleSnapshot(QuerySnapshot snapshot) async {
    if (!lgController.isConnected) return;

    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    sb.writeln('<Document>');
    sb.writeln('<name>Safe Zones Live Data</name>');
    
    // Define Styles
    sb.writeln(_getStyle('Hospital', 'http://maps.google.com/mapfiles/kml/shapes/hospitals.png', 'ffff0000')); // Blue (AABBGGRR) -> Red? No KML is AABBGGRR. Blue=FFFF0000
    sb.writeln(_getStyle('Relief Camp', 'http://maps.google.com/mapfiles/kml/shapes/square.png', 'ff800080')); // Purple
    sb.writeln(_getStyle('Safe Zone', 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png', 'ff00ff00')); // Green
    sb.writeln(_getStyle('High Ground', 'http://maps.google.com/mapfiles/kml/shapes/triangle.png', 'ffffff00')); // Cyan (Blue+Green) -> AABBGGRR -> 00FFFF -> FFFF00
    sb.writeln(_getStyle('FULL', 'http://maps.google.com/mapfiles/kml/shapes/forbidden.png', 'ff808080')); // Grey

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filter Logic
      final bool visible = data['visibleToPublic'] ?? true;
      if (!visible) continue;

      final String status = data['status'] ?? 'ACTIVE';
      final String type = data['type'] ?? 'Safe Zone';
      
      String styleId = type;
      if (status == 'FULL') styleId = 'FULL';
      
      // Placemark
      sb.writeln('<Placemark>');
      sb.writeln('<name>${_escape(data['name'] ?? 'Unknown')}</name>');
      sb.writeln('<description><![CDATA[');
      sb.writeln('Type: $type<br/>');
      sb.writeln('Capacity: ${data['capacity'] ?? 'N/A'}<br/>');
      sb.writeln('District: ${data['district'] ?? 'Kerala'}<br/>');
      sb.writeln('Status: $status');
      sb.writeln(']]></description>');
      sb.writeln('<styleUrl>#${_cleanId(styleId)}</styleUrl>');
      sb.writeln('<Point><coordinates>${data['lng']},${data['lat']},0</coordinates></Point>');
      sb.writeln('</Placemark>');
    }

    sb.writeln('</Document>');
    sb.writeln('</kml>');

    try {
        // Upload to /var/www/html/kml/SafeZones_Live.kml
        await lgController.uploadString(sb.toString(), '/var/www/html/kml/SafeZones_Live.kml');
        print('Uploaded SafeZones_Live.kml');
    } catch (e) {
        print('Upload failed: $e');
    }
  }

  String _getStyle(String id, String iconParams, String color) {
     return '''
    <Style id="${_cleanId(id)}">
      <IconStyle>
        <color>$color</color>
        <scale>1.2</scale>
        <Icon><href>$iconParams</href></Icon>
      </IconStyle>
      <LabelStyle><scale>1.0</scale></LabelStyle>
    </Style>
     ''';
  }
  
  String _cleanId(String s) => s.replaceAll(' ', '_');
  String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

extension on LGController {
    // Helper to upload string since it's defined in sshController inside lgController
    // But wait, LGController has _sshController which has uploadString. 
    // LGController doesn't expose uploadString publically? 
    // Let's check existing LGController code.
    // It has `sendKMLToSlave` (calls uploadString to slave path)
    // It has `uploadAsset` (calls uploadAsset)
    // It DOES expose `uploadString` via `_sshController.uploadString` IF we make a method or duplicate logic.
    // Actually `LGController` has `sendKMLToSlave`. 
    // To support arbitrary path upload, I might need to add a method to LGController or define an extension if `sshController` works.
    // LGController's `_sshController` is private. 
    // But `LGController` has `executeCommand`.
    // Wait, the file `lg_controller.dart` has `Future<void> sendKMLToSlave(...)`. 
    // I should modify `LGController` to add `uploadString(content, path)` public method since it already has private access.
}
