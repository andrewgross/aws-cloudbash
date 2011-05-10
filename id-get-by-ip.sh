#!/bin/bash

# Andrew Gross
# May 10th, 2011

# This script takes in the IP address of an instance and returns the Instance ID on an exit code of 0.  If there is
# no instance with that IP address, it returns an exit code of 1.

usage()
{
cat << EOF
usage: $0 options

This script adds takes the IP Address of an AWS Instance and returns the Instance ID

OPTIONS:
   -h      Show this message
   -i      IP Address      Ex: 192.168.123.456

EOF
}

# Checks that the input fits the IP address pattern, then splits the
# address into 4 octets and checks the limits to make sure they are valid

valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


# Checks the Instance ID passed in to be of the valid format of 8 hex digits

check_instance_id()
{

    local IID=$1

    case ${IID} in
        i-[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]] )
            return 0
            ;;
        * )
            exit 1
            ;;
    esac

}


# Use getops to parse the options and assign them to variables
# Also does some simple checking on existence of a passed in file
while getopts “hi:” OPTION
do
    case $OPTION in
    h)
        # Show help information
        usage
        exit 1
        ;;
    i)
        # Set IP Address passed in
        IP_ADDRESS=$OPTARG
        valid_ip $IP_ADDRESS
        if [[ $? == 1 ]]
        then
            echo "Invalid IP Address format"
            usage
            exit 1
        fi
        ;;
    ?)
        # Handle uncaught parameters
        usage
        exit 1
        ;;
    esac
done

INSTANCE_ID=$(ec2-describe-instances | grep $IP_ADDRESS | grep INSTANCE | awk '{print $2}')

check_instance_id $INSTANCE_ID

if [[ $? == 0 ]]
then
    echo $INSTANCE_ID
    exit 0
fi

exit 1



