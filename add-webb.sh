#!/bin/bash
#######authour:s.houshangi##########
input="/opt/sanc"
[ ! -f "$input" ] && { echo "Error: $0 file not found."; exit 2; }
if [ -s "$input" ];
then
 while IFS= read -r line
 do
   sed -i  '/^$/d' $input
   sed -i '/#AB/a  use_backend '$line' if { req_ssl_sni -i '$line' }' /etc/haproxy/haproxy.cfg
   sed -i '/#CD/a  backend '$line' \n mode tcp \n option ssl-hello-chk \n server '$line'-site  '$line':443 \n' /etc/haproxy/haproxy.cfg

  #echo "$line"
 done < "$input"
else
  echo "$input is empty"
fi
