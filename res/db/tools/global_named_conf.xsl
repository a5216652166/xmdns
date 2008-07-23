<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- For all physical networks that get global resolution, create a zone definition -->

  <xsl:include href="../xsl-res/ip_functions.xsl"/>

  <xsl:template match="network[@type='physical' and not(no-global-reverse-resolve)]">
    <xsl:text>// network: </xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>
</xsl:text>
    <!-- Iterate over all prefix definitions and make a zone file -->
    <xsl:for-each select="prefix">
      <!-- Ignore certain IPv4 networks ... useful for RFC1918 addresses with IPv6 combined nets -->
      <xsl:if test="not(../ignore-ipv4-reverse-resolve) or @proto!='ipv4'">
        <xsl:text>zone "</xsl:text>
        <xsl:choose>
          <xsl:when test="@proto='ipv4'">
            <xsl:call-template name="gen-ipv4-zone-name">
              <xsl:with-param name="ip_range" select="."/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="@proto='ipv6'">
            <xsl:call-template name="gen-ipv6-zone-name">
              <xsl:with-param name="ip_range" select="."/>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
        <!-- <xsl:value-of select="." /> -->
        <xsl:text>" {
	type master;
	file "/etc/bind/reverse/headers/</xsl:text>
        <xsl:value-of select="@proto" />
        <xsl:text>-</xsl:text>
        <xsl:value-of select="../name" />
        <xsl:text>";
};
</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="network"></xsl:template>

</xsl:stylesheet>
