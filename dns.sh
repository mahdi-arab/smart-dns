#!/bin/bash
# =================================================
# Smart DNS Selector (Production Ready)
# Author: Mahdi Arab
# =================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# -------- Config --------
TEST_DOMAIN="${1:-${TEST_DOMAIN:-google.com}}"
MAX_OK=5

SERVERS="217.218.155.155 185.20.163.4 78.157.42.101 31.24.234.37 2.189.44.44 185.20.163.2 194.60.210.66 217.218.127.127 2.188.21.130 31.24.200.4 2.185.239.138 5.145.112.39 85.185.85.6 217.219.132.88 178.22.122.100 194.36.174.1 185.53.143.3 80.191.209.105 78.157.42.100 213.176.123.5 185.55.226.26 185.161.112.38 194.225.152.10 2.188.21.131 2.188.21.132 10.202.10.10 46.224.1.42 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112"

OK_SERVERS=()

# -------- Helpers --------
log() { echo -e "${CYAN}[*] $1${NC}"; }
ok() { echo -e "${GREEN}[✓] $1${NC}"; }
fail() { echo -e "${RED}[✗] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }

# -------- Check root --------
if [ "$EUID" -ne 0 ]; then
  fail "Run as root!"
  exit 1
fi

# -------- Check dig --------
if ! command -v dig >/dev/null 2>&1; then
  warn "dig not found. Installing..."

  if command -v apt >/dev/null 2>&1; then
    apt update && apt install -y dnsutils
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y bind-utils
  elif command -v yum >/dev/null 2>&1; then
    yum install -y bind-utils
  else
    fail "Cannot install dig automatically."
    exit 1
  fi
fi

# -------- Test DNS --------
log "Testing DNS for: $TEST_DOMAIN"

for DNS in $SERVERS; do
  if dig @"$DNS" "$TEST_DOMAIN" +time=1 +tries=1 +short > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} $DNS"
    OK_SERVERS+=("$DNS")
  else
    echo -e "${RED}[FAIL]${NC} $DNS"
  fi

  [ "${#OK_SERVERS[@]}" -ge "$MAX_OK" ] && break
done

if [ "${#OK_SERVERS[@]}" -eq 0 ]; then
  fail "No working DNS found!"
  exit 1
fi

DNS_LIST=$(printf "%s " "${OK_SERVERS[@]}")
ok "Selected ${#OK_SERVERS[@]} DNS servers"

# -------- Detect system --------

USE_NM=false
USE_RESOLVED=false

if command -v nmcli >/dev/null 2>&1 && systemctl is-active NetworkManager >/dev/null 2>&1; then
  USE_NM=true
fi

if command -v resolvectl >/dev/null 2>&1 && systemctl is-active systemd-resolved >/dev/null 2>&1; then
  USE_RESOLVED=true
fi

# -------- Apply DNS --------

log "Applying DNS settings..."

if $USE_NM; then
  CONN=$(nmcli -t -f NAME con show --active | head -n1)

  if [ -z "$CONN" ]; then
    fail "No active NetworkManager connection"
    exit 1
  fi

  nmcli con mod "$CONN" ipv4.dns "$DNS_LIST"
  nmcli con mod "$CONN" ipv4.ignore-auto-dns yes
  nmcli con up "$CONN" >/dev/null 2>&1

  ok "Applied via NetworkManager ($CONN)"

elif $USE_RESOLVED; then
  IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

  if [ -z "$IFACE" ]; then
    fail "Cannot detect network interface"
    exit 1
  fi

  resolvectl dns "$IFACE" $DNS_LIST

  ok "Applied via systemd-resolved ($IFACE)"

else
  warn "Fallback to /etc/resolv.conf"

  cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true

  echo -n > /etc/resolv.conf
  for DNS in "${OK_SERVERS[@]}"; do
    echo "nameserver $DNS" >> /etc/resolv.conf
  done

  ok "Written to /etc/resolv.conf"
fi

echo
ok "Done. Domain tested: $TEST_DOMAIN"
ok "DNS in use: $DNS_LIST"