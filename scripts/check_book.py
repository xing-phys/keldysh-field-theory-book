"""Check source references and rendered local links without third-party packages."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import re
import sys
ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / '_site'
class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(); self.ids=set(); self.links=[]; self.feed(text)
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.add(a['id'])
        for key in ('href','src','poster'):
            if key in a: self.links.append(a[key])
errors=[]
sources=list(ROOT.glob('*.qmd'))
labels={}; cites=set()
for source in sources:
    text=source.read_text()
    for label in re.findall(r'\{#((?:eq|sec|fig|tbl)-[\w-]+)', text):
        if label in labels: errors.append(f'Duplicate label {label}: {source.name}, {labels[label]}')
        labels[label]=source.name
    for match in re.finditer(r'(?<![\w\\])@([A-Za-z][A-Za-z0-9_:-]*)', text):
        key=match.group(1)
        if key.startswith(('eq-','sec-','fig-','tbl-')): continue
        cites.add(key)
bib=ROOT/'assets/bibliography.bib'
keys=set(re.findall(r'@\w+\s*\{\s*([^,]+)',bib.read_text())) if bib.exists() else set()
for key in sorted(cites-keys): errors.append('Missing bibliography key: '+key)
for source in sources:
    for label in re.findall(r'@((?:eq|sec|fig|tbl)-[\w-]+)',source.read_text()):
        if label not in labels: errors.append(f'{source.name}: undefined source reference {label}')
if not SITE.exists(): errors.append('No rendered _site directory; run quarto render first.')
cache={}
for path in SITE.rglob('*.html'):
    text=path.read_text(); cache[path.resolve()]=Page(text)
    if 'quarto-unresolved-ref' in text: errors.append(f'{path.name}: unresolved Quarto reference')
    if re.search(r'<strong>\?\?\?',text): errors.append(f'{path.name}: unresolved reference marker')
for path,page in cache.items():
    for link in page.links:
        u=urlsplit(link)
        if u.scheme or u.netloc: continue
        target=unquote(u.path)
        if not target: dest=path
        elif target.startswith('/'):
            prefix='/keldysh-field-theory-book/'
            target=target[len(prefix):] if target.startswith(prefix) else target.lstrip('/')
            dest=(SITE/target).resolve()
        else: dest=(path.parent/target).resolve()
        if dest.is_dir(): dest=dest/'index.html'
        if not dest.exists():
            errors.append(f'{path.name}: missing target {link}'); continue
        if u.fragment and dest.suffix=='.html':
            parsed=cache.get(dest)
            if parsed and unquote(u.fragment) not in parsed.ids:
                errors.append(f'{path.name}: missing anchor {link}')
for message in sorted(set(errors)): print('ERROR:',message)
print(f'Checked {len(sources)} sources, {len(labels)} labels, {len(cites)} citation keys, {len(cache)} HTML pages.')
if errors: sys.exit(1)
print('Source references, bibliography keys, local assets, navigation, anchors, and PDF links passed.')
