import os
import glob
import re

translations = {
    'fr': {'colorMode': 'COULEUR', 'patternsMode': 'MOTIFS', 'numbersMode': 'NOMBRES'},
    'es': {'colorMode': 'COLOR', 'patternsMode': 'PATRONES', 'numbersMode': 'NÚMEROS'},
    'de': {'colorMode': 'FARBE', 'patternsMode': 'MUSTER', 'numbersMode': 'ZAHLEN'},
    'it': {'colorMode': 'COLORE', 'patternsMode': 'MODELLI', 'numbersMode': 'NUMERI'},
    'ja': {'colorMode': '色', 'patternsMode': 'パターン', 'numbersMode': '数字'},
    'ko': {'colorMode': '색상', 'patternsMode': '패턴', 'numbersMode': '숫자'},
    'zh': {'colorMode': '颜色', 'patternsMode': '图案', 'numbersMode': '数字'}
}

files = glob.glob('lib/i18n/strings_*.dart')
for filepath in files:
    lang = re.search(r'strings_([a-z]{2})\.dart', filepath)
    if not lang: continue
    lang = lang.group(1)
    if lang not in translations: continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # insert before the closing brace
    for k, v in translations[lang].items():
        if f"'{k}'" not in content:
            content = content.replace('};', f"  '{k}': '{v}',\n}};")
            
    with open(filepath, 'w') as f:
        f.write(content)
