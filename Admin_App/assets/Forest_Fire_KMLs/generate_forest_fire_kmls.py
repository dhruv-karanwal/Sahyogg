import os
import math

output_dir = r"c:\Users\HP\Desktop\kml folder\Forest_Fire_KMLs"
os.makedirs(output_dir, exist_ok=True)

def generate_circle_polygon(center_lat, center_lon, radius_km, num_points=32):
    coords = []
    for i in range(num_points):
        angle = math.radians(float(i) / num_points * 360.0)
        # 1 degree of lat is roughly 111km
        lat = center_lat + (radius_km / 111.0) * math.cos(angle)
        lon = center_lon + (radius_km / (111.0 * math.cos(math.radians(center_lat)))) * math.sin(angle)
        coords.append(f"{lon:.4f},{lat:.4f},0")
    coords.append(coords[0]) # close polygon
    return " ".join(coords)

def make_kml(name, content):
    kml = f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>{name}</name>
    <Folder>
      <name>{name}</name>
{content}
    </Folder>
  </Document>
</kml>'''
    filepath = os.path.join(output_dir, f"{name.replace(' ', '_')}.kml")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(kml)
    return kml

# FORMAT for KML colors is AABBGGRR (Alpha, Blue, Green, Red - hex)

# --- 1. FIRE SPREAD PERIMETER (Multi-Coloured Polygons) ---
# Highest incident areas: Pauri (402), Nainital (266), Tehri (247), Chamoli (221), Almora (195)
perimeters = [
    ("Pauri (Severe Spread: 402 Incidents)", 30.15, 78.78, 20, "aa0000ff", "ffff0000"), # Red
    ("Nainital (High Spread: 266 Incidents)", 29.39, 79.45, 15, "aa0088ff", "ffff8800"), # Orange
    ("Tehri (High Spread: 247 Incidents)", 30.38, 78.48, 15, "aa0088ff", "ffff8800"), # Orange
    ("Chamoli (Moderate Spread: 221 Incidents)", 30.29, 79.32, 12, "aa00aaff", "ffffff00"), # Yellow
    ("Almora (Moderate Spread: 195 Incidents)", 29.59, 79.64, 12, "aa00aaff", "ffffff00"), # Yellow
]
perimeter_content = ""
for name, lat, lon, rad, fill, stroke in perimeters:
    style_id = name.split()[0].replace('(', '')
    perimeter_content += f'''
      <Style id="{style_id}">
        <PolyStyle><color>{fill}</color></PolyStyle>
        <LineStyle><color>{stroke}</color><width>2</width></LineStyle>
      </Style>
      <Placemark>
        <name>{name}</name>
        <styleUrl>#{style_id}</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>{generate_circle_polygon(lat, lon, rad)}</coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
'''
k1 = make_kml("Fire Spread Perimeter", perimeter_content)


# --- 2. THERMAL HOTSPOTS ---
# Plotting the 13 district hotspots based on the report
hotspots = [
    (78.03, 30.31, "Dehradun Hotspots (175)", "375 ha affected"),
    (78.16, 29.94, "Haridwar Hotspots (52)", "132 ha affected"),
    (78.43, 30.72, "Uttarkashi Hotspots (172)", "240 ha affected"),
    (78.98, 30.28, "Rudraprayag Hotspots (82)", "159 ha affected"),
    (80.21, 29.58, "Pithoragarh Hotspots (97)", "288 ha affected"),
    (79.77, 29.83, "Bageshwar Hotspots (60)", "215 ha affected"),
    (80.09, 29.33, "Champawat Hotspots (59)", "119 ha affected"),
    (79.40, 28.98, "Udham Singh Nagar (16)", "14 ha affected"),
]
hotspot_content = '''
      <Style id="fireIcon">
        <IconStyle><scale>1.5</scale><Icon><href>http://maps.google.com/mapfiles/kml/shapes/firedept.png</href></Icon></IconStyle>
        <LabelStyle><color>ff0000ff</color><scale>1.2</scale></LabelStyle>
      </Style>
'''
for lon, lat, name, desc in hotspots:
    hotspot_content += f'''
      <Placemark>
        <name>{name}</name>
        <description>{desc}</description>
        <styleUrl>#fireIcon</styleUrl>
        <Point><coordinates>{lon},{lat},0</coordinates></Point>
      </Placemark>
'''
k2 = make_kml("Thermal Hotspots", hotspot_content)


# --- 3. VEGETATION LOSS ---
# Moist deciduous (55%) and subtropical pine (29%)
veg_loss_content = '''
      <Style id="vegLossPine"><PolyStyle><color>9914b4a3</color></PolyStyle><LineStyle><color>ff14b4a3</color><width>2</width></LineStyle></Style>
      <Style id="vegLossDeciduous"><PolyStyle><color>99245131</color></PolyStyle><LineStyle><color>ff245131</color><width>2</width></LineStyle></Style>
      <Placemark>
        <name>Subtropical Pine Forest Burnt Area (29%) - Approx 628 sq km</name>
        <styleUrl>#vegLossPine</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>
          78.2,29.8,0 79.5,29.8,0 79.5,30.5,0 78.2,30.5,0 78.2,29.8,0
        </coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
      <Placemark>
        <name>Moist Deciduous Forest Burnt Area (55%) - Approx 1191 sq km</name>
        <styleUrl>#vegLossDeciduous</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>
          78.5,29.3,0 80.0,29.3,0 80.0,29.7,0 78.5,29.7,0 78.5,29.3,0
        </coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
'''
k3 = make_kml("Vegetation Loss", veg_loss_content)


# --- 4. SMOKE PLUME DISPERSION ---
smoke_content = '''
      <Style id="smokeDark"><PolyStyle><color>70333333</color></PolyStyle><LineStyle><color>aa333333</color><width>1</width></LineStyle></Style>
      <Style id="smokeLight"><PolyStyle><color>50777777</color></PolyStyle><LineStyle><color>aa777777</color><width>1</width></LineStyle></Style>
      <Placemark>
        <name>Dense Smoke / High Black Carbon Concentration</name>
        <styleUrl>#smokeDark</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>
          77.8,29.5,0 79.8,29.5,0 80.2,30.8,0 78.2,30.8,0 77.8,29.5,0
        </coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
      <Placemark>
        <name>Light Smoke Dispersion / Poor Visibility</name>
        <styleUrl>#smokeLight</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>
          77.0,28.5,0 80.5,28.5,0 80.8,29.5,0 77.2,29.5,0 77.0,28.5,0
        </coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
'''
k4 = make_kml("Smoke Plume Dispersion", smoke_content)


# --- 5. INFRASTRUCTURE AT RISK (Houses & Communities) ---
infra = [
    (78.8, 30.15, "Pauri Village Settlements (At Risk)"),
    (79.45, 29.39, "Nainital Suburban Houses (Evacuated)"),
    (78.5, 30.38, "Tehri Hydro Dam Facilities (Surrounded by Fire)"),
    (79.6, 29.6, "Almora Rural Homes (Under threat)"),
]
infra_content = '''
      <Style id="houseIcon">
        <IconStyle><scale>1.3</scale><Icon><href>http://maps.google.com/mapfiles/kml/shapes/lodging.png</href></Icon></IconStyle>
        <LabelStyle><color>ff0000ff</color><scale>1.1</scale></LabelStyle>
      </Style>
'''
for lon, lat, name in infra:
    infra_content += f'''
      <Placemark>
        <name>{name}</name>
        <styleUrl>#houseIcon</styleUrl>
        <Point><coordinates>{lon},{lat},0</coordinates></Point>
      </Placemark>
'''
# Adding a multi-polygon for overall infrastructure threat zone
infra_content += '''
      <Style id="infraRiskPoly"><PolyStyle><color>600000ff</color></PolyStyle><LineStyle><color>ff0000ff</color><width>2</width></LineStyle></Style>
      <Placemark>
        <name>Critical Infrastructure Threat Zone (6 lives lost, 31 injured)</name>
        <styleUrl>#infraRiskPoly</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>
          78.2,29.3,0 79.8,29.3,0 79.5,30.5,0 78.0,30.5,0 78.2,29.3,0
        </coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
'''
k5 = make_kml("Infrastructure At Risk", infra_content)


# --- 6. WILDLIFE IMPACT (National Parks) ---
parks = [
    ("Corbett National Park (261 ha affected)", 29.53, 78.77, 10, "9966ccaa", "ff66ccaa"), # Purple-green
    ("Rajaji National Park (70 ha affected)", 30.01, 78.02, 5, "99cc9933", "ffcc9933"), # Yellow-brown
    ("Kedarnath Musk Deer Sanctuary (60 ha affected)", 30.60, 79.13, 5, "993399ff", "ff3399ff"), # Orange
]
wildlife_content = '''
      <Style id="parkIcon">
        <IconStyle><scale>1.5</scale><Icon><href>http://maps.google.com/mapfiles/kml/shapes/parks.png</href></Icon></IconStyle>
        <LabelStyle><color>ff00aaff</color><scale>1.2</scale></LabelStyle>
      </Style>
'''
for name, lat, lon, rad, fill, stroke in parks:
    style_id = name.split()[0]
    wildlife_content += f'''
      <Style id="{style_id}">
        <PolyStyle><color>{fill}</color></PolyStyle>
        <LineStyle><color>{stroke}</color><width>2</width></LineStyle>
      </Style>
      <Placemark>
        <name>{name} - Burnt Area Zone</name>
        <styleUrl>#{style_id}</styleUrl>
        <Polygon><outerBoundaryIs><LinearRing><coordinates>{generate_circle_polygon(lat, lon, rad)}</coordinates></LinearRing></outerBoundaryIs></Polygon>
      </Placemark>
      <Placemark>
        <name>Wildlife Habitat Under threat</name>
        <styleUrl>#parkIcon</styleUrl>
        <Point><coordinates>{lon},{lat},0</coordinates></Point>
      </Placemark>
'''
k6 = make_kml("Wildlife Impact", wildlife_content)


# --- 7. SAFE ZONES ---
camps = [
    (78.03, 30.34, "Dehradun Central Relief Camp"),
    (78.16, 29.98, "Haridwar City Evacuation Center"),
    (79.45, 29.40, "Nainital Lake Safe Zone"),
    (79.64, 29.62, "Almora Cantonment Safe Hub"),
    (78.78, 30.17, "Pauri Medical Relief Station"),
]
safe_content = '''
      <Style id="safePoint">
        <IconStyle><scale>1.4</scale><Icon><href>http://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png</href></Icon></IconStyle>
        <LabelStyle><color>ff00ff00</color><scale>1.2</scale></LabelStyle>
      </Style>
'''
for lon, lat, name in camps:
    safe_content += f'''
      <Placemark>
        <name>{name}</name>
        <styleUrl>#safePoint</styleUrl>
        <Point><coordinates>{lon},{lat},0</coordinates></Point>
      </Placemark>
'''
k7 = make_kml("Safe Zones", safe_content)


# --- 8. EVACUATION ROUTES ---
routes = [
    ("Pauri to Dehradun Evacuation Highway", "78.78,30.15,0 78.4,30.2,0 78.03,30.34,0"),
    ("Nainital Downhill Escape Route", "79.45,29.39,0 79.5,29.2,0 79.4,28.98,0"),
    ("Tehri to Haridwar Corridor", "78.48,30.38,0 78.3,30.1,0 78.16,29.98,0"),
    ("Almora Inter-district Safety Route", "79.64,29.59,0 79.5,29.45,0 79.45,29.40,0"),
]
route_content = '''
      <Style id="routeLine"><LineStyle><color>ff00ff00</color><width>6</width></LineStyle></Style>
'''
for name, coords in routes:
    route_content += f'''
      <Placemark>
        <name>{name}</name>
        <styleUrl>#routeLine</styleUrl>
        <LineString><tessellate>1</tessellate><coordinates>{coords}</coordinates></LineString>
      </Placemark>
'''
k8 = make_kml("Evacuation Routes", route_content)

# --- MASTER KML Generation ---
master_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>SAHYOG: Uttarakhand Forest Fire Intelligence</name>
    <open>1</open>
    <description>Profoundly enriched multi-layer Liquid Galaxy Demo for Forest Fires</description>
    
    <Folder><name>Fire Spread Perimeter (Severity Zones)</name>{perimeter_content}</Folder>
    <Folder><name>Thermal Hotspots (District Nodes)</name>{hotspot_content}</Folder>
    <Folder><name>Vegetation Loss (Ecosystem Impact)</name>{veg_loss_content}</Folder>
    <Folder><name>Smoke Plume Dispersion (Air Quality)</name>{smoke_content}</Folder>
    <Folder><name>Infrastructure At Risk (Housing &amp; Facilities)</name>{infra_content}</Folder>
    <Folder><name>Wildlife Impact (National Parks &amp; Sanctuaries)</name>{wildlife_content}</Folder>
    <Folder><name>Safe Zones (Relief Camp Network)</name>{safe_content}</Folder>
    <Folder><name>Evacuation Routes (Multi-Corridor)</name>{route_content}</Folder>
  </Document>
</kml>
'''

master_path = os.path.join(output_dir, "Forest_Fire_Master_Detailed.kml")
with open(master_path, "w", encoding="utf-8") as f:
    f.write(master_content)
print(f"Master KML created at: {master_path}")
