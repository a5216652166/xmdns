<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is to print out all registered domains -->

  <!-- print out domainname for each entry -->
  <xsl:template match="network[(prefix or match-clients) and not(no-resolve)]">
    <xsl:text>view "</xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>-view" {
  match-clients { </xsl:text>
    <xsl:choose>
      <xsl:when test="match-clients[@special]">
        <xsl:value-of select="match-clients/@special" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="name" />
        <!-- <xsl:for-each select="match-clients">
        </xsl:for-each> -->
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>; };
</xsl:text>
    <xsl:text>  recursion </xsl:text>
    <xsl:value-of select="@recursion" />
    <xsl:text>;
  include "/etc/bind/views/</xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>/named.conf";
};

</xsl:text>
  </xsl:template>

  <xsl:template match="network"></xsl:template>

</xsl:stylesheet>
