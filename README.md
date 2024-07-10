# self-hosted FireZone

## Why

- I want to use FireZone in production on a vm without cloud providers and IaC tools

## Repository info

- Here's a variant of how to deploy self-hosted FireZone 1.x
  - where deployed
    - portal via docker
    - gateway via systemd
    - relay via systemd (+ extracted from docker image :sad:)

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

- TODO cuz I'm just installing it :smile: I'll update it later

## Troubleshooting

### "Connection failed (ICE timeout)" in gateway logs

- If you got something like below in the output of "systemctl status firezone-gateway" and install the gateway before the relay, try to restart the gateway.

```
INFO accept_connection{id=<id>}: snownet::node: Created new connection
INFO handle_timeout{id=<id>}: snownet::node: Connection failed (ICE timeout)
```

## TODO

### Local

- add info about emails

### Need changes from FireZone
- use version `1` instead of `latest` for docker images
- maybe rewrite seeds for the portal (currently we have a hardcoded version 0.1.0 and a duplicate `domain` folder in `/app/lib`)
- use the relay binary from the official artifact url instead of getting it from the docker image
