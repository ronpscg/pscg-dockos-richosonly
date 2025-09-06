# pscg-dockos-richosonly - a docker running a rootfs that can help in testing userspace features very quickly

The project aims at running a *Debian/Ubuntu* base system that could be PscgBuildOS, but you can easily replace it with your own things.
It has been used in the past to test very quickly the OTA logic, and to demonstrate some [Linux on MacOS](https://www.youtube.com/watch?v=j5ajUgxmqKU&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=31) and [Linux on Windows/WSL2](https://www.youtube.com/watch?v=6lqMeg_n7l4&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=32) features.


## Design and layering
This aims to be a userspace only docker. However, under MacOS (and maybe Windows?) we can take advantage of the incompetence of Docker, and that it actually provides a VM. This is not the current scope though.

## Building and using

### Building:
```
./helpers/prepare-run.sh
```

This build two docker images:
- *run-pscg-dockos-richosonly-av* which also has the packages to use *wayland* and *pipewire* (on the host)
- *run-pscg-dockos-richosonly-noav* which does not provide multimedia support. The *-av* version bulid on this one.

It also takes the *ota* project code from out of tree and uses it. You can add similarily more things in the build context, or bind mounts.

You can rebuild the docker with `./helpers/prepare-run.sh --rebuild-docker


Note: In the past (before cleaning up the repo) pulseaudio packages were installed as well. Since I don't have *right now* MacOS or Windows available, I can't test them, but in a way, everything worked for all of them too, and may need some refreshind (hey, I have the Youtube videos to prove that...)

### Running:
```
./helpers/run-pscg-dockos-richosonly.sh <av|noav>
```

## More usage tips and hacks
To get into your docker, you would naturally do `docker exec -it pscg-dockos-richosonly bash`. 
However, to use it as you usually would access the target, you would want to either login, or ssh.
This will give you the look and feel of ssh-ing:
```
docker exec -it pscg-dockos-richosonly ssh -o StrictHostKeyChecking=no root@localhost
```

# Setting up pulseaudio (docker --> MacOS host)

MacOS pulseaudio server Installation:
```
    brew install pulseaudio
    pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon
```

Run docker with:
```
export DOCKERHOST_PULSEAUDIOSERVER=host.docker.internal
export DOCKERTARGET_PULSECONFIGDIR=/root/.config/pulse # Not sure about it

docker run \
    -e PULSE_SERVER=$DOCKERHOST_PULSEAUDIOSERVER \
    -v ~/.config/pulse:$DOCKERTARGET_PULSECONFIGDIR \
    ...
```

