#!/bin/bash

remdom=$1
remsuffix=$2
localccachepath=$3
recname=$4
remote=$5

# Create zone on local DC pointing to remote domain
sudo samba-tool dns zonecreate 127.0.0.1 $remdom.$remsuffix --use-kerberos=required --use-krb5-ccache=$localccachepath

# Create A record pointing at specified IP
sudo samba-tool dns add 127.0.0.1 $remdom.$remsuffix $recname A $remote --use-kerberos=required --use-krb5-ccache=$localccachepath
