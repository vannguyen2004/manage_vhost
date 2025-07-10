#!/bin/bash
domain=$1
if [[ -f "/etc/apache2/sites-available/${domain}.conf" ]] || [[ -f "/etc/apache2/sites-available/${domain}-le-ssl.conf" ]] ; then
        exit 0
else
        exit 1
fi
