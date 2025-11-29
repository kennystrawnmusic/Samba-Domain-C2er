#!/bin/bash

remdom=$1
remsuffix=$2
localccachepath=$3
recname=$4
remote=$5
localhostname=$(hostname -s)

# Check if zone exists before creating
samba-tool dns query --use-kerberos=required --use-krb5-ccache=$localccachepath $localhostname $remdom.$remsuffix @ NS &> /dev/null

if [ $? -eq 255 ]
then
  # Create zone on local DC pointing to remote domain
  sudo samba-tool dns zonecreate $localhostname $remdom.$remsuffix --use-kerberos=required --use-krb5-ccache=$localccachepath
fi

# Create A record pointing at specified IP
sudo samba-tool dns add $localhostname $remdom.$remsuffix $recname A $remote --use-kerberos=required --use-krb5-ccache=$localccachepath