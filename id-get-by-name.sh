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
            exit 1
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


get_ip_by_nslookup(){

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

get_ip_by_hosts_file(){

    local SERVER_NAME=$1

    INSTANCE_IP=$(cat /etc/hosts | grep -w $SERVER_NAME | awk '{print $1}')

    valid_ip $INSTANCE_IP

    if [[ $? == 0 ]]
    then
        echo $INSTANCE_IP
        return 0
    fi

    return 1

}

get_id_by_tag(){

    local SERVER_NAME=$1

    INSTANCE_ID=$(ec2-describe-instances | grep -B1 TAG | grep Name | grep -i -w ut1 | awk '{print $3}')

}



## TODO Implement getopts, implement flow for different options
## handle function exit codes
## Implement get_id_by_ip calls



valid_ip $INSTANCE_IP

case $? in
    0 )
        echo $(./id-get-by-ip.sh -i $INSTANCE_IP)
         ;;
    * )
         ;;
esac


    check_instance_id $INSTANCE_ID

    if [[ $? == 0 ]]
    then
        echo $INSTANCE_ID
        return 0
    fi

    return 1
