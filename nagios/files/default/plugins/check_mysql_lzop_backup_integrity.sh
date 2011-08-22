#! /bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION="0.0.1"

print_usage() {
        echo "Usage: $PROGNAME <options> application_name"
}

print_help() {
        print_revision $PROGNAME $REVISION
        echo ""
        print_usage
        echo ""
        echo "This plugin checks the integrity of lzop compressed backup files"
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
        -V)
                print_revision $PROGNAME $REVISION
                exit 0
                ;;
        *)
                appname=${!#}
                date=`date -d "-1 day" +"%Y_%m_%d"`
                output=`sudo /usr/bin/lzop -t /u/backup/db/${appname}/${date}_${appname}.tar.lzop 2>&1`
                status=$?
                if test "$1" = "-v" -o "$1" = "--verbose"; then
                        echo ${output}
                fi
                if test ${status} -eq 127; then
                        echo "UNKNOWN Did you install lzop?"
                        exit -1
                elif test ${status} -ne 0 ; then
                        echo "WARNING - lzop -t returned state $status - $output"
                        exit 1
                fi
                echo OK
                exit 0
                ;;
esac