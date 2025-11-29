#!/bin/bash

localdom=$1
localsuffix=$2
remdom=$3
remsuffix=$4
remote=$5
localccachepath=$6
remccachepath=$7
localip=$8

# Create bidirectional trust necessary to facilitate this kind of spoofing
sudo samba-tool domain trust create $remdom.$remsuffix --type=forest --direction=both -U $remdom.$remsuffix\\Administrator --use-krb5-ccache=$remccachepath --local-dc-username=$localdom.$localsuffix\\Administrator --local-dc-use-krb5-ccache=$localccachepath

# Create wildcard record pointing at our network-facing local IP
./targetresolver.sh $localdom $localsuffix $localccachepath "*" $localip
