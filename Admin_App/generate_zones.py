import os
import json
import random

disasters = {
    'Flood': {'lat': 10.1076, 'lng': 76.3519, 'districts': ['Ernakulam', 'Pathanamthitta', 'Alappuzha', 'Thrissur']},
    'Cyclone': {'lat': 22.9868, 'lng': 87.8550, 'districts': ['Paschim Medinipur', 'Purba Medinipur', 'South 24 Parganas']},
    'Landslide': {'lat': 11.6854, 'lng': 76.1320, 'districts': ['Wayanad', 'Kozhikode', 'Malappuram']},
    'Forest Fire': {'lat': 30.0668, 'lng': 79.0193, 'districts': ['Pauri Garhwal', 'Almora', 'Nainital']}
}

types = ['Hospital', 'Relief Camp', 'Community Hall', 'School']
categories = ['Medical Facility', 'Large Shelter', 'Medium Shelter', 'School Shelter']

data = {}

for disaster, info in disasters.items():
    zones = []
    base_lat = info['lat']
    base_lng = info['lng']
    prefix = disaster[:2].upper()
    if disaster == 'Forest Fire': prefix = 'FF'
    
    for i in range(1, 22):
        lat = base_lat + random.uniform(-0.15, 0.15)
        lng = base_lng + random.uniform(-0.15, 0.15)
        
        t_idx = random.randint(0, 3)
        typ = types[t_idx]
        cat = categories[t_idx]
        
        icon = 'HOSPITAL' if typ == 'Hospital' else 'SHELTER'
        if typ == 'School': icon = 'SCHOOL'
        
        district_val = info['districts'][i % len(info['districts'])]
        
        zone = {
            'id': f'AUTO_{prefix}_SZ_{i:03d}',
            'name': f'{district_val} {typ} {i}',
            'type': typ,
            'category': cat,
            'lat': round(lat, 4),
            'lng': round(lng, 4),
            'district': district_val,
            'city': 'District Center',
            'area': 'Local Area',
            'capacity': random.randint(200, 2000),
            'status': 'ACTIVE',
            'visibleToPublic': True,
            'source': 'Generated Simulation Data',
            'confidence': 'HIGH',
            'kmlCategory': 'SAFE_ZONE',
            'iconHint': icon,
            'lgPriority': 1 if typ == 'Hospital' else 2
        }
        zones.append(zone)
    data[disaster] = zones

dart_code = f'// Auto-generated Safe Zones Data\n\nconst Map<String, List<Map<String, dynamic>>> safeZonesData = {json.dumps(data, indent=2)};\n'

os.makedirs('c:/Users/HP/Desktop/LG/Flood_LG/Admin_App/lib/data', exist_ok=True)
with open('c:/Users/HP/Desktop/LG/Flood_LG/Admin_App/lib/data/safe_zones_data.dart', 'w') as f:
    f.write(dart_code)
