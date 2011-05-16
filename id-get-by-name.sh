#!/bin/bash

# Andrew Gross
# May 10th, 2011

# This script takes in the common name of an instance and returns the Instance ID on an exit code of 0.  If there is
# no instance with that name that can be found, it returns an exit code of 1.
# The main flow of this program is to find an IP address associated with that name, then attempt to find the common
# name inside the tags associated with the instance via AWS Instance Information.


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

# Checks the Instance ID passed in to be of the valid format of 8 hex digits

check_instance_id()
{

    local IID=$1

    case ${IID} in
        i-[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]] )
            return 0
            ;;
        * )
            return 1
            ;;
    esac

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

# Does a lookup of the IP via nslookup.  Since we are in bash we should be able to assume that this function exists.
# If we aren't in bash, and in say, cygwin, hope you have nslookup installed. Also, get out while you still can.

get_ip_by_nslookup()
{

    local SERVER_NAME=$1

    INSTANCE_IP=$(nslookup ${SERVER_NAME} | grep Address:\  | awk '{print $2}')

    valid_ip $INSTANCE_IP

    if [[ $? == 0 ]]
    then
        echo $INSTANCE_IP
        return 0
    fi

    return 1

}

# Checks your local host file for an explicit reference to the name given then snatches the IP.  The IP is then passed
# around gratuitously to other functions to get the instance_id.

get_ip_by_hosts_file()
{

    local SERVER_NAME=$1

    INSTANCE_IP=$(cat /etc/hosts | grep -i -w $SERVER_NAME | awk '{print $1}')

    valid_ip $INSTANCE_IP

    if [[ $? == 0 ]]
    then
        echo $INSTANCE_IP
        return 0
    fi

    return 1

}

# Get the information from Amazon about your instances, parse the results for the TAG field with the Key 'Name',
# return the instance ID associated with the

get_id_by_server_name(){

    local SERVER_NAME=$1

    INSTANCE_ID=$(ec2-describe-instances | grep -B1 TAG | grep Name | grep -i -w $SERVER_NAME | awk '{print $3}')

    check_instance_id $INSTANCE_ID

    if [[ $? == 0 ]]
    then
        echo $INSTANCE_ID
        return 0
    fi

    return 1

}


while getopts “hn:” OPTION
do
    case $OPTION in
    h)
        # Show help information
        usage
        exit 1
        ;;
    n)
        # Set Name passed in
        SERVER_NAME=$OPTARG
        ;;
    ?)
        # Handle uncaught parameters
        usage
        exit 1
        ;;
    esac
done


# Try all 3 methods, return the first plausible result.  It may be better to try all 3 and compare, but for now
# I will stick with simplicity and slight speed improvements (API calls are expensive!)
# Of course, this assumes your DNS, /etc/hosts and EC2 Naming conventions are all in sync.  They are all in sync, right?

NS_LOOKUP__METHOD=$(get_ip_by_nslookup $SERVER_NAME)
if [[ $? == 0 ]]
then
    NS_LOOKUP__METHOD=$(./id-get-by-ip.sh -i $NS_LOOKUP__METHOD)
fi

check_instance_id $NS_LOOKUP__METHOD

if [[ $? == 0 ]]
then
    echo $NS_LOOKUP__METHOD
    exit 0
fi

HOST_FILE_METHOD=$(get_ip_by_hosts_file $SERVER_NAME)
if [[ $? == 0 ]]
then
    HOST_FILE_METHOD=$(./id-get-by-ip.sh -i $HOST_FILE_METHOD)
fi

check_instance_id $HOST_FILE_METHOD

if [[ $? == 0 ]]
then
    echo $HOST_FILE_METHOD
    exit 0
fi

TAG_METHOD=$(get_id_by_server_name $SERVER_NAME)

check_instance_id $TAG_METHOD

if [[ $? == 0 ]]
then
    echo $TAG_METHOD
    exit 0
fi

exit 1




