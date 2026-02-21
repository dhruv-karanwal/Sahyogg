import csv
import os

modis_file = r"C:\Users\HP\Desktop\LG\Flood_LG\Admin_App\DL_FIRE_M-C61_718495\fire_archive_M-C61_718495.csv"
viirs_file = r"C:\Users\HP\Desktop\LG\Flood_LG\Admin_App\DL_FIRE_SV-C2_718496\fire_archive_SV-C2_718496.csv"
output_dir = r"C:\Users\HP\Desktop\forest fire kml"

os.makedirs(output_dir, exist_ok=True)

data = []

def process_file(filepath, source):
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            acq_date = row.get('acq_date', '')
            if acq_date.startswith('2016-04') or acq_date.startswith('2016-05'):
                row['Source'] = source
                data.append(row)

if os.path.exists(modis_file):
    process_file(modis_file, 'MODIS')
else:
    print(f"File not found: {modis_file}")

if os.path.exists(viirs_file):
    process_file(viirs_file, 'VIIRS')
else:
    print(f"File not found: {viirs_file}")

def is_high_confidence(row):
    if row['Source'] == 'MODIS':
        try:
            return float(row['confidence']) >= 80
        except:
            return False
    else:
        # VIIRS
        return row.get('confidence', '').lower() == 'h'

def get_kml_time(date_str, time_val):
    try:
        time_str = str(int(time_val)).zfill(4)
        return f"{date_str}T{time_str[:2]}:{time_str[2:]}:00Z"
    except:
        return f"{date_str}T00:00:00Z"

def create_kml_content(data_subset, name):
    kml = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<kml xmlns="http://www.opengis.net/kml/2.2">',
           '<Document>',
           f'<name>{name}</name>',
           '''
           <Style id="highFire">
             <IconStyle>
               <scale>1.3</scale>
               <Icon>
                 <href>http://maps.google.com/mapfiles/ms/icons/red-dot.png</href>
               </Icon>
             </IconStyle>
           </Style>
           <Style id="lowFire">
             <IconStyle>
               <scale>1.3</scale>
               <Icon>
                 <href>http://maps.google.com/mapfiles/ms/icons/orange-dot.png</href>
               </Icon>
             </IconStyle>
           </Style>
           ''']
    
    for row in data_subset:
        lat = row.get('latitude', '0')
        lon = row.get('longitude', '0')
        style = "highFire" if is_high_confidence(row) else "lowFire"
        acq_date = row.get('acq_date', '')
        acq_time = row.get('acq_time', '0')
        timestamp = get_kml_time(acq_date, acq_time)
        
        conf = row.get('confidence', '')
        frp = row.get('frp', 'N/A')
        source = row.get('Source', '')
        
        desc = (f"Source: {source}<br/>"
                f"Date: {acq_date}<br/>"
                f"Time: {acq_time}<br/>"
                f"Confidence: {conf}<br/>"
                f"FRP: {frp}<br/>")
                
        kml.append('<Placemark>')
        kml.append(f'<name>Fire {source}</name>')
        kml.append(f'<description><![CDATA[{desc}]]></description>')
        kml.append(f'<TimeStamp><when>{timestamp}</when></TimeStamp>')
        kml.append(f'<styleUrl>#{style}</styleUrl>')
        kml.append('<Point>')
        kml.append(f'<coordinates>{lon},{lat},0</coordinates>')
        kml.append('</Point>')
        kml.append('</Placemark>')
        
    kml.append('</Document>')
    kml.append('</kml>')
    return '\n'.join(kml)

if data:
    # Master KML
    master_kml = create_kml_content(data, 'Master_Fire_Points')
    with open(os.path.join(output_dir, 'Master.kml'), 'w', encoding='utf-8') as f:
        f.write(master_kml)

    # Daily KMLs
    dates = set(row['acq_date'] for row in data)
    for date in sorted(dates):
        day_data = [row for row in data if row['acq_date'] == date]
        day_kml = create_kml_content(day_data, f'Fire_{date}')
        with open(os.path.join(output_dir, f'Fire_{date}.kml'), 'w', encoding='utf-8') as f:
            f.write(day_kml)
    print(f"Generated Master.kml and {len(dates)} daily KML files.")
else:
    print("No data found for April/May 2016 or files are missing.")
