#!/bin/bash

#
# Note: the av path was only tested with Linux. Darwin was only tested with pulseaudio and X11 forwarding, and will remain such without av as well
#
init_av() {
	LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
	: ${RESOURCES_DIR=$(readlink -f $LOCAL_DIR/../resources)}
	: ${forward_pulseaudio="false"} # set this to true if you understand the meaning of it, and have properly set up pulseaudio at your host. You don't really need it if running pipewire and bind mounting XDG_RUNTIME_DIR (if in Linux). If in MacOS read the notes in the README file as well


	pulseaudioDockerFlags=" "     # will be populated with flags if pulseaudio server is indeed supported
	# to use this, assure you have pulse. the androding will be heard if so - but it will add a slight annoying delay
	if [ "$forward_pulseaudio" = "true" ] &&  [ "$(uname)" = "Darwin" ] && paplay $RESOURCES_DIR/androding.ogg ; then # TODO change path
		DOCKERHOST_PULSEAUDIOSERVER=host.docker.internal # (if you don't use MacOS this needs to be changed)
		DOCKERTARGET_PULSECONFIGDIR=/root/.config/pulse  # (if we configure pulse audio properly, this URL needs to be changed)
		pulseaudioDockerFlags=" -e PULSE_SERVER=$DOCKERHOST_PULSEAUDIOSERVER -v $HOME/.config/pulse:$DOCKERTARGET_PULSECONFIGDIR "
		GRAPHICS_AND_AUDIO_FLAGS=$pulseaudioDockerFlags
	else
		if [ "$1" = "av" ] ; then
			#echo -e "\x1b[33mContinuing without sound support. If you think it is wrong, make sure you have MacOS and you installed pulseaudio\x1b[0m"
			#paplay $RESOURCES_DIR/androding.ogg
			pw-cat -p $RESOURCES_DIR/androding.ogg
	
			# setting XDG_RUNTIME_DIR to a specific value to avoid 1. user collision (e.g. in /run/user/<userid>) 2. putting it in /tmp won't work as systemd clears out /tmp
			GRAPHICS_AND_AUDIO_FLAGS="-v $XDG_RUNTIME_DIR:/root/XDG_RUNTIME_DIR -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR=/root/XDG_RUNTIME_DIR"
			if [ "$forward_pulseaudio" = "true" ] ; then
				# Haven't been tested in a while, leaving it just in case. In general, there is no real reason not to use pipewire here on modern host distros
				DOCKERHOST_PULSEAUDIOSERVER=172.17.0.1
				DOCKERTARGET_PULSECONFIGDIR=/root/.config/pulse  # (if we configure pulse audio properly, this URL needs to be changed)
				pulseaudioDockerFlags=" -e PULSE_SERVER=$DOCKERHOST_PULSEAUDIOSERVER " # -v $HOME/.config/pulse:$DOCKERTARGET_PULSECONFIGDIR:ro "
				GRAPHICS_AND_AUDIO_FLAGS+=" $pulseaudioDockerFlags"
			fi
		fi
	fi
}

DOCKER_NAME=pscg-dockos-richosonly
#: ${DOCKER_FLAGS=" --network=host -d"} # e.g. "-d" to detach (should be the default behavior you use!",  e.g "-it"  to see the systemd messages on boot (but then don't detach) etc.
DOCKER_FLAGS="-it"  # We don't really need most if we run as privileged... and later systemd versions behave better with it "-it --tmpfs /tmp --tmpfs /run --tmpfs /run/lock --cgroupns private -v /sys/fs/cgroup:/sys/fs/cgroup:ro"
: ${DOCKERWIPBINDMOUNTBASE=$(readlink -f $(dirname $0)/../docker-mounts)}
: ${hostname="$DOCKER_NAME-1337"}

if [ "$(uname)" = "Darwin" ] ; then
	PRIVILEGED="--privileged"
elif [ "$(uname)" = "Linux" ] ; then
	# might not work in WSL2 will check this...
	PRIVILEGED=""
	PRIVILEGED="--privileged"
	# DOCKER_FLAGS+=" --network=bridge" # use this if you want to use ssh on the target if you run --privileged (privileged by default means --network=host)
	
fi



case $1 in
	av)
		DOCKER_IMAGE_NAME=pscg-dockos-richosonly-av
		;;
	noav)
		DOCKER_IMAGE_NAME=pscg-dockos-richosonly-noav		
		;;
	*)
		echo -e "Usage: $0 <av|noav>.\nPlease provide \$1 as av (to include graphics and audio) or noav (to not include them)"
		exit 1
		;;
esac


init_av $1

# Doing the minimum here to support some of the OTA code. Could add and mount more things, but we already demonstrated way too much in this aspect
# INIT_TO_RUN=/bin/bash # No need for systemd to check wayland or pw-cat, e.g. on the host
INIT_TO_RUN=/lib/systemd/systemd
docker run $PRIVILEGED --rm $DOCKER_FLAGS  \
	--hostname=$hostname \
	-v $DOCKERWIPBINDMOUNTBASE/data:/mnt/data \
        -v $DOCKERWIPBINDMOUNTBASE/otastate:/mnt/ota/state \
        -v $DOCKERWIPBINDMOUNTBASE/otaextract:/mnt/ota/extract \
	$GRAPHICS_AND_AUDIO_FLAGS \
        --name $DOCKER_NAME \
	$DOCKER_IMAGE_NAME $INIT_TO_RUN

