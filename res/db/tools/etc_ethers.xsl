<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we have a very simple xslt that tries a trivial
     parse of the host_list.xml and outputs all hosts+a/aaaa records in
     a psuedo /etc/hosts style format -->

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
    <!-- for duplicate entries, force the existance of the known-duplicate parameter -->
    <xsl:variable name="hostname">
      <xsl:value-of select="hostname" />
    </xsl:variable>
    <xsl:for-each select="macAddress">
      <xsl:value-of select="." />
      <xsl:text> </xsl:text>
      <xsl:value-of select="$hostname" />
      <xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
