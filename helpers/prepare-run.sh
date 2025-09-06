#!/bin/bash
set -euo pipefail

# all variables set here are examples. it is up to you to use your own
: ${INSTALLER_IMAGE=~/aug19-pscgbuildos/artifacts/sep05_busyboxos_0509-x86_64-installer.img}
: ${FAKE_FILES_DIR=~/pscgdockos-materials/runtime-materials/dockosrd/fakestuff/fake-files/}
: ${DOCKER_BUILD_CONTEXT=$(readlink -f $(dirname ${BASH_SOURCE[0]})/../docker-build-context)}
: ${DOCKER_BUILD_CONTEXT_DIRS=$DOCKER_BUILD_CONTEXT/contextdirs} # we could use bind mounts for everything but this makes it easier to understand for the first build
: ${REBUILD_DOCKER=false}
: ${DOCKER_IMAGE_NAME=pscg-dockos-richosonly-*} # we will look at it but rebuild both
: ${OTA_TARGET_FILES=/home/ron/dev/otaworkshop/oot/debos-rootfs-ota/targetfiles}


LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
echo $LOCAL_DIR
cd $LOCAL_DIR/..

arg1=${1:-""} # keep set -u happy
if [ "$arg1" = "--rebuild-docker" -o $(docker images "$DOCKER_IMAGE_NAME" | wc -l) -lt 2 ] ;  then
	REBUILD_DOCKER=true
fi

if [ "$REBUILD_DOCKER" = "true" ] ; then
	echo "[+] Recreating the docker-context dirs at $DOCKER_BUILD_CONTEXT_DIRS"
	if [ -d "$DOCKER_BUILD_CONTEXT_DIRS" -o -L "$DOCKER_BUILD_CONTEXT_DIRS" ] ; then
		echo "removing previous directory $DOCKER_BUILD_CONTEXT_DIRS and recreating from $OTA_TARGET_FILES"  # can be from other places as well later
		rm -rf $DOCKER_BUILD_CONTEXT_DIRS
	fi

	# Soft links cannot be added. Hard links cannot be done for folders.
	# We COULD bind mount -  but I wanted to demonstrate that the docker is scratch + busybox executables
	# We can copy only the respective files with cp -al - but since everything so small, there is no harm in copying. We could copy the entire folder - but let's copy only
	# what we care about
	mkdir $DOCKER_BUILD_CONTEXT_DIRS
	for d in $OTA_TARGET_FILES/* ; do
		echo $d
		cp -a $d $DOCKER_BUILD_CONTEXT_DIRS/
	done

	docker build -t pscg-dockos-richosonly-noav -f docker-build-context/Dockerfile.min_pscgdebos docker-build-context || { echo "Failed to rebuild noav docker" ; exit 1 ; }
	docker build -t pscg-dockos-richosonly-av -f docker-build-context/Dockerfile.min_pscgdebos-wayland_pipewire docker-build-context || { echo "Failed to rebuild av docker" ; exit 1 ; }
fi

# We could also add the installer image here, and do a userspace only update if we wanted to, but that is not the purpose, and the full updates can be happily tested with the other projects

echo -e "[+] DONE. You may run with\n./helpers/run-pscg-dockos-richosonly.sh <av|noav>"
