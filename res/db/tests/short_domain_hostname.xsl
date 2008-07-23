<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we do a basic sanity check for entries by
     making sure that shortname+domainname = hostname -->

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
    <xsl:variable name="composite-name">
      <xsl:value-of select="shortname" />
      <xsl:text>.</xsl:text>
      <xsl:value-of select="domainname" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$composite-name=hostname">
        <!-- Don't bother to output anything for the good case -->
      </xsl:when>
      <xsl:otherwise>
      <xsl:value-of select="hostname" />
      <xsl:text> != </xsl:text>
      <xsl:value-of select="$composite-name" />
      <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
