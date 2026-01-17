import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/lg_controller.dart';
import 'package:flutter/foundation.dart';

class SafeZoneLGService {
  final LGController lgController;
  final Set<String> _castedShelterIds = {};

  SafeZoneLGService(this.lgController);

  /// Casts a single shelter (Appends/Updates in the live KML)
  Future<void> castShelter(String shelterId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('safe_zones').doc(shelterId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      if (!_isValidShelter(data)) return;

      _castedShelterIds.add(shelterId);
      await _updateLiveKML();
      
      // Fly to the shelter
      await lgController.flyTo(
        data['lat'], 
        data['lng'], 
        1000, // Range 
        45,   // Tilt
        0     // Heading
      );
    } catch (e) {
      debugPrint('Error casting shelter: $e');
    }
  }

  /// Casts all valid shelters (Replaces live KML)
  Future<void> castAllShelters() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('safe_zones').get();
      _castedShelterIds.clear();
      
      for (var doc in snapshot.docs) {
        if (_isValidShelter(doc.data())) {
          _castedShelterIds.add(doc.id);
        }
      }
      
      await _updateLiveKML();

      // Fly to a central view (approx Kerala center)
      await lgController.flyTo(10.8505, 76.2711, 250000, 0, 0); 
    } catch (e) {
      debugPrint('Error casting all shelters: $e');
    }
  }

  bool _isValidShelter(Map<String, dynamic> data) {
    // 1. Data Source Rules
    if (data['visibleToPublic'] == false) return false;
    
    final type = data['type'] ?? '';
    final validTypes = ['Relief Camp', 'Shelter', 'Medical Shelter'];
    if (!validTypes.contains(type)) return false;

    // 2. Button Action Validation
    if (data['status'] == 'CLOSED') return false;
    if (data['lat'] == null || data['lng'] == null) return false;

    return true;
  }

  Future<void> _updateLiveKML() async {
    if (_castedShelterIds.isEmpty) {
      // If empty, maybe clear the file or upload empty KML
       await lgController.uploadString(
        _buildEmptyKML(), 
        '/var/www/html/kml/Shelters_Live.kml'
      );
      return;
    }

    // Fetch all needed docs
    // Note: optimization - we could cache data, but for now we fetch to be fresh
    // Or we can rely on passing the data object if we have it. 
    // For 'castAll', we have the snapshot. For 'castShelter', we fetched one.
    // To ensure consistency, let's fetch 'IN' query if list is small, or just fetch all and filter.
    // Given usage, fetching all active might be better if list is long? 
    // Let's iterate the IDs and fetch. If list is HUGE, this is slow. 
    // But typically ~50 shelters.
    
    // Better approach: Maintain a local cache of data `_shelterCache`
    // For this task, let's just fetch all from Firestore again to be safe and simple 
    // or optimized:
    
    final snapshot = await FirebaseFirestore.instance.collection('safe_zones').get();
    final docs = snapshot.docs.where((d) => _castedShelterIds.contains(d.id)).toList();

    final kmlContent = _generateKML(docs);
    
    // 6. Liquid Galaxy Deployment
    await lgController.uploadString(kmlContent, '/var/www/html/kml/Shelters_Live.kml');
    
    // Ensure NetworkLink exists
    await _ensureNetworkLink();
  }
  
  String _buildEmptyKML() {
      return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Shelters Live</name>
  </Document>
</kml>''';
  }

  String _generateKML(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    sb.writeln('<Document>');
    sb.writeln('<name>Shelters Live</name>');
    
    // Styles
    // Relief Camp -> Purple Square
    sb.writeln(_getStyle('Relief Camp', 'http://maps.google.com/mapfiles/kml/shapes/square.png', 'ff800080')); // Purple (AABBGGRR) -> 800080 is purple. KML is AABBGGRR. Flutter Color(0xFF800080). 
    // Shelter -> Green Circle
    sb.writeln(_getStyle('Shelter', 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png', 'ff00ff00')); // Green
    // Medical Shelter -> Blue Cross
    sb.writeln(_getStyle('Medical Shelter', 'http://maps.google.com/mapfiles/kml/shapes/cross-hairs.png', 'ffff0000')); // Blue (AABBGGRR: ff(opacity) ff(blue) 00(green) 00(red))
    // FULL -> Grey modifier (we'll just use a separate style ID)
    sb.writeln(_getStyle('Relief Camp_FULL', 'http://maps.google.com/mapfiles/kml/shapes/square.png', 'ff808080'));
    sb.writeln(_getStyle('Shelter_FULL', 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png', 'ff808080'));
    sb.writeln(_getStyle('Medical Shelter_FULL', 'http://maps.google.com/mapfiles/kml/shapes/cross-hairs.png', 'ff808080'));

    for (var doc in docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown Shelter';
      final type = data['type'] ?? 'Shelter';
      final status = data['status'] ?? 'OPEN';
      final capacity = data['capacity'] ?? 'N/A';
      final district = data['district'] ?? 'N/A';
      final lat = data['lat'];
      final lng = data['lng'];

      String styleId = type;
      if (status == 'FULL') {
        styleId = '${type}_FULL';
      }

      sb.writeln('<Placemark>');
      sb.writeln('<name>${_escape(name)}</name>');
      sb.writeln('<description><![CDATA[');
      sb.writeln('<b>Type:</b> $type<br/>');
      sb.writeln('<b>District:</b> $district<br/>');
      sb.writeln('<b>Capacity:</b> $capacity<br/>');
      sb.writeln('<b>Status:</b> $status');
      sb.writeln(']]></description>');
      sb.writeln('<styleUrl>#${_cleanId(styleId)}</styleUrl>');
      sb.writeln('<Point><coordinates>$lng,$lat,0</coordinates></Point>');
      sb.writeln('</Placemark>');
    }

    sb.writeln('</Document>');
    sb.writeln('</kml>');
    return sb.toString();
  }

  Future<void> _ensureNetworkLink() async {
    // 6. Ensure a NetworkLink exists... Shelters_NetworkLink.kml
    final linkKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <NetworkLink>
    <name>Live Shelters Layer</name>
    <flyToView>0</flyToView>
    <Link>
      <href>http://localhost:81/kml/Shelters_Live.kml</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>5</refreshInterval>
    </Link>
  </NetworkLink>
</kml>''';
    
    // We upload this to a specific slave or master file that is loaded.
    // Assuming standard "kmls.txt" method loads http links.
    // We need to upload this file to the server, then ensure kmls.txt points to IT.
    
    await lgController.uploadString(linkKml, '/var/www/html/kml/Shelters_NetworkLink.kml');
    
    // Add to kmls.txt if not present (simple append for now, or use a managed list)
    // To avoid duplicates, we might want to check or just overwrite kmls.txt if we controlled it fully.
    // For now, appending is the standard "dumb" way in many LG apps if we don't track state.
    // But let's try to be smarter? 
    // Actually, if we just echo it, it might append multiple times.
    // A safer way is to assume we are adding it once per session or relying on a clear command.
    // Let's just append. The user can "Clean KMLs" if it gets messy.
    
    // IMPORTANT: Note that kmls.txt usually takes URLs.
    // http://localhost:81/kml/Shelters_NetworkLink.kml
    final linkUrl = 'http://localhost:81/kml/Shelters_NetworkLink.kml';
    await lgController.executeCommand('grep -qFx "$linkUrl" /var/www/html/kmls.txt || echo "$linkUrl" >> /var/www/html/kmls.txt');
  }

  String _getStyle(String id, String iconHref, String color) {
    return '''
    <Style id="${_cleanId(id)}">
      <IconStyle>
        <color>$color</color>
        <scale>1.1</scale>
        <Icon><href>$iconHref</href></Icon>
      </IconStyle>
      <LabelStyle>
        <scale>1.0</scale>
      </LabelStyle>
    </Style>''';
  }

  String _cleanId(String s) => s.replaceAll(' ', '_');
  String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
