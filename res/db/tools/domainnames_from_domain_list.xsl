<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is to print out all registered domains -->

  <!-- print out domainname for each entry -->
  <xsl:template match="domain">
    <xsl:value-of select="name" />
    <xsl:text>
</xsl:text>
  </xsl:template>

</xsl:stylesheet>
