#!/bin/bash

remdom=$1
remsuffix=$2
remccachepath=$3
recname=$4
remote=$5
localip=$6

# Create zone on remote pointing at us
sudo samba-tool dns zonecreate $remote $remdom.$remsuffix --use-kerberos=required --use-krb5-ccache=$remccachepath

# Create A record on remote zone pointing at us
sudo samba-tool dns add $remote $remdom.$remsuffix $recname A $localip --use-kerberos=required --use-krb5-ccache=$remccachepath
