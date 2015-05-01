#!/system/bin/sh
#
# Copyright (c) 2012, Motorola Mobility LLC,  All rights reserved.
#
# The purpose of this script is to annotate panic dumps with useful information
# about the context of the event.
#

export PATH=/system/bin:$PATH

annotate()
{
    VAL=`$2`
    [ "$VAL" ] || return

    # Elaborate trick to prevent multiple annotations, due to shell limitations
    PREVIFS="$IFS"
    IFS="
"
    for LINE in `cat /proc/apanic_annotate` ; do
        if [ ${LINE%:*} = "$1" ] ; then
            IFS="$PREVIFS"
            return
        fi
    done
    IFS="$PREVIFS"

    echo "$1: $VAL" > /proc/apanic_annotate
}

case $1 in
    build*)
        annotate "Build number" "getprop ro.build.display.id"
        annotate "Build config" "getprop ro.build.config.version"
        annotate "Kernel version" "cat /proc/sys/kernel/osrelease"
        ;;
    baseband*)
        annotate "Baseband version" "getprop gsm.version.baseband"
        ;;
esac

#check for panic log and copy them to /data/dontpanic
if [ -e /proc/last_kmsg ]
then
    cp /proc/last_kmsg /data/dontpanic/last_kmsg
    chown root:log /data/dontpanic/last_kmsg
    chmod 0640 /data/dontpanic/last_kmsg
fi

if [ -e /proc/apanic_console ]
then
    cp /proc/apanic_console /data/dontpanic/apanic_console
    chown root:log /data/dontpanic/apanic_console
    chmod 0640 /data/dontpanic/apanic_console

    cp /proc/apanic_threads /data/dontpanic/apanic_threads
    chown root:log  /data/dontpanic/apanic_threads
    chmod 0640  /data/dontpanic/apanic_threads

    cp /proc/apanic_app_threads /data/dontpanic/apanic_app_threads
    chown root:log /data/dontpanic/apanic_app_threads
    chmod 0640 /data/dontpanic/apanic_app_threads

    #must erase apanic partition
    echo "1" > /proc/apanic_console
fi

#report to server
/system/bin/kpgather
