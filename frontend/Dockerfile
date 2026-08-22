FROM lscr.io/linuxserver/swag:latest

COPY build/web /defaults/www
COPY nginx.conf /defaults/nginx/site-confs/default.conf
COPY copy-web.sh /custom-cont-init.d/10-copy-web

RUN chmod +x /custom-cont-init.d/10-copy-web

EXPOSE 80 443