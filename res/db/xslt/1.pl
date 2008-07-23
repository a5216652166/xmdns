#!/usr/bin/perl

foreach my $attr ( qw(
hostname
shortname
domainname
action
a-globalnet
a-hinet-dmz
a-hinet-internal
a-hinet-san
a-pirlnet-dmz
a-pirlnet-internal
a-pirlnet-san
a-printernet
a-securenet
cname-globalnet
cname-hinet-dmz
cname-pirlnet-internal
description
macAddress
) ) {
  print qq|
      <xsl:for-each select="./$attr">
        <$attr><xsl:value-of select="." /></$attr>
      </xsl:for-each>|;
#      <xsl:if test="$attr">
#        <$attr><xsl:value-of select="$attr" /></$attr>
#      </xsl:if>|;
}
