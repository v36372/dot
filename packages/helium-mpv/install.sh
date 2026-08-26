#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST_DIR="$HOME/Library/Application Support/net.imput.helium/NativeMessagingHosts"
HOST_MANIFEST="$HOST_DIR/net.imput.helium_mpv.json"
EXTENSION_ID="aoccdgfffknimehjkhkkocgimaonfhhk"

chmod +x "$ROOT/native-host.py"
mkdir -p "$HOST_DIR"
cat > "$HOST_MANIFEST" <<EOF
{
  "name": "net.imput.helium_mpv",
  "description": "Launch detected browser streams in mpv",
  "path": "$ROOT/native-host.py",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXTENSION_ID/"]
}
EOF

python3 -m json.tool "$HOST_MANIFEST" >/dev/null
"$ROOT/native-host.py" --self-test

echo "Native host installed: $HOST_MANIFEST"
echo "Extension directory:    $ROOT/extension"
echo
echo "In helium://extensions:"
echo "  1. Enable Developer mode"
echo "  2. Click Load unpacked"
echo "  3. Select $ROOT/extension"
