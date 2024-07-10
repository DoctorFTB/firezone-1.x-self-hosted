# Installation nginx

## Installation

1. Install nginx `sudo apt install nginx -y`

## Configure nginx

1. Copy the `firezone.conf` file to the path `/etc/nginx/sites-enabled/firezone.conf`
   - Via wget: `wget https://raw.githubusercontent.com/DoctorFTB/firezone-1.x-self-hosted/main/reverse-proxy/nginx/firezone.conf -O /etc/nginx/sites-enabled/firezone.conf`
2. Configure the `/etc/nginx/sites-enabled/firezone.conf` file (you must replace all lines with the text `REPLACE-ME`)
3. Test nginx configuration `nginx -t`
4. Restart nginx `nginx -s reload`
