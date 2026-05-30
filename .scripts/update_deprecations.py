from pathlib import Path
import re

root = Path('.')
opacity_re = re.compile(r"\.withOpacity\(([^)]+)\)")
new_re = re.compile(r"\bnew\s+([A-Za-z_][A-Za-z0-9_]*)")
files = list(root.rglob('*.dart'))
count = 0
for path in files:
    text = path.read_text(encoding='utf-8')
    new_text = opacity_re.sub(r'.withValues(alpha: \1)', text)
    new_text = new_re.sub(r'\1', new_text)
    if new_text != text:
        path.write_text(new_text, encoding='utf-8')
        count += 1
print(f'updated {count} files out of {len(files)} dart files')
