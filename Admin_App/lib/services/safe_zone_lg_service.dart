import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/lg_controller.dart';
import 'package:flutter/foundation.dart';

class SafeZoneLGService {
  final LGController lgController;
  final String disasterType;
  final Set<String> _castedShelterIds = {};
  double _currentScale = 1.1;

  SafeZoneLGService(this.lgController, this.disasterType);

  /// Casts a single shelter (Appends/Updates in the live KML)
  Future<void> castShelter(String shelterId) async {
    try {
      _currentScale = 1.1; // Reset scale for individual cast
      final doc = await FirebaseFirestore.instance.collection('Disasters').doc(disasterType).collection('safe_zones').doc(shelterId).get();
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
      _currentScale = 1.1; // Reset scale for normal cast all
      await _castAllInternal();
      // Fly to a central view (approx Kerala center)
      await lgController.flyTo(10.8505, 76.2711, 250000, 0, 0); 
    } catch (e) {
      debugPrint('Error casting all shelters: $e');
    }
  }

  /// Strategic Overview: Casts all with LARGE icons and High View
  Future<void> castStrategicOverview() async {
    try {
      _currentScale = 4.0; // Large scale for visibility
      await _castAllInternal();
      // Fly to higher altitude for overview
      await lgController.flyTo(10.8505, 76.2711, 600000, 0, 0); 
    } catch (e) {
      debugPrint('Error casting strategic overview: $e');
    }
  }

  Future<void> _castAllInternal() async {
      final snapshot = await FirebaseFirestore.instance.collection('Disasters').doc(disasterType).collection('safe_zones').get();
      _castedShelterIds.clear();
      
      for (var doc in snapshot.docs) {
        if (_isValidShelter(doc.data())) {
          _castedShelterIds.add(doc.id);
        }
      }
      await _updateLiveKML();
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

    final snapshot = await FirebaseFirestore.instance.collection('Disasters').doc(disasterType).collection('safe_zones').get();
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
    
    // Styles with Dynamic Scale
    // Relief Camp -> Purple Square
    sb.writeln(_getStyle('Relief Camp', 'http://maps.google.com/mapfiles/kml/shapes/square.png', 'ff800080', _currentScale)); 
    // Shelter -> Green Circle
    sb.writeln(_getStyle('Shelter', 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png', 'ff00ff00', _currentScale)); 
    // Medical Shelter -> Blue Cross
    sb.writeln(_getStyle('Medical Shelter', 'http://maps.google.com/mapfiles/kml/shapes/cross-hairs.png', 'ffff0000', _currentScale)); 
    
    // FULL -> Grey modifier
    sb.writeln(_getStyle('Relief Camp_FULL', 'http://maps.google.com/mapfiles/kml/shapes/square.png', 'ff808080', _currentScale));
    sb.writeln(_getStyle('Shelter_FULL', 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png', 'ff808080', _currentScale));
    sb.writeln(_getStyle('Medical Shelter_FULL', 'http://maps.google.com/mapfiles/kml/shapes/cross-hairs.png', 'ff808080', _currentScale));

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
    
    await lgController.uploadString(linkKml, '/var/www/html/kml/Shelters_NetworkLink.kml');
  
    final linkUrl = 'http://localhost:81/kml/Shelters_NetworkLink.kml';
    await lgController.executeCommand('grep -qFx "$linkUrl" /var/www/html/kmls.txt || echo "$linkUrl" >> /var/www/html/kmls.txt');
  }

  String _getStyle(String id, String iconHref, String color, double scale) {
    return '''
    <Style id="${_cleanId(id)}">
      <IconStyle>
        <color>$color</color>
        <scale>$scale</scale>
        <Icon><href>$iconHref</href></Icon>
      </IconStyle>
      <LabelStyle>
        <scale>${scale * 0.8}</scale> 
      </LabelStyle>
    </Style>''';
  }

  String _cleanId(String s) => s.replaceAll(' ', '_');
  String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
