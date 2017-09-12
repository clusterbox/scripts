#!/bin/sh

#Source instructions for rClone implementation
#https://enztv.wordpress.com/2016/10/19/using-amazon-cloud-drive-with-plex-media-server-and-encrypting-it/

#Source instructions for Dockerizing Clusterbox
#https://zackreed.me/docker-how-and-why-i-use-it/

USER=cbuser
KEEPMOUNTS=false
ENCRYPTEDMOVIEFOLDER=IepOejn11g4nP5JHvRa6GShx
ENCRYPTEDTVFOLDER=jCAtPeFmvjtPrlSeYLx5G2kd

while getopts ':k' opts; do
    case "${opts}" in
        k) KEEPMOUNTS=$OPTARG ;;
    esac
done

#if [ "$KEEPMOUNTS" = false ] ; then
#    /bin/bash /home/$USER/scripts/mount.sh
#fi

echo "Stopping and removing all docker containers..."
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)


echo "Creating docker container folder structures..."
sudo mkdir -p /docker/containers/nzbget/config
sudo mkdir -p /docker/containers/plex/config
sudo mkdir -p /docker/containers/plex/transcode
sudo mkdir -p /docker/containers/plexpy/config
sudo mkdir -p /docker/containers/portainer/config
sudo mkdir -p /docker/containers/radarr/config
sudo mkdir -p /docker/containers/sonarr/config
sudo mkdir -p /docker/containers/organizr/config
sudo mkdir -p /docker/containers/ombi/config
sudo mkdir -p /docker/containers/jackett/config
sudo mkdir -p /docker/containers/jackett/blackhole
sudo mkdir -p /docker/containers/transmission/config
sudo mkdir -p /docker/containers/transmission/data
sudo mkdir -p /docker/containers/nginx-proxy/certs
sudo mkdir -p /docker/downloads/completed/movies
sudo mkdir -p /docker/downloads/completed/tv
sudo chown -R $USER:$USER /docker

sudo mkdir -p /etc/nginx/certs
sudo touch /etc/nginx/vhost.d
mkdir -p /usr/share/nginx/html

echo "Starting Nginx Proxy Container..."
#docker rm -fv docker-proxy; docker run -d \
#--name=docker-proxy \
#-p 80:80 \
#-p 433:433 \
#-v /var/run/docker.sock:/tmp/docker.sock:ro \
#-e DEFAULT_HOST=portal.clusterboxcloud.com \
#jwilder/nginx-proxy:alpine



docker rm -fv nginx-proxy; docker run -d \
--name=nginx-proxy \
-e DEFAULT_HOST=portal.clusterboxcloud.com \
-p 80:80 \
-p 443:443 \
-v /docker/containers/nginx-proxy/certs:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy:alpine


echo "Starting Nginx LetsEncrypt Container..."
docker rm -fv nginx-proxy-lets-encrypt; docker run -d \
--name=nginx-proxy-lets-encrypt \
-v /docker/containers/nginx-proxy/certs:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--volumes-from nginx-proxy \
jrcs/letsencrypt-nginx-proxy-companion



echo "Starting NZBget Container..."
docker rm -fv nzbget; docker run -d \
--name nzbget \
-p 6789:6789 \
-e PUID=1000 -e PGID=1000 \
-v /docker/containers/nzbget/config:/config \
-v /docker/downloads:/downloads \
-v /storage:/storage \
linuxserver/nzbget


echo "Starting Plex Container..."
docker rm -fv plex; docker run -d \
--name plex \
-p 32400:32400 \
-p 32400:32400/udp \
-p 32469:32469 \
-p 32469:32469/udp \
-p 5353:5353/udp \
-p 1900:1900/udp \
-e VIRTUAL_HOST=plex.clusterboxcloud.com \
-e VIRTUAL_PORT=32400 \
-e PLEX_UID=1000 -e PLEX_GID=1000 \
-e TZ="America/Los Angeles" \
-v /docker/containers/plex/config:/config \
-v /docker/containers/plex/transcode:/transcode \
-v /storage:/data \
plexinc/pms-docker:plexpass


echo "Starting PlexPy Container..."
docker rm -fv plexpy; docker run -d \
--name=plexpy \
--link plex:plex \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/plexpy/config:/config \
-v /docker/containers/plex/config/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
-e PUID=1000 -e PGID=1000 \
-p 8181:8181 \
linuxserver/plexpy


echo "Starting Portainer Container..."
docker rm -fv portainer; docker run -d \
--name=portainer \
-p 9000:9000 \
-v /docker/containers/portainer/config:/data \
-v /var/run/docker.sock:/var/run/docker.sock portainer/portainer


echo "Starting Jackett..."
docker rm -fv jackett; docker run -d \
--name=jackett \
-v /docker/containers/jackett/config:/config \
-v /docker/containers/jackett/blackhole:/downloads \
-e PUID=1000 -e PGID=1000 \
-e TZ="America/Los Angeles" \
-v /etc/localtime:/etc/localtime:ro \
-p 9117:9117 \
linuxserver/jackett


echo "Starting Transmission..."
docker rm -fv transmission; docker run -d --cap-add=NET_ADMIN --device=/dev/net/tun -d \
--name=transmission \
--restart="always" \
--dns 8.8.8.8 \
--dns 8.8.8.4 \
-v /docker/containers/transmission/data:/data \
-v /etc/localtime:/etc/localtime:ro \
--env-file /docker/containers/transmission/config/DockerEnv \
-p 9091:9091 \
haugene/transmission-openvpn


echo "Starting rclone.movie Container..."
docker rm -fv rclone.movie; docker run -d \
--name=rclone.movie \
-p 8081:8080 \
-v /home/$USER/.local/$ENCRYPTEDMOVIEFOLDER:/data \
-v /home/$USER/local/movies:/media \
-v /home/$USER/rclone_config:/config \
-e SYNC_COMMAND="rclone copy -v /data/ gdrive_clusterbox:cb/$ENCRYPTEDMOVIEFOLDER --size-only --config=/config/rclone.conf  --log-file=/config/rclone_movie_clusterbox.log" \
that1guy/docker-rclone


echo "Starting Radarr Container..."
docker rm -fv radarr; docker run -d \
--name=radarr \
--link rclone.movie:rclone.movie \
--link transmission:transmission \
--link nzbget:nzbget \
-v /docker/containers/radarr/config:/config \
-v /storage:/storage \
-v /docker/downloads:/downloads \
-v /docker/containers/transmission/data:/data \
-v /home/$USER/scripts:/scripts \
-e PUID=1000 -e PGID=1000 \
-e TZ="America/Los Angeles" \
-p 7878:7878 \
linuxserver/radarr


echo "Starting rclone.tv Container..."
docker rm -fv rclone.tv; docker run -d \
--name=rclone.tv \
-p 8082:8080 \
-v /home/$USER/.local/$ENCRYPTEDTVFOLDER:/data \
-v /home/$USER/local/tv:/media \
-v /home/$USER/rclone_config:/config \
-e SYNC_COMMAND="rclone copy -v /data/ gdrive_clusterbox:cb/$ENCRYPTEDTVFOLDER --size-only --config=/config/rclone.conf  --log-file=/config/rclone_tv_clusterbox.log" \
that1guy/docker-rclone


echo "Starting Sonarr Container..."
docker rm -fv sonarr; docker run -d \
--name=sonarr \
--link rclone.tv:rclone.tv \
--link transmission:transmission \
--link nzbget:nzbget \
-p 8989:8989 \
-e PUID=1000 -e PGID=1000 \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/sonarr/config:/config \
-v /storage:/storage \
-v /docker/downloads:/downloads \
-v /docker/containers/transmission/data:/data \
-v /home/$USER/scripts:/scripts \
linuxserver/sonarr


echo "Starting Ombi..."
docker rm -fv ombi; docker run -d \
--name=ombi \
--link radarr:radarr \
--link sonarr:sonarr \
--link plex:plex \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/ombi/config:/config \
-e PUID=1000 -e PGID=1000 \
-e TZ="America/Los Angeles" \
-p 3579:3579 \
linuxserver/ombi


echo "Starting Watchtower..."
docker rm -fv watchtower; docker run -d \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
v2tec/watchtower --interval 60 --cleanup


echo "Starting Log.io..."
docker rm -fv logio; docker run -d \
-p 28778:28778 \
-e "LOGIO_ADMIN_USER=clusterbox" \
-e "LOGIO_ADMIN_PASSWORD=4letterword" \
--name logio \
blacklabelops/logio


echo "Starting Log.io Harvester..."
docker rm -fv harvester; docker run -d \
-v /var/lib/docker/containers:/var/lib/docker/containers \
--restart="always" \
-e "LOGIO_HARVESTER1STREAMNAME=docker" \
    -e "LOGIO_HARVESTER1LOGSTREAMS=/var/lib/docker/containers" \
    -e "LOGIO_HARVESTER1FILEPATTERN=*-json.log" \
-v /docker:/docker \
-e "LOGIO_HARVESTER2STREAMNAME=ombi" \
    -e "LOGIO_HARVESTER2LOGSTREAMS=/docker/containers/ombi/config/logs" \
    -e "LOGIO_HARVESTER2FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER3STREAMNAME=nzbGet_downloads" \
    -e "LOGIO_HARVESTER3LOGSTREAMS=/docker/downloads" \
    -e "LOGIO_HARVESTER3FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER4STREAMNAME=organizr" \
    -e "LOGIO_HARVESTER4LOGSTREAMS=/docker/containers/organizr" \
    -e "LOGIO_HARVESTER4FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER5STREAMNAME=plex" \
    -e "LOGIO_HARVESTER5LOGSTREAMS=/docker/containers/plex" \
    -e "LOGIO_HARVESTER5FILEPATTERN=*.log *.txt" \
-e "LOGIO_HARVESTER6STREAMNAME=plexpy" \
    -e "LOGIO_HARVESTER6LOGSTREAMS=/docker/containers/plexpy" \
    -e "LOGIO_HARVESTER6FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER7STREAMNAME=radarr" \
    -e "LOGIO_HARVESTER7LOGSTREAMS=/docker/containers/radarr" \
    -e "LOGIO_HARVESTER7FILEPATTERN=*.log *.txt" \
-e "LOGIO_HARVESTER8STREAMNAME=sonarr" \
    -e "LOGIO_HARVESTER8LOGSTREAMS=/docker/containers/sonarr" \
    -e "LOGIO_HARVESTER8FILEPATTERN=*.log *.txt" \
-v /home/$USER/rclone_config:/rclone_config \
-e "LOGIO_HARVESTER9STREAMNAME=rclone" \
    -e "LOGIO_HARVESTER9LOGSTREAMS=/rclone_config" \
    -e "LOGIO_HARVESTER9FILEPATTERN=*.log" \
--link logio:logio \
--name harvester \
--user root \
blacklabelops/logio harvester


echo "Starting Wetty Terminal..."
docker rm -fv term; docker run -d \
--name term \
-p 3000 \
-dt krishnasrinivas/wetty


echo "Starting Netdata..."
docker rm -fv netdata; docker run -d --cap-add SYS_PTRACE \
--name=netdata \
-v /proc:/host/proc:ro \
-v /sys:/host/sys:ro \
-v /var/run/docker.sock:/var/run/docker.sock \
-p 19999:19999 \
titpetric/netdata:latest


echo "Starting Organizr..."
docker rm -fv organizr; docker run -d \
--name=organizr \
--link sonarr:sonarr \
--link radarr:radarr \
--link portainer:portainer \
--link plexpy:plexpy \
--link nzbget:nzbget \
--link ombi:ombi \
--link logio:logio \
--link term:term \
--link jackett:jackett \
--link transmission:transmission \
--link netdata:netdata \
-v /docker/containers/organizr/config:/config \
-e PUID=1000 -e PGID=1000 \
-e VIRTUAL_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_EMAIL=clusterbox@clusterboxcloud.com \
-e HTTPS_METHOD=noredirect \
-p 29999:29999 \
lsiocommunity/organizr


echo "******** ClusterBox Build Complete ********"

exit
