#!/usr/bin/env bash

# Based on https://github.com/firezone/firezone/blob/4ac447ad1f0c65db3660f4311ad7c1d9040fa0e1/elixir/apps/web/lib/web/live/relay_groups/new_token.ex#L278

set -euo pipefail

FIREZONE_TOKEN=${FIREZONE_TOKEN:-}
FIREZONE_API_URL=${FIREZONE_API_URL:-}
PUBLIC_IP4_ADDR=${PUBLIC_IP4_ADDR:-}
PUBLIC_IP6_ADDR=${PUBLIC_IP6_ADDR:-}

# Comment out the line with PUBLIC_IP6_ADDR if it is empty.
PUBLIC_IP6_ADDR_COMMENT=`[ -z "$PUBLIC_IP6_ADDR" ] && echo "#"`

if [ -z "$FIREZONE_TOKEN" ]; then
  echo "FIREZONE_TOKEN is required"
  exit 1
fi

if [ -z "$FIREZONE_API_URL" ]; then
  echo "FIREZONE_API_URL is required"
  exit 1
fi

if [ -z "$PUBLIC_IP4_ADDR" ]; then
  echo "PUBLIC_IP4_ADDR is required"
  exit 1
fi

if [ ! -e /usr/local/bin/firezone-relay ]; then
  echo "/usr/local/bin/firezone-relay not found."
  exit 1
fi

FIREZONE_NAME=$(hostname)
FIREZONE_ID=$(uuidgen)
RUST_LOG=${RUST_LOG:-firezone_relay=info,firezone_tunnel=info,connlib_shared=info,tunnel_state=info,phoenix_channel=info,snownet=info,str0m=info,warn}

# Setup user and group
sudo groupadd -f firezone
id -u firezone &>/dev/null || sudo useradd -r -g firezone -s /sbin/nologin firezone

# Create systemd unit file
sudo cat > /etc/systemd/system/firezone-relay-1.service <<EOF
[Unit]
Description=Firezone Relay
After=network.target
Documentation=https://www.firezone.dev/kb

[Service]
Type=simple
Environment="FIREZONE_NAME=$FIREZONE_NAME"
Environment="FIREZONE_ID=$FIREZONE_ID"
Environment="FIREZONE_TOKEN=$FIREZONE_TOKEN"
Environment="FIREZONE_API_URL=$FIREZONE_API_URL"
Environment="PUBLIC_IP4_ADDR=$PUBLIC_IP4_ADDR"
${PUBLIC_IP6_ADDR_COMMENT}Environment="PUBLIC_IP6_ADDR=$PUBLIC_IP6_ADDR"
Environment="LOWEST_PORT=49152"
Environment="HIGHEST_PORT=57343"
Environment="RUST_LOG=$RUST_LOG"
Environment="RUST_LOG_STYLE=never"
ExecStartPre=/usr/local/bin/firezone-relay-init
ExecStart=/usr/bin/sudo \
  --preserve-env=FIREZONE_NAME,FIREZONE_ID,FIREZONE_TOKEN,FIREZONE_API_URL,PUBLIC_IP4_ADDR,PUBLIC_IP6_ADDR,LOWEST_PORT,HIGHEST_PORT,RUST_LOG,RUST_LOG_STYLE \
  -u firezone \
  -g firezone \
  /usr/local/bin/firezone-relay
TimeoutStartSec=3s
TimeoutStopSec=15s
Restart=always
RestartSec=7

[Install]
WantedBy=multi-user.target
EOF

# Create second relay systemd unit file with changed LOWEST_PORT and HIGHEST_PORT env
sed 's/LOWEST_PORT=49152/LOWEST_PORT=57344/;s/HIGHEST_PORT=57343/HIGHEST_PORT=65535/' \
/etc/systemd/system/firezone-relay-1.service > /etc/systemd/system/firezone-relay-2.service

# Create ExecStartPre script
sudo cat > /usr/local/bin/firezone-relay-init <<EOF
#!/bin/sh

set -ue

if [ ! -e /usr/local/bin/firezone-relay ]; then
  echo "/usr/local/bin/firezone-relay not found."
  exit 1
fi

# Set proper capabilities and permissions on each start
chgrp firezone /usr/local/bin/firezone-relay
chmod 0750 /usr/local/bin/firezone-relay

mkdir -p /var/lib/firezone
chown firezone:firezone /var/lib/firezone
chmod 0775 /var/lib/firezone
EOF

# Make ExecStartPre script executable
sudo chmod +x /usr/local/bin/firezone-relay-init

# Reload systemd
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable firezone-relay-1
sudo systemctl enable firezone-relay-2

# Start the service
sudo systemctl start firezone-relay-1
sudo systemctl start firezone-relay-2

echo "Run 'sudo systemctl status firezone-relay-1' and 'sudo systemctl status firezone-relay-2' to check the status."
echo "Run 'sudo journalctl -xeu firezone-relay-1.service' and 'sudo journalctl -xeu firezone-relay-2.service' to check the logs."
