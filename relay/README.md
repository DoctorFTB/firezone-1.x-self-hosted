# Installation FireZone Relay via systemd

## Preparation

1. Obtain `firezone-relay` from docker image
   - **ATTENTION** Currently, you can only get the binary file by building from source code or a docker image
   - Docker is only needed to get the file, no more reason!
   - run script:
```bash
DOCKER_IMAGE_PREFIX=ghcr.io/firezone
DOCKER_TAG=1

docker run \
  -v $PWD:/opt/mount \
  --rm \
  --entrypoint cp ${DOCKER_IMAGE_PREFIX}/relay:${DOCKER_TAG} \
  /bin/firezone-relay \
  /opt/mount/firezone-relay && \
    mv ./firezone-relay /usr/local/bin/firezone-relay
```
2. Obtain `FIREZONE_TOKEN`
   - Go to the `portal` and log in
   - Go to `Relays` -> pick your group -> click `Deploy` -> copy `FIREZONE_TOKEN`
   - Save the token to the clipboard

## Configure firewall

- You need to open `3478/udp` and `49152:65535/udp` for the server with the gateway and for each FireZone client

### Sample for `ufw`:

```bash
ufw allow from $ip to any port 3478 proto udp
ufw allow from $ip to any port 49152:65535 proto udp
```

## Install Relay

1. Run the script with variables:
   - where
     - `FIREZONE_TOKEN` is token from `Preparation` stage
     - `FIREZONE_API_URL` is path to `api` service (`EXTERNAL_URL` with `https` replaced by `wss`)
     - `PUBLIC_IP4_ADDR` is server ipv4 (can be obtained from `curl ifconfig.net`)
     - `PUBLIC_IP6_ADDR` is *OPTIONAL* server ipv6

```bash
FIREZONE_TOKEN="<TOKEN>" \
FIREZONE_API_URL="wss://<URL>" \
PUBLIC_IP4_ADDR="<PUBLICIPV4>" \
PUBLIC_IP6_ADDR="<OPTINAL PUBLICIPV6>" \
  bash <(curl -fsSL https://raw.githubusercontent.com/DoctorFTB/firezone-1.x-self-hosted/main/relay/relay-install.sh)
```
