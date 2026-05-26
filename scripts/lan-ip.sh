#!/usr/bin/env bash
# Detect the Mac's current LAN IP and patch ios/project.yml so a real device
# on the same Wi-Fi can hit the local wrangler dev server.
#
# Run this whenever you switch networks. Regenerates the Xcode project.

set -euo pipefail

cd "$(dirname "$0")/.."

ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
if [[ -z "$ip" ]]; then
  echo "ERROR: could not detect a LAN IP. Check that Wi-Fi is on." >&2
  exit 1
fi

echo "Detected LAN IP: $ip"

# Replace the LASTSCREW_API_BASE in project.yml.
sed -i.bak -E "s|LASTSCREW_API_BASE: \"http://[0-9.]+:8787\"|LASTSCREW_API_BASE: \"http://$ip:8787\"|" ios/project.yml

# Replace the exception domain (the previous IP entry). Tolerant of any digits-and-dots.
sed -i.bak -E "s|^( {12})[0-9.]+:$|\1$ip:|" ios/project.yml || true

rm -f ios/project.yml.bak

echo "Regenerating Xcode project..."
( cd ios && xcodegen generate )
echo "Done. Open ios/Lastscrew.xcodeproj and Cmd+R."
