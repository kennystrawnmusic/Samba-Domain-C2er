#!/bin/bash

localdom=$1
localsuffix=$2
remdom=$3
remsuffix=$4
remote=$5
localccachepath=$6
remccachepath=$7
remoteip=$8

# Create trust
sudo samba-tool domain trust create $remdom.$remsuffix --type=forest --direction=both -U $remdom.$remsuffix\\Administrator --use-krb5-ccache=$remccachepath --local-dc-username=$localdom.$localsuffix\\Administrator --local-dc-use-krb5-ccache=$localccachepath

# Create wildcard record
./revdns.sh $remdom $remsuffix $localccachepath "*" 127.0.0.1 $remoteip
