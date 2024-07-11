# Installation FireZone Portal

## Preparation

1. Install [docker](https://docs.docker.com/engine/install/)
2. Copy the `.env custom-seeds.exs docker-compose.*.yml` files from the repository to the server
   - Via wget: ``wget `for name in .env custom-seeds.exs docker-compose.{portal,postgres}.yml; do echo "https://raw.githubusercontent.com/DoctorFTB/firezone-1.x-self-hosted/main/portal/$name"; done` ``
3. Configure the `.env` and `custom-seeds.exs` files (you must replace all lines with the text `REPLACE-ME`)
4. Pull all needed docker images
   - `docker compose -f docker-compose.postgres.yml pull`
   - `docker compose -f docker-compose.portal.yml pull`

## Run postgres database

1. Run `docker compose -f docker-compose.postgres.yml up -d`
2. Check is alive `docker compose -f docker-compose.postgres.yml logs`

## Run migrations and seeds

1. Run the command:
```bash
# Get domain folder with version for volume
domain_folder=` \
   docker compose \
      -f docker-compose.portal.yml \
      run \
      -v $(pwd)/custom-seeds.exs:/app/custom-seeds.exs:ro \
      --rm \
      api \
      /bin/sh -c "bin/api version | sed 's|api |domain-|'" \
`

# Run migrations and seeds
docker compose \
   -f docker-compose.portal.yml \
   run \
   -v $(pwd)/custom-seeds.exs:/app/lib/$domain_folder/priv/repo/seeds.exs:ro \
   --rm \
   api \
   /bin/sh -c "bin/migrate && bin/seed"
```
2. Check for errors in the output of the command

## Run portal

1. Run `docker compose -f docker-compose.portal.yml up -d`
2. Check is alive `docker compose -f docker-compose.portal.yml logs`

### Login information

- The portal is available at `https://app.$DOMAIN` (configured on the `web` service using the `EXTERNAL_URL` env variable)
- The account slug is `account_slug` from the `custom-seeds.exs` file
- The username and password are `admin_actor_email` and `admin_actor_password` from the `custom-seeds.exs` file
