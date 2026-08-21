with open(r'C:\Users\gusta\.gemini\antigravity\brain\a08b9cd2-5202-4a5f-978c-63200f815ce1\.system_generated\steps\458\content.md', 'r', encoding='utf-8') as f:
    text = f.read()

import re
keywords = ['RootTemplate', 'SkillData', 'Summon', 'Template', 'GetTemplate', 'Ext.Template']
for kw in keywords:
    matches = [m.start() for m in re.finditer(re.escape(kw), text, re.IGNORECASE)]
    print(f"Keyword: {kw}, matches: {len(matches)}")
    for idx in matches[:3]:
        print("---")
        print(text[max(0, idx-50):min(len(text), idx+150)])
