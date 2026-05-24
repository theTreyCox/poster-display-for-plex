#!/bin/zsh
# Packages the Roku app source bundle for local Roku sideloading.
# Note: This ZIP is not a signed distribution package. Roku store submission
# requires a signed .pkg/.zip generated from a Roku development device.
set -e
APP_NAME="poster-display-for-plex"
OUTPUT_FILE="$APP_NAME.zip"

rm -f "$OUTPUT_FILE"
python3 - <<'PY'
import os, zipfile
root = os.getcwd()
output = os.path.join(root, 'poster-display-for-plex.zip')
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, allowZip64=False) as zf:
    def add(path):
        arcname = os.path.relpath(path, root)
        zf.write(path, arcname)
    add('manifest')
    for folder in ['source', 'components', 'images', 'fonts']:
        for dirpath, dirnames, filenames in os.walk(folder):
            for filename in filenames:
                if filename == '.DS_Store':
                    continue
                add(os.path.join(dirpath, filename))
print('Created', output)
PY

echo "Created package: $OUTPUT_FILE"
