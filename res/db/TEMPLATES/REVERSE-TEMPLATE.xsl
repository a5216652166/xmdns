<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="host_list"/>

  <xsl:template name="net">NETWORK_NAME</xsl:template>

  <xsl:template name="ip_version">PROTOCOL</xsl:template>

  <xsl:include href="../xsl-res/reverse.xsl"/>
</xsl:stylesheet>
