#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-profiles/deferral-90days.mobileconfig}"

if [[ ! -f "$PROFILE" ]]; then
  echo "Profile not found: $PROFILE" >&2
  exit 1
fi

# Generate distinct UUIDs for each payload + profile wrapper
PAYLOAD1_UUID=$(uuidgen)
PAYLOAD2_UUID=$(uuidgen)
PROFILE_UUID=$(uuidgen)

# Create profile with UUIDs inserted
TEMP_DIR=$(mktemp -d)
TEMP_PROFILE="$TEMP_DIR/profile.mobileconfig"
trap 'rm -rf "$TEMP_DIR"' EXIT
sed \
  -e "s/PAYLOAD1-UUID/$PAYLOAD1_UUID/" \
  -e "s/PAYLOAD2-UUID/$PAYLOAD2_UUID/" \
  -e "s/PROFILE-UUID/$PROFILE_UUID/" \
  "$PROFILE" > "$TEMP_PROFILE"

echo "Installing profile: $PROFILE"
echo "  Payload 1 UUID: $PAYLOAD1_UUID"
echo "  Payload 2 UUID: $PAYLOAD2_UUID"
echo "  Profile UUID: $PROFILE_UUID"

# Try CLI first; fall back to UI if it fails
if sudo /usr/bin/profiles install -type configuration -path "$TEMP_PROFILE" 2>/dev/null; then
  echo "Done. Check System Settings → Privacy & Security → Profiles to verify."
else
  echo "Opening profile in System Settings for manual approval..."
  open "$TEMP_PROFILE"
  echo "Press Enter after you've approved (or declined) the profile in System Settings."
  read -r
fi
