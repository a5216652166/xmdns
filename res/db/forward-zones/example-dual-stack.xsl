<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="host_list"/>

  <!-- define the networks we are interested in order of preference -->
  <xsl:template name="net_list">example-dual-stack,example-external,globalnet</xsl:template>

  <xsl:template name="domain"><xsl:value-of select="$target_domain"/></xsl:template>

  <xsl:template name="default_mx"></xsl:template>

  <xsl:include href="../xsl-res/forward.xsl"/>
</xsl:stylesheet>
