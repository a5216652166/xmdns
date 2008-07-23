<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is to print out all registered domains -->

  <!-- print out domainname for each entry -->
  <xsl:template match="network[(prefix or match-clients) and not(no-resolve)]">
    <xsl:text>acl "</xsl:text>
    <xsl:value-of select="name" />
    <xsl:text>" {
</xsl:text>
    <xsl:choose>

      <xsl:when test="./match-clients[@special='none' or @special='any' or @special='localhost' or @special='localnets']">
          <xsl:text>  // Special match-clients clause specified
</xsl:text>
      </xsl:when>

      <xsl:when test="match-clients">
          <xsl:text>  // match-clients clause specified
</xsl:text>
        <xsl:for-each select="match-clients">
          <xsl:text>  </xsl:text>
          <xsl:value-of select="." />
          <xsl:text>;
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <xsl:otherwise>
        <xsl:for-each select="prefix">
          <xsl:text>  </xsl:text>
          <xsl:value-of select="." />
          <xsl:text>;
</xsl:text>
        </xsl:for-each>
      </xsl:otherwise>

    </xsl:choose>
    <xsl:text>};

</xsl:text>
  </xsl:template>

  <xsl:template match="network"></xsl:template>

</xsl:stylesheet>
