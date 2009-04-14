#!/bin/bash

cd `dirname $0`

dig lpl.arizona.edu axfr +noall +answer @vc2.lpl.arizona.edu > lpl-vc2
dig lpl.arizona.edu axfr +noall +answer @hidyns01.lpl.arizona.edu > lpl-hidyns01

cat lpl-hidyns01 | sed 's/86400//;s/604800//;s/	/ /g;s/  / /g' | tr '[:upper:]' '[:lower:]' | sort > pirl
cat lpl-vc2 | sed 's/86400//;s/604800//;s/	/ /g;s/  / /g' | tr '[:upper:]' '[:lower:]' | sort > lpl

diff lpl pirl \
	| egrep '^[<>]' \
	| sed 's/</LDAP /;s/>/SVN  /' \
	| egrep -iv 'view-hr.lpl.arizona.edu|view.lpl.arizona.edu.|timehost.lpl.arizona.edu.|2607:f088' \
	&> /tmp/view_diff.$$
export lines=`wc -l /tmp/view_diff.$$ | awk '{print $1}'`

if [ "$lines" != "0" ]; then
  echo "Subject: DNS Differences detected" &> /tmp/dns_mail.$$
  echo >> /tmp/dns_mail.$$
  echo "The following differences between the DNS schemes have been identified:         " >> /tmp/dns_mail.$$
  echo "--------------------------------------------------------------------------------" >> /tmp/dns_mail.$$
  cat /tmp/view_diff.$$ >> /tmp/dns_mail.$$
  echo "--------------------------------------------------------------------------------" >> /tmp/dns_mail.$$
  echo "                                                                                " >> /tmp/dns_mail.$$
  echo "Lines beginning with LDAP mean that the entry exists in LDAP and not in the     " >> /tmp/dns_mail.$$
  echo "subversion repository. Conversely, lines beginning with SVN mean that the entry " >> /tmp/dns_mail.$$
  echo "exists in the subversion repository and not in LDAP.                            " >> /tmp/dns_mail.$$
  echo "                                                                                " >> /tmp/dns_mail.$$
  echo "Please make sure that all differences are fixed on a timely basis to ensure the " >> /tmp/dns_mail.$$
  echo "integrity of DNS queries within the lpl.arizona.edu domains.                    " >> /tmp/dns_mail.$$
  echo "                                                                                " >> /tmp/dns_mail.$$
  echo "*pointing finger out of inbox*  This means YOU                                  " >> /tmp/dns_mail.$$
  ## LPL Sys wants to do all of their updates after January 29th
  ## and do not want to be bugged about DNS problems until then.
  # for users in tims joep terryf deanj jgotobed tferro pursch; do
  mail sys@hirise.lpl.arizona.edu < /tmp/dns_mail.$$
  rm /tmp/dns_mail.$$
fi

rm -f /tmp/view_diff.$$
