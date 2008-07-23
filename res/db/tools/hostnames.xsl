<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we have a very simple xslt that tries a trivial
     parse of the host_list.xml -->

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
    <!-- for duplicate entries, force the existance of the known-duplicate parameter -->
    <xsl:choose>
      <xsl:when test="known-duplicate"></xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="hostname" />
        <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
