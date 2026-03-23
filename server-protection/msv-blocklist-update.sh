#!/usr/bin/env bash
# msv-blocklist-update.sh
# Fetches bad IP lists → loads into CSF/ipset → allows Googlebot
# Run as root or with sudo
# Suggested cron: 0 */2 * * * /path/to/msv-blocklist-update.sh >> /var/log/msv-blocklist.log 2>&1

set -e

CSF_BLOCKLIST="/etc/csf/csf.blocklists"
TEMP_DIR="/tmp/msv-blocklist-$(date +%s)"
mkdir -p "$TEMP_DIR"

# ------------------------------------------------------
# 1. Backup current blocklists
# ------------------------------------------------------
cp /etc/csf/csf.blocklists "/etc/csf/csf.blocklists.bak.$(date +%F_%H%M%S)" 2>/dev/null || true

# ------------------------------------------------------
# 2. Clear old MSV entries & rebuild clean file
# ------------------------------------------------------
grep -v '^# MSV-' "$CSF_BLOCKLIST" > "${CSF_BLOCKLIST}.new" 2>/dev/null || touch "${CSF_BLOCKLIST}.new"
mv "${CSF_BLOCKLIST}.new" "$CSF_BLOCKLIST"

# ------------------------------------------------------
# 3. Sources (name|interval_sec|max_entries|url)
# ------------------------------------------------------
SOURCES=(
  "BITWIRE_INBOUND|7200|20000|https://raw.githubusercontent.com/bitwire-it/ipblocklist/main/inbound.txt"
  "IPSUM_LEVEL3|86400|10000|https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt"
)

# ------------------------------------------------------
# 4. Add blocklist definitions to csf.blocklists
# ------------------------------------------------------
{
  echo ""
  echo "# MSV-SpyBlocker: Virus/Malware/Bad IPs (updated frequently)"
  for src in "${SOURCES[@]}"; do
    IFS='|' read -r name interval max url <<< "$src"
    echo "${name}|${interval}|${max}|${url}"
  done
} >> "$CSF_BLOCKLIST"

# ------------------------------------------------------
# 5. Fetch & process each list
# ------------------------------------------------------
for src in "${SOURCES[@]}"; do
  IFS='|' read -r name interval max url <<< "$src"
  
  file="$TEMP_DIR/$(basename "$url")"
  echo "Fetching $name → $file"
  curl -s -f -o "$file" "$url" || { echo "Failed to fetch $name"; continue; }
  
  # Optional: sort -uV "$file" -o "$file"   # dedupe if desired
  
  # Append IPs to csf.blocklists (CSF will handle the rest on restart)
  echo "# $name IPs" >> "$CSF_BLOCKLIST"
  cat "$file" >> "$CSF_BLOCKLIST"
  echo "" >> "$CSF_BLOCKLIST"
done

# ------------------------------------------------------
# 6. Allow Googlebot (current ranges from official source)
# ------------------------------------------------------
echo "Updating Googlebot allow rules..."
wget -q https://developers.google.com/search/apis/ipranges/googlebot.json -O /tmp/googlebot.json

grep -Eho '((25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])(\/(3[0-2]|[12]?[0-9]))?' /tmp/googlebot.json \
  | sort -u \
  | xargs -r -n1 -I{} csf -a "{}" "Googlebot" 2>/dev/null || true

# Also add the main known range(s) if not already covered
csf -a 66.249.64.0/19 "Googlebot" 2>/dev/null || true
csf -a 66.249.80.0/20 "Googlebot" 2>/dev/null || true

rm -f /tmp/googlebot.json

# ------------------------------------------------------
# 7. Restart CSF + LFD (this fetches lists again + builds IPSETs)
# ------------------------------------------------------
echo "Restarting CSF..."
csf -ra

# ------------------------------------------------------
# 8. Quick stats & verification
# ------------------------------------------------------
echo ""
echo "=== CSF/IPSET Status ==="
csf -s

echo ""
echo "=== Loaded MSV blocklists ==="
ipset list | grep -E 'bl_BITWIRE|bl_IPSUM' || echo "No MSV sets found yet — check /etc/csf/csf.blocklists"

echo ""
echo "=== Total blocked IPs across all sets ==="
ipset list -t | awk '
  /^Name:/ { name=$2 }
  /^Number of entries:/ { entries+=$4 }
  END { print "Total blocked IPs:", entries }
' || echo "ipset list -t failed"

echo ""
echo "=== Recent BLOCK/DROP events (last 20 lines) ==="
tail -n 20 /var/log/csf/csf.log | grep -E 'BLOCK|DROP' || echo "No recent blocks"

# ------------------------------------------------------
# Cleanup
# ------------------------------------------------------
rm -rf "$TEMP_DIR"

echo ""
echo "[MSV] Blocklist update complete."
