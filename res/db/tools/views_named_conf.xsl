<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is to print out all registered domains -->

<!--
// Reverse resolution of all global networks
include "/etc/bind/reverse/global-named.conf";

zone "2.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/reverse/headers/ipv4-hinet-dmz";
};

zone "3.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/reverse/headers/ipv4-hinet-internal";
};
-->

  <!-- print out domainname for each entry -->
  <xsl:template match="domain">
    <xsl:text>zone "</xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>" {
	type master;
	file "/etc/bind/views/</xsl:text>
    <xsl:value-of select="$target_view" />
    <xsl:text>/headers/db-</xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>";
};

</xsl:text>
  </xsl:template>

  <xsl:template match="domain_list">
    <xsl:apply-templates />
    <xsl:text>// Reverse resolution of all global networks
include "/etc/bind/reverse/global-named.conf";
</xsl:text>
    <xsl:text>// Reverse resolution of special networks
include "/etc/bind/views/</xsl:text>
    <xsl:value-of select="$target_view" />
    <xsl:text>/extra-reverse.conf</xsl:text>
    <xsl:text>";

</xsl:text>

  </xsl:template>

</xsl:stylesheet>
