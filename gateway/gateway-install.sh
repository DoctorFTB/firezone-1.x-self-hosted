#!/usr/bin/env bash

# Based on https://github.com/firezone/firezone/blob/4ac447ad1f0c65db3660f4311ad7c1d9040fa0e1/scripts/gateway-systemd-install.sh

set -euo pipefail

FIREZONE_TOKEN=${FIREZONE_TOKEN:-}
FIREZONE_API_URL=${FIREZONE_API_URL:-}

# Can be used to download a specific version of the gateway from a custom URL
FIREZONE_VERSION=${FIREZONE_VERSION:-latest}
FIREZONE_ARTIFACT_URL=${FIREZONE_ARTIFACT_URL:-https://www.firezone.dev/dl/firezone-gateway}

if [ -z "$FIREZONE_TOKEN" ]; then
  echo "FIREZONE_TOKEN is required"
  exit 1
fi

if [ -z "$FIREZONE_API_URL" ]; then
  echo "FIREZONE_API_URL is required"
  exit 1
fi

FIREZONE_NAME=$(hostname)
FIREZONE_ID=$(uuidgen)
RUST_LOG=${RUST_LOG:-str0m=warn,info}

# Setup user and group
sudo groupadd -f firezone
id -u firezone >/dev/null 2>&1 || sudo useradd -r -g firezone -s /sbin/nologin firezone

# Create systemd unit file
sudo cat > /etc/systemd/system/firezone-gateway.service <<EOF
[Unit]
Description=Firezone Gateway
After=network.target
Documentation=https://www.firezone.dev/kb

[Service]
Type=simple
Environment="FIREZONE_NAME=$FIREZONE_NAME"
Environment="FIREZONE_ID=$FIREZONE_ID"
Environment="FIREZONE_TOKEN=$FIREZONE_TOKEN"
Environment="FIREZONE_API_URL=$FIREZONE_API_URL"
Environment="RUST_LOG=$RUST_LOG"
Environment="RUST_LOG_STYLE=never"
ExecStartPre=/usr/local/bin/firezone-gateway-init
ExecStart=/usr/bin/sudo \
  --preserve-env=FIREZONE_NAME,FIREZONE_ID,FIREZONE_TOKEN,FIREZONE_API_URL,RUST_LOG,RUST_LOG_STYLE \
  -u firezone \
  -g firezone \
  /usr/local/bin/firezone-gateway
TimeoutStartSec=3s
TimeoutStopSec=15s
Restart=always
RestartSec=7

[Install]
WantedBy=multi-user.target
EOF

# Create ExecStartPre script
sudo cat > /usr/local/bin/firezone-gateway-init <<EOF
#!/bin/sh

set -ue

# Download ${FIREZONE_VERSION} version of the gateway if it doesn't already exist
if [ ! -e /usr/local/bin/firezone-gateway ]; then
  echo "/usr/local/bin/firezone-gateway not found."
  echo "Downloading ${FIREZONE_VERSION} version from ${FIREZONE_ARTIFACT_URL}..."
  arch=\$(uname -m)

  # See https://www.firezone.dev/changelog for available binaries
  curl -fsSL ${FIREZONE_ARTIFACT_URL}/${FIREZONE_VERSION}/\$arch -o /tmp/firezone-gateway

  if file /tmp/firezone-gateway | grep -q "ELF"; then
    mv /tmp/firezone-gateway /usr/local/bin/firezone-gateway
  else
    echo "/tmp/firezone-gateway is not an executable!"
    echo "Ensure '${FIREZONE_ARTIFACT_URL}/${FIREZONE_VERSION}/\$arch' is accessible from this machine,"
    echo "or download binary manually and install to /usr/local/bin/firezone-gateway."
    exit 1
  fi
else
  echo "/usr/local/bin/firezone-gateway found. Skipping download."
fi

# Set proper capabilities and permissions on each start
chgrp firezone /usr/local/bin/firezone-gateway
chmod 0750 /usr/local/bin/firezone-gateway
setcap 'cap_net_admin+eip' /usr/local/bin/firezone-gateway
mkdir -p /var/lib/firezone
chown firezone:firezone /var/lib/firezone
chmod 0775 /var/lib/firezone

can_use_ipv6() {
	command -v "ip6tables" > /dev/null 2>&1
}

# Enable masquerading for ethernet and wireless interfaces
iptables -C FORWARD -i tun-firezone -j ACCEPT > /dev/null 2>&1 || iptables -A FORWARD -i tun-firezone -j ACCEPT
iptables -C FORWARD -o tun-firezone -j ACCEPT > /dev/null 2>&1 || iptables -A FORWARD -o tun-firezone -j ACCEPT
iptables -t nat -C POSTROUTING -o e+ -j MASQUERADE > /dev/null 2>&1 || iptables -t nat -A POSTROUTING -o e+ -j MASQUERADE
iptables -t nat -C POSTROUTING -o w+ -j MASQUERADE > /dev/null 2>&1 || iptables -t nat -A POSTROUTING -o w+ -j MASQUERADE

if can_use_ipv6; then
  ip6tables -C FORWARD -i tun-firezone -j ACCEPT > /dev/null 2>&1 || ip6tables -A FORWARD -i tun-firezone -j ACCEPT
  ip6tables -C FORWARD -o tun-firezone -j ACCEPT > /dev/null 2>&1 || ip6tables -A FORWARD -o tun-firezone -j ACCEPT
  ip6tables -t nat -C POSTROUTING -o e+ -j MASQUERADE > /dev/null 2>&1 || ip6tables -t nat -A POSTROUTING -o e+ -j MASQUERADE
  ip6tables -t nat -C POSTROUTING -o w+ -j MASQUERADE > /dev/null 2>&1 || ip6tables -t nat -A POSTROUTING -o w+ -j MASQUERADE
fi

# Enable packet forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.src_valid_mark=1

if can_use_ipv6; then
  sysctl -w net.ipv6.conf.all.disable_ipv6=0
  sysctl -w net.ipv6.conf.all.forwarding=1
  sysctl -w net.ipv6.conf.default.forwarding=1
fi
EOF

# Make ExecStartPre script executable
sudo chmod +x /usr/local/bin/firezone-gateway-init

# Reload systemd
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable firezone-gateway

# Start the service
sudo systemctl start firezone-gateway

echo "Run 'sudo systemctl status firezone-gateway' to check the status."
echo "Run 'sudo journalctl -xeu firezone-gateway.service' to check the logs."
