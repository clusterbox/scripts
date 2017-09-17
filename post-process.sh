#!/bin/bash

#USER=cbuser
#LOGFILE=/config/logs/rclone-trigger.log

#touch $LOGFILE
#chmod 775 $LOGFILE
#chown $USER:$USER $LOGFILE

#exec &> $LOGFILE

while getopts c: option
do
 case "${option}"
 in
 c) CONTAINER=${OPTARG};;
 esac
done


#echo "Container we're curling $CONTAINER"

eval "curl -i $CONTAINER"
exit

#echo "Sonarr sonarr_episodefile_path $sonarr_episodefile_path"
#echo "Radarr path $radarr_moviefile_path" 


#if [ -n "$sonarr_episodefile_path" ]; then
#    echo "passing folder to Sonarr:  $sonarr_episodefile_path"

#    rootpath="/storage/tv/"
#    sonarr_episodefile_path=${sonarr_episodefile_path#${rootpath}}
#    sonarr_episodefile_path=$(dirname "${sonarr_episodefile_path}")
#    sonarr_episodefile_path=$(printf %q "${sonarr_episodefile_path}")

#    echo "stripped folder path to TV Show: $sonarr_episodefile_path"
#    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$sonarr_episodefile_path'"
#elif [ -n "$radarr_moviefile_path" ]; then
#    echo "passing folder to Radarr:  $radarr_moviefile_path"

#    rootpath="/storage/movies/"
#    radarr_moviefile_path=${radarr_moviefile_path#${rootpath}}
#    radarr_moviefile_path=$(dirname "${radarr_moviefile_path}")
#    radarr_moviefile_path=$(printf %q "${radarr_moviefile_path}")

#    echo "stripped folder path to movie: $radarr_moviefile_path"
#    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$radarr_moviefile_path'"
#else
#    curlCmd="curl -G '$CONTAINER'"
#fi

#eval "curl -i $curlCmd"

#exit
