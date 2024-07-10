# Installation FireZone Gateway via systemd

## Preparation

1. Obtain `FIREZONE_TOKEN`
   - Go to the `portal` and log in
   - Go to `Sites` -> pick your site -> click `+ Deploy Gateway` -> click `systemd` -> copy `FIREZONE_TOKEN`
   - Save the token to the clipboard

## Install Gateway

1. Run the script with variables:
   - where
     - `FIREZONE_TOKEN` is token from `Preparation` stage
     - `FIREZONE_API_URL` is path to `api` service (`EXTERNAL_URL` with `https` replaced by `wss`)

```bash
FIREZONE_TOKEN="<TOKEN>" \
FIREZONE_API_URL="wss://<URL>" \
  bash <(curl -fsSL https://raw.githubusercontent.com/DoctorFTB/firezone-1.x-self-hosted/main/gateway/gateway-install.sh)
```
