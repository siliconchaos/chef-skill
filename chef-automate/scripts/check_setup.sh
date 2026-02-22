#!/usr/bin/env bash
# check_setup.sh — Verify knife and Chef Automate configuration
# Run this to diagnose connectivity issues before anything else.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "       $1"; }

echo "=== knife / Chef Automate Setup Check ==="
echo ""

# 1. knife installed?
echo "--- knife CLI ---"
if command -v knife &>/dev/null; then
    pass "knife is installed: $(knife --version 2>/dev/null | head -1)"
else
    fail "knife is not installed or not on PATH"
    info "Install Chef Workstation from https://docs.chef.io/workstation/install_workstation/"
    exit 1
fi

echo ""

# 2. Configuration file present?
echo "--- Configuration ---"
CREDS_FILE="$HOME/.chef/credentials"
CONFIG_FILE=".chef/config.rb"

if [[ -f "$CREDS_FILE" ]]; then
    pass "credentials file found: $CREDS_FILE"
elif [[ -f "$CONFIG_FILE" ]]; then
    pass "config.rb found: $CONFIG_FILE"
else
    fail "No credentials file at $HOME/.chef/credentials and no .chef/config.rb"
    info "Create ~/.chef/credentials with your Chef Automate connection details"
fi

# 3. Show active config values
echo ""
CLIENT_NAME=$(knife config get client_name 2>/dev/null | grep -v '^$' || true)
SERVER_URL=$(knife config get chef_server_url 2>/dev/null | grep -v '^$' || true)
CLIENT_KEY=$(knife config get client_key 2>/dev/null | grep -v '^$' || true)

[[ -n "$CLIENT_NAME" ]] && pass "client_name: $CLIENT_NAME" || fail "client_name not set"
[[ -n "$SERVER_URL" ]] && pass "chef_server_url: $SERVER_URL" || fail "chef_server_url not set"
[[ -n "$CLIENT_KEY" ]] && pass "client_key configured: $CLIENT_KEY" || warn "client_key not explicitly set"

# 4. Check the key file exists and is readable
echo ""
echo "--- Key File ---"
KEY_PATH=$(echo "$CLIENT_KEY" | sed 's/.*= //')
if [[ -n "$KEY_PATH" ]]; then
    EXPANDED_KEY="${KEY_PATH/#\~/$HOME}"
    if [[ -f "$EXPANDED_KEY" ]]; then
        PERMS=$(stat -f "%Mp%Lp" "$EXPANDED_KEY" 2>/dev/null || stat -c "%a" "$EXPANDED_KEY" 2>/dev/null)
        if [[ "$PERMS" == "600" || "$PERMS" == "0600" ]]; then
            pass "Key file exists with secure permissions: $EXPANDED_KEY"
        else
            warn "Key file exists but permissions are $PERMS (should be 600): $EXPANDED_KEY"
            info "Fix with: chmod 600 $EXPANDED_KEY"
        fi
    else
        fail "Key file not found: $EXPANDED_KEY"
    fi
fi

# 5. Clock skew
echo ""
echo "--- Clock ---"
LOCAL_TIME=$(date +%s)
if command -v ntpdate &>/dev/null || command -v timedatectl &>/dev/null; then
    pass "Time sync tooling available"
else
    warn "Could not verify time sync (ntpdate/timedatectl not found)"
fi
info "Local time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
info "Note: Chef requires workstation and server clocks within 15 minutes"

# 6. SSL check
echo ""
echo "--- SSL ---"
if knife ssl check &>/dev/null 2>&1; then
    pass "SSL certificate is trusted"
else
    fail "SSL check failed"
    info "Run: knife ssl fetch"
    info "Then re-run: knife ssl check"
fi

# 7. Connectivity
echo ""
echo "--- Connectivity ---"
if knife client list &>/dev/null 2>&1; then
    CLIENT_COUNT=$(knife client list 2>/dev/null | wc -l | tr -d ' ')
    pass "Connected to Chef Infra Server ($CLIENT_COUNT clients found)"
else
    fail "Cannot connect to Chef Infra Server"
    info "Check chef_server_url, key file, SSL trust, and network access"
fi

echo ""
echo "=== Done ==="
