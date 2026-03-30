#!/usr/bin/env python3
"""
Build comprehensive OUI database from IEEE registry.
Adds threat categorization for surveillance, defense, and suspicious vendors.
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

# Threat categories
THREAT_CATEGORIES = {
    "us_defense": {
        "level": "critical",
        "description": "US Department of Defense / Military"
    },
    "us_intel": {
        "level": "critical", 
        "description": "US Intelligence Community contractors"
    },
    "law_enforcement": {
        "level": "high",
        "description": "Law enforcement / Police equipment"
    },
    "surveillance": {
        "level": "high",
        "description": "Known surveillance equipment vendors"
    },
    "chinese_state": {
        "level": "high",
        "description": "Chinese state-affiliated companies"
    },
    "russian_state": {
        "level": "high",
        "description": "Russian state-affiliated companies"
    },
    "israeli_intel": {
        "level": "high",
        "description": "Israeli intelligence/defense contractors"
    },
    "tracking": {
        "level": "medium",
        "description": "Tracking device manufacturers"
    },
    "iot_risk": {
        "level": "low",
        "description": "IoT devices with known vulnerabilities"
    }
}

# Keywords to match vendors to threat categories
THREAT_KEYWORDS = {
    "us_defense": [
        "raytheon", "lockheed", "northrop", "general dynamics", "boeing defense",
        "l3harris", "l-3", "harris corp", "bae systems", "leidos",
        "saic", "caci", "booz allen", "mantech", "perspecta",
        "army", "navy", "air force", "marine", "dod ", "department of defense",
        "pentagon", "darpa", "nsa ", "cia ", "dhs ", "fbi ",
        "sandia", "los alamos", "lawrence livermore", "oak ridge",
        "mitre", "aerospace corporation", "rand corporation"
    ],
    "us_intel": [
        "palantir", "clearview", "anduril", "babel street",
        "voyager labs", "shadowdragon", "cobwebs", "media sonar",
        "pen-link", "penlink", "i2 group", "verint", "nice systems",
        "ss8", "utimaco", "trovicor", "gamma group", "hacking team"
    ],
    "law_enforcement": [
        "motorola solutions", "axon", "taser", "vigilant solutions",
        "shotspotter", "cellebrite", "grayshift", "magnet forensics",
        "msab", "oxygen forensic", "detective", "police", "sheriff",
        "stingray", "harris corporation", "digital receiver technology",
        "drt", "keyw", "sixgill"
    ],
    "surveillance": [
        "hikvision", "dahua", "uniview", "tiandy", "cp plus",
        "hanwha", "wisenet", "axis communications", "genetec", "milestone",
        "avigilon", "pelco", "honeywell security", "bosch security",
        "flir", "teledyne flir", "thermal", "night vision",
        "drone", "uav", "unmanned", "quadcopter"
    ],
    "chinese_state": [
        "huawei", "zte", "hikvision", "dahua", "hytera",
        "inspur", "sugon", "dawning", "phytium", "loongson",
        "china mobile", "china telecom", "china unicom",
        "alibaba", "tencent", "baidu", "bytedance", "dji",
        "sensetime", "megvii", "yitu", "cloudwalk", "iflytek",
        "nuctech", "pci-suntek", "meiya pico"
    ],
    "russian_state": [
        "kaspersky", "positive technologies", "group-ib",
        "rostelecom", "megafon", "mts ", "beeline", "tele2 russia",
        "yandex", "mail.ru", "vk ", "sberbank"
    ],
    "israeli_intel": [
        "nso group", "candiru", "cognyte", "cellebrite",
        "verint", "nice systems", "elbit", "rafael", "iai ",
        "israel aerospace", "elta", "check point", "cybereason"
    ],
    "tracking": [
        "tile", "chipolo", "samsung smartthings", "apple find",
        "airtag", "tracker", "gps track", "lojack", "spireon",
        "calamp", "geotab", "samsara", "fleet"
    ],
    "iot_risk": [
        "tuya", "espressif", "realtek", "mediatek", "qualcomm atheros",
        "broadcom", "marvell", "ralink"
    ]
}

def parse_ieee_oui(filepath):
    """Parse IEEE OUI text file into structured data."""
    entries = []
    current_entry = {}
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.rstrip()
        
        # Match OUI line: "28-6F-B9   (hex)		Nokia Shanghai Bell Co., Ltd."
        hex_match = re.match(r'^([0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2})\s+\(hex\)\s+(.+)$', line)
        if hex_match:
            if current_entry:
                entries.append(current_entry)
            
            oui = hex_match.group(1).replace('-', ':')
            vendor = hex_match.group(2).strip()
            current_entry = {
                'oui': oui,
                'vendor': vendor,
                'address': []
            }
            continue
        
        # Match base16 line for additional info
        base16_match = re.match(r'^([0-9A-F]{6})\s+\(base 16\)\s+(.+)$', line)
        if base16_match and current_entry:
            continue
        
        # Address lines (indented with tabs)
        if line.startswith('\t\t') and current_entry:
            addr_line = line.strip()
            if addr_line:
                current_entry['address'].append(addr_line)
    
    # Don't forget last entry
    if current_entry:
        entries.append(current_entry)
    
    return entries

def categorize_vendor(vendor_name, address_lines):
    """Determine threat category for a vendor."""
    search_text = (vendor_name + ' ' + ' '.join(address_lines)).lower()
    
    for category, keywords in THREAT_KEYWORDS.items():
        for keyword in keywords:
            if keyword.lower() in search_text:
                return category
    
    return None

def determine_country(address_lines):
    """Extract country code from address."""
    if not address_lines:
        return None
    
    last_line = address_lines[-1].strip()
    
    # Common country codes
    country_map = {
        'US': 'United States', 'CN': 'China', 'TW': 'Taiwan',
        'KR': 'South Korea', 'JP': 'Japan', 'DE': 'Germany',
        'GB': 'United Kingdom', 'UK': 'United Kingdom',
        'FR': 'France', 'IT': 'Italy', 'NL': 'Netherlands',
        'SE': 'Sweden', 'FI': 'Finland', 'NO': 'Norway',
        'DK': 'Denmark', 'CH': 'Switzerland', 'AT': 'Austria',
        'IL': 'Israel', 'RU': 'Russia', 'IN': 'India',
        'AU': 'Australia', 'NZ': 'New Zealand', 'CA': 'Canada',
        'MX': 'Mexico', 'BR': 'Brazil', 'SG': 'Singapore',
        'HK': 'Hong Kong', 'MY': 'Malaysia', 'TH': 'Thailand',
        'VN': 'Vietnam', 'PH': 'Philippines', 'ID': 'Indonesia'
    }
    
    # Check if last line is a 2-letter country code
    if len(last_line) == 2 and last_line.upper() in country_map:
        return last_line.upper()
    
    return None

def build_database(entries):
    """Build the final database with threat categorization."""
    database = {
        'version': '1.0.0',
        'source': 'IEEE Standards Association',
        'source_url': 'https://standards-oui.ieee.org/oui/oui.txt',
        'total_entries': len(entries),
        'threat_categories': THREAT_CATEGORIES,
        'entries': {}
    }
    
    threat_counts = defaultdict(int)
    country_counts = defaultdict(int)
    
    for entry in entries:
        oui = entry['oui']
        vendor = entry['vendor']
        address = entry.get('address', [])
        
        category = categorize_vendor(vendor, address)
        country = determine_country(address)
        
        db_entry = {
            'vendor': vendor,
            'country': country
        }
        
        if category:
            db_entry['threat_category'] = category
            db_entry['threat_level'] = THREAT_CATEGORIES[category]['level']
            threat_counts[category] += 1
        
        if country:
            country_counts[country] += 1
        
        database['entries'][oui] = db_entry
    
    # Add statistics
    database['statistics'] = {
        'by_threat_category': dict(threat_counts),
        'by_country': dict(sorted(country_counts.items(), key=lambda x: -x[1])[:20])
    }
    
    return database

def export_formats(database, output_dir):
    """Export database in multiple formats."""
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # Full JSON
    with open(output_dir / 'oui-database.json', 'w') as f:
        json.dump(database, f, indent=2)
    print(f"Wrote {output_dir / 'oui-database.json'}")
    
    # Compact JSON (no indentation)
    with open(output_dir / 'oui-database.min.json', 'w') as f:
        json.dump(database, f, separators=(',', ':'))
    print(f"Wrote {output_dir / 'oui-database.min.json'}")
    
    # Simple CSV for easy import
    with open(output_dir / 'oui-database.csv', 'w') as f:
        f.write('oui,vendor,country,threat_category,threat_level\n')
        for oui, entry in database['entries'].items():
            vendor = entry['vendor'].replace('"', '""')
            country = entry.get('country', '')
            category = entry.get('threat_category', '')
            level = entry.get('threat_level', '')
            f.write(f'"{oui}","{vendor}","{country}","{category}","{level}"\n')
    print(f"Wrote {output_dir / 'oui-database.csv'}")
    
    # Threat-only database (smaller, just suspicious vendors)
    threat_db = {
        'version': database['version'],
        'threat_categories': database['threat_categories'],
        'entries': {
            oui: entry for oui, entry in database['entries'].items()
            if 'threat_category' in entry
        }
    }
    threat_db['total_entries'] = len(threat_db['entries'])
    
    with open(output_dir / 'oui-threats.json', 'w') as f:
        json.dump(threat_db, f, indent=2)
    print(f"Wrote {output_dir / 'oui-threats.json'} ({len(threat_db['entries'])} threat entries)")
    
    # Rust source file for embedding
    with open(output_dir / 'oui_embedded.rs', 'w') as f:
        f.write('// Auto-generated OUI database\n')
        f.write('// Source: IEEE Standards Association\n\n')
        f.write('pub static OUI_DATABASE: &[(&str, &str, Option<&str>)] = &[\n')
        for oui, entry in sorted(database['entries'].items()):
            vendor = entry['vendor'].replace('"', '\\"').replace('\\', '\\\\')
            category = entry.get('threat_category')
            if category:
                f.write(f'    ("{oui}", "{vendor}", Some("{category}")),\n')
            else:
                f.write(f'    ("{oui}", "{vendor}", None),\n')
        f.write('];\n')
    print(f"Wrote {output_dir / 'oui_embedded.rs'}")

def main():
    input_file = Path(__file__).parent / 'ieee-oui-raw.txt'
    output_dir = Path(__file__).parent
    
    if not input_file.exists():
        print(f"Error: {input_file} not found. Run download first.")
        sys.exit(1)
    
    print(f"Parsing {input_file}...")
    entries = parse_ieee_oui(input_file)
    print(f"Parsed {len(entries)} OUI entries")
    
    print("Building database with threat categorization...")
    database = build_database(entries)
    
    print(f"\nStatistics:")
    print(f"  Total entries: {database['total_entries']}")
    print(f"  Threat entries: {sum(database['statistics']['by_threat_category'].values())}")
    for cat, count in sorted(database['statistics']['by_threat_category'].items()):
        print(f"    {cat}: {count}")
    print(f"  Top countries:")
    for country, count in list(database['statistics']['by_country'].items())[:10]:
        print(f"    {country}: {count}")
    
    print("\nExporting...")
    export_formats(database, output_dir)
    
    print("\nDone!")

if __name__ == '__main__':
    main()
