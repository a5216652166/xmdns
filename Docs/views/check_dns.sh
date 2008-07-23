#!/bin/bash
# Automatically generated by check_dns.xsl

ns=128.196.11.233

echo "Warning, using NS: $ns"

function check_host {
  host=$1;shift
  wanted_ips=$*
  ## perform lookup on current status in dns
  current_ips=`dig @$ns $host A +short | sort`
  if [ "$wanted_ips" != "$current_ips" ]
  then
    echo "   HOST:" $host
    echo " WANTED:" $wanted_ips
    echo "CURRENT:" $current_ips
    echo
  fi
  while [ $1 ]
  do
    check_reverse $host $1;shift
  done
}

function check_reverse {
  wanted_host=`echo $1 | tr '[:upper:]' '[:lower:]'`;shift
  ip=$1
  ## reverse ip and add .in-addr.arpa
  arpa_ip=`echo $1 | sed 's/\([0-9]*\).\([0-9]*\).\([0-9]*\).\([0-9]*\).*/\4.\3.\2.\1.in-addr.arpa/'`
  current_host=`dig @$ns $arpa_ip PTR +short | sort | tr '[:upper:]' '[:lower:]'`
  if [ "$wanted_host." != "$current_host" ]
  then
    echo "     IP:" $ip
    echo " WANTED:" $wanted_host.
    echo "CURRENT:" $current_host
    echo
  fi
}
