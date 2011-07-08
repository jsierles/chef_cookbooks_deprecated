#! /bin/sh

# Simple script to check for all PPAs refernced in your apt sources and
# to grab any signing keys you are missing from keyserver.ubuntu.com.
# Additionally copes with users on launchpad with multiple PPAs
# (e.g., ~asac)
#
# Author: Dominic Evans https://launchpad.net/~oldman
# License: LGPL v2

for APT in `find /etc/apt/ -name *.list`; do
    grep -o "^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+" $APT | while read ENTRY ; do
        # work out the referenced user and their ppa
        USER=`echo $ENTRY | cut -d/ -f4`
        PPA=`echo $ENTRY | cut -d/ -f5`
        # some legacy PPAs say 'ubuntu' when they really mean 'ppa', fix that up
        if [ "ubuntu" = "$PPA" ]
        then
            PPA=ppa
        fi
        # scrape the ppa page to get the keyid
        KEYID=`wget -q --no-check-certificate https://launchpad.net/~$USER/+archive/$PPA -O- | grep -o "1024R/[A-Z0-9]\+" | cut -d/ -f2`
        sudo apt-key adv --list-keys $KEYID >/dev/null 2>&1
        if [ $? != 0 ]
        then
            echo Grabbing key $KEYID for archive $PPA by ~$USER
            sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $KEYID
        else
            echo Already have key $KEYID for archive $PPA by ~$USER
        fi
    done
done

echo DONE

