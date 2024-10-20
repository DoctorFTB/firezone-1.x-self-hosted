#!/usr/bin/env bash

# Validate input

if [ -f /etc/systemd/system/firezone-relay-1.service ]; then
  echo 'File "/etc/systemd/system/firezone-relay-1.service" found'
  echo "I think you don't need this migration."
  exit 1
fi

if [ ! -f /etc/systemd/system/firezone-relay.service ]; then
  echo 'File "/etc/systemd/system/firezone-relay.service" not found'
  echo 'I think you need to manually setup the two relays.'
  exit 1
fi

if ! grep -q '^Environment="RUST_LOG=' /etc/systemd/system/firezone-relay.service; then
  echo 'Line starts with "Environment=\"RUST_LOG=" is not present in the file /etc/systemd/system/firezone-relay.service'
  echo 'I think you need to manually setup the two relays.'
  exit 1
fi

# Stop the service
sudo systemctl stop firezone-relay
sudo systemctl disable firezone-relay

# Configure two relays via two systemd unit files

mv /etc/systemd/system/firezone-relay.service /etc/systemd/system/firezone-relay-1.service

# Add LOWEST_PORT and HIGHEST_PORT for the first relay
sed -i 's/^\(Environment="RUST_LOG=\)/Environment="LOWEST_PORT=49152"\nEnvironment="HIGHEST_PORT=57343"\nEnvironment="LISTEN_PORT=3478"\n\1/;
s/\(,RUST_LOG,\)/,LOWEST_PORT,HIGHEST_PORT\1/' /etc/systemd/system/firezone-relay-1.service

# Create second relay systemd unit file with changed LOWEST_PORT and HIGHEST_PORT env
sed 's/LOWEST_PORT=49152/LOWEST_PORT=57344/;s/HIGHEST_PORT=57343/HIGHEST_PORT=65535/;s/LISTEN_PORT=3478/LISTEN_PORT=3479/' \
/etc/systemd/system/firezone-relay-1.service > /etc/systemd/system/firezone-relay-2.service

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
