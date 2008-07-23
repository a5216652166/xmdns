<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we have a very simple xslt that tries a trivial
     parse of the host_list.xml -->

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
  </xsl:template>

  <!-- print out nothing for each network entry -->
  <xsl:template match="network">
  </xsl:template>

  <!-- print out nothing for each domain entry -->
  <xsl:template match="domain">
  </xsl:template>

</xsl:stylesheet>
