
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LGService {
  static final LGService _instance = LGService._internal();
  factory LGService() => _instance;
  LGService._internal();

  SSHClient? _client;

  Future<bool> connectToLG() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('lg_ip') ?? '';
      final port = prefs.getInt('lg_port') ?? 22;
      final username = prefs.getString('lg_username') ?? '';
      final password = prefs.getString('lg_password') ?? '';

      if (host.isEmpty || username.isEmpty) return false;

      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      return true;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  String generateKMLFromCSV(List<List<dynamic>> csvData) {
    String kmlHeader = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>LG KML Automation</name>
    <Style id="polyStyle">
      <LineStyle>
        <color>ff0000ff</color>
        <width>4</width>
      </LineStyle>
      <PolyStyle>
        <color>7f0000ff</color>
      </PolyStyle>
    </Style>
    <Style id="pushpin">
      <IconStyle>
        <scale>1.1</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
        </Icon>
      </IconStyle>
    </Style>
''';

    String placemarks = '';
    String polygonCoordinates = '';

    for (var i = 1; i < csvData.length; i++) {
      var row = csvData[i];
      if (row.length < 3) continue;

      String name = row[0].toString();
      double lat = double.tryParse(row[1].toString()) ?? 0.0;
      double lon = double.tryParse(row[2].toString()) ?? 0.0;
      double alt = double.tryParse(row[3].toString()) ?? 0.0;
      double validAlt = alt > 0 ? alt : 100;

      polygonCoordinates += '$lon,$lat,$validAlt ';

      placemarks += '''
    <Placemark>
      <name>$name</name>
      <styleUrl>#pushpin</styleUrl>
      <Point>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$lon,$lat,$validAlt</coordinates>
      </Point>
    </Placemark>
''';
    }

    String polygonKml = '''
    <Placemark>
      <name>Polygon Area</name>
      <styleUrl>#polyStyle</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $polygonCoordinates
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
''';

    return kmlHeader + polygonKml + placemarks + '''
  </Document>
</kml>''';
  }

  Future<void> sendKMLToSlave(String kmlContent) async {
    if (_client == null) return;

    try {
      String fileName = "automation.kml";
      await _client!.execute("echo '$kmlContent' > /var/www/html/$fileName");
      await _client!.execute("chmod 777 /var/www/html/$fileName");
      String url = "http://localhost:81/$fileName";

      await _client!.execute("echo '$url' > /var/www/html/kmls.txt");

      await _client!.execute("echo '$kmlContent' > /var/www/html/kml/master_1.kml");

    } catch (e) {
      print('Failed to send KML: $e');
    }
  }

  Future<void> flyToCamera(List<List<dynamic>> csvData) async {
    if (_client == null || csvData.length <= 1) return;

    try {
      double totalLat = 0, totalLon = 0;
      int count = 0;

      for (var i = 1; i < csvData.length; i++) {
        var row = csvData[i];
        if (row.length < 3) continue;
        totalLat += double.tryParse(row[1].toString()) ?? 0;
        totalLon += double.tryParse(row[2].toString()) ?? 0;
        count++;
      }

      if (count == 0) return;

      double centerLat = totalLat / count;
      double centerLon = totalLon / count;

      String flyToCmd =
          'flytoview=<LookAt>'
          '<longitude>$centerLon</longitude>'
          '<latitude>$centerLat</latitude>'
          '<altitude>0</altitude>'
          '<heading>0</heading>'
          '<tilt>30</tilt>'
          '<range>500000</range>'
          '<gx:altitudeMode>relativeToGround</gx:altitudeMode>'
          '</LookAt>';

      await _client!.execute('echo "$flyToCmd" > /tmp/query.txt');
    } catch (e) {
      print('Could not fly: $e');
    }
  }

  Future<void> cleanKML() async {
    if (_client == null) return;
    await _client!.execute("> /var/www/html/kmls.txt");
    await _client!.execute("echo '' > /var/www/html/kml/master_1.kml");
  }
}