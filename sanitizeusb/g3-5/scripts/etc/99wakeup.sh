#!/bin/sh

case "$1" in
    resume)
        echo "Hey I just got resumed!"
        /etc/rc.d/rc.local
	/root/shredit.sh
esac

