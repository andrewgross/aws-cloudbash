#!/bin/bash

# Andrew Gross
# May 10th, 2011

# This script takes in the instance ID of an instance and returns the IP Address on an exit code of 0.  If there is
# no instance with that IP address, it returns an exit code of 1.

usage()
{
cat << EOF
usage: $0 options

This script adds takes the instance ID of an AWS Instance and returns the private IP address

OPTIONS:
   -h      Show this message
   -i      Instance ID      Ex: i-1234abcd

EOF
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


# Checks the Address passed to be a valid internal IP address
# Currently only checks the first octet instead of
# 10. | 172.{16-31}. | 192.168
#
# Checks that the Address fits the IP address pattern, then splits the
# address into 4 octets and checks the limits to make sure they are valid
valid_internal_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^(172|192|10)\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
    then
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
        # Set Instance ID passed in
        INSTANCE_ID=$1
        check_instance_id $INSTANCE_ID
        if [[ $? == 1 ]]
        then
            echo "Invalid Instance ID format"
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


for field in $(ec2-describe-instances $INSTANCE_ID | grep INSTANCE)
do
    valid_internal_ip ${field}
    if [[ $? == 0 ]]
    then
        echo $field
        exit 0
    fi
done

exit 1






