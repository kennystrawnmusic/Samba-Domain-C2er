#!/bin/bash

localdom=$1
localsuffix=$2
remdom=$3
remsuffix=$4
shadowprinsid=$5
remote=$6
localccachepath=$7
remccachepath=$8

sudo samba-tool domain trust create $remdom.$remsuffix --type=forest --direction=incoming --treat-as-external -U $remdom.$remsuffix\\Administrator --use-krb5-ccache=$remccachepath --local-dc-username=$localdom.$localsuffix\\Administrator --local-dc-use-krb5-ccache=$localccachepath

cat > remtrustattr.ldif << EOF
dn: CN=$localdom.$localsuffix,CN=System,DC=$remdom,DC=$remsuffix
action: modify
replace: trustAttributes
trustAttributes: 1096 # Bastion Forest
EOF

KRB5CCNAME=$remccachepath ldapmodify -Q -Y GSSAPI -H ldap://$remote -f remtrustattr.ldif

cat > localtrustattr.ldif << EOF
dn: CN=$remdom.$remsuffix,CN=System,DC=$localdom,DC=$localsuffix
action: modify
replace: trustAttributes
trustAttributes: 1096 # Bastion Forest
EOF

KRB5CCNAME=$localccachepath ldapmodify -Q -Y GSSAPI -H ldap://127.0.0.1 -f localtrustattr.ldif

cat > shadowcontaineradd.ldif << EOF
dn: CN=Shadow Principal Configuration,CN=Configuration,DC=$localdom,DC=$localsuffix
objectClass: top
objectClass: msDS-ShadowPrincipalContainer
description: Container for Shadow Principal objects
EOF

KRB5CCNAME=$localccachepath ldapadd -Q -Y GSSAPI -H ldap://127.0.0.1 -f shadowcontaineradd.ldif

cat > shadowprin.ldif << EOF
dn: CN=$remdom-Enterprise Admins,CN=Shadow Principal Configuration,CN=Configuration,DC=$localdom,DC=$localsuffix
changetype: add
objectClass: msDS-ShadowPrincipal
msDS-ShadowPrincipalSid: $shadowprinsid
member: CN=Administrator,CN=Users,DC=$localdom,DC=$localsuffix
EOF

KRB5CCNAME=$localccachepath ldapmodify -Q -Y GSSAPI -H ldap://127.0.0.1 -f shadowprin.ldif