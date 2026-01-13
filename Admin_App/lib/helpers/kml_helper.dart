class KmlHelper {
  /// Get default KML for a slave screen
  static String getSlaveDefaultKml(int slaveNo) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document id="slave_$slaveNo">
    <name>Slave $slaveNo</name>
    <open>1</open>
  </Document>
</kml>''';
  }

  /// Get KML for logo overlay on left screen
  static String getLogoKml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>LG Logo</name>
    <open>1</open>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>http://lg1:81/kml/logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="200" y="200" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  /// Get a sample KML with a placemark
  static String getSampleKml1() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Sample KML 1</name>
    <description>First sample KML for testing</description>
    <Style id="icon">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Placemark>
      <name>New York City</name>
      <description>The Big Apple</description>
      <styleUrl>#icon</styleUrl>
      <Point>
        <coordinates>-74.006,40.7128,0</coordinates>
      </Point>
    </Placemark>
    <LookAt>
      <longitude>-74.006</longitude>
      <latitude>40.7128</latitude>
      <altitude>0</altitude>
      <range>5000000</range>
      <tilt>0</tilt>
      <heading>0</heading>
    </LookAt>
  </Document>
</kml>''';
  }

  /// Get a second sample KML
  static String getSampleKml2() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Sample KML 2</name>
    <description>Second sample KML for testing</description>
    <Style id="icon">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Placemark>
      <name>London</name>
      <description>Capital of the UK</description>
      <styleUrl>#icon</styleUrl>
      <Point>
        <coordinates>-0.1278,51.5074,0</coordinates>
      </Point>
    </Placemark>
    <LookAt>
      <longitude>-0.1278</longitude>
      <latitude>51.5074</latitude>
      <altitude>0</altitude>
      <range>5000000</range>
      <tilt>0</tilt>
      <heading>0</heading>
    </LookAt>
  </Document>
</kml>''';
  }
}
