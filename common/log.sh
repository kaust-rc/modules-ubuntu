#!/bin/bash

mode=''
name=''
path=''

# Let's read in the inputs
while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            shift
            mode="$1"
            shift
        ;;

        --name)
            shift
            name="$1"
            shift
        ;;

        --path)
            shift
            path="$1"
            shift
        ;;

        --help|-h)
cat << EOF
usage: $0
    --mode        <command>, Specify command user passed to module
    --name        <name>, Specify module user wants to load
    --path        <fullpath>, Specify path of module file being loaded
EOF
            exit 0
        ;;

        -*)
            echo "$0: error - unrecognized option $1" 1>&2
            exit 1
        ;;

        *)  break
        ;;
    esac
done

kaust_id=$(id -u)
hostname=$(hostname -s)

# Connect to ubunut-dev box containing Apache, MySQL, our Python code.
curl -s --connect-timeout 1 -o /dev/null --stderr /dev/null \
    http://10.254.144.103/logs?mode=$mode'&'name=$name'&'path=$path'&'hostname=$hostname'&'id=$kaust_id
