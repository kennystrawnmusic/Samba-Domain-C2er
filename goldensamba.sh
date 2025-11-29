#!/usr/bin/sudo /bin/bash

args=("$@")

domain=${args[0]}
realm=${args[1]}
domadm=${args[2]}
dchost=${args[3]}

nbname=${realm%%\.*}

cat > /etc/samba/smb.conf << EOF
# Global parameters
[global]
        netbios name = $nbname
        realm = $realm
        server role = active directory domain controller
        server services = s3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, ft_scanner, winbindd, ntp_signd, kcc, dnsupdate
        workgroup = $nbname
        idmap_ldb:use rfc2307 = yes
        admin users = $domadm
        username map = /etc/samba/smbusers
        client use kerberos = desired
        template shell = /bin/bash
        kerberos method = secrets and keytab
        winbind refresh tickets = yes
        interfaces = ${args[@]:4}
        bind interfaces only = yes
        kdc default domain supported enctypes = aes256-cts-hmac-sha1-96-sk aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
        kdc:user ticket lifetime = 87600
        kdc:service ticket lifetime = 87600
        kdc:renewal lifetime = 87600
        ad dc functional level = 2016

[sysvol]
        path = /var/lib/samba/sysvol
        read only = No

[netlogon]
        path = /var/lib/samba/sysvol/$domain/scripts
        read only = No
EOF

cat > /etc/krb5.conf << EOF
[libdefaults]
        default_realm = $realm
        default_ccache_name = /tmp/%{username}.ccache
        dns_lookup_realm = true
        dns_lookup_kdc = true
        default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
        default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
        permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5
        ticket_lifetime = 3650d
        forwardable = true

[realms]
$realm = {
        admin_server = $dchost
        kdc = $dchost
        default_domain = $domain
        auth_to_local = RULE:[1:\$1@$domain]
}

[domain_realm]
        $dchost = $realm
EOF

cat > /etc/security/pam_winbind.conf << EOF
/etc/security/pam_winbind.conf
[global]
   debug = no
   debug_state = no
   try_first_pass = yes
   krb5_auth = yes
   krb5_ccache_type = FILE:/tmp/%$(USER).ccache

   cached_login = yes
   silent = no
   mkhomedir = yes
EOF
