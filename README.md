# self-hosted FireZone

## Why

- I want to use FireZone in production on a vm without cloud providers and IaC tools

## Repository info

- Here's a variant of how to deploy self-hosted FireZone 1.x
  - where deployed
    - portal via docker
    - gateway via systemd
    - relay via systemd (+ extracted from docker image :sad:)

### FireZone doesn't officially support self-hosting.

## Installation FireZone

- [portal](./portal/README.md)
- [gateway](./gateway/README.md)
- [relay](./relay/README.md)
- reverse proxy
  - [nginx](./reverse-proxy/nginx/README.md)

## FireZone Client

- Use official FireZone clients for connect: `https://www.firezone.dev/kb/user-guides`
  - Don't forget to change the `Auth Base URL` and `API URL` in the settings!

## Updating

### FireZone portal

- Use `docker compose -f docker-compose.postgres.yml pull` and restart all containers

### FireZone Gateway

- Two ways:
  - Remove file "/usr/local/bin/firezone-gateway" and restart systemd service
    - Service automatically redownload it
  - Update it manually via download it from FireZone Changelog and put file to "/usr/local/bin/firezone-gateway"

### FireZone Relay

- You need manually reobtain file "/usr/local/bin/firezone-relay" from docker-image

## Troubleshooting

### "Connection failed (ICE timeout)" in gateway logs

- If you got something like below in the output of "systemctl status firezone-gateway" and install the gateway before the relay, try to restart the gateway.

```
INFO accept_connection{id=<id>}: snownet::node: Created new connection
INFO handle_timeout{id=<id>}: snownet::node: Connection failed (ICE timeout)
```

## KNOWN ISSUES

### At least two relays for setup

- FireZone uses relay to communicate with the portal, because of this it needs at least 2 relays 

## BREAKING CHANGES

### 10.17.2024 Two relay setup

- Previously only one relay was installed, you need at least two relays to work properly after partial restart
  - upstream issue: https://github.com/firezone/firezone/issues/6648
- You can run the command below to migrate (if you have installed FireZone through this repository before)
  - `bash <(curl -fsSL https://raw.githubusercontent.com/DoctorFTB/firezone-1.x-self-hosted/main/relay/two-relay-migrate.sh)`

## TODO

- add info about emails
