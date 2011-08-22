#! /bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION="0.0.1"

print_usage() {
        echo "Usage: $PROGNAME application_name exmected_minimum_size_in_bytes"
}

print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        print_usage
        echo ""
        echo "This plugin checks the size of MySQL backup files"
        echo ""
        support
        exit 0
}

case "$1" in
        --help)
                print_help
                exit 0
                ;;
        -h)
                print_help
                exit 0
                ;;
        --version)
        print_revision $PROGNAME $REVISION
                exit 0
                ;;
        *)
                appname=${!#}
                date=`date -d "-1 day" +"%Y_%m_%d"`
                filename="/u/backup/db/$1/${date}_$1.tar.lzop"
                filesize=$(sudo stat -c%s $filename)
                if [ $filesize -lt $2 ]; then
                        echo "CRITICAL - ${filename} was ${filesize} bytes in size, minimum was $2"
                        exit 2
                fi
                echo "OK - ${filename} was ${filesize} bytes in size, minimum was $2"
                exit 0
                ;;
esac