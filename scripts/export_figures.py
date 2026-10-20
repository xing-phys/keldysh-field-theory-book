"""Export vector PDFs and readable PNGs using Inkscape (not needed to read the book)."""
from pathlib import Path
import shutil
import subprocess
root = Path(__file__).resolve().parents[1]
inkscape = shutil.which('inkscape')
if not inkscape:
    raise SystemExit('Install Inkscape to export SVG figures to PDF and PNG.')
for svg in sorted((root / 'figs').glob('*.svg')):
    for extension in ('pdf', 'png'):
        subprocess.run([inkscape, str(svg), '--export-type='+extension,
                        '--export-filename='+str(svg.with_suffix('.'+extension)),
                        '--export-dpi=160'], check=True, capture_output=True)
    print('Exported', svg.name)
