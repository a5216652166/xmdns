<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we do a basic sanity check for entries by
     making sure that shortname+domainname = hostname -->

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
    <xsl:for-each select="./cname">
      <xsl:if test="substring(.,string-length(.),1)='.'">
        <xsl:value-of select="../hostname" />
        <xsl:text>
</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
