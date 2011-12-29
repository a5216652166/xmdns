<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we have a very simple xslt that tries a trivial
     parse of the host_list.xml -->

  <!-- turn 0:1:2:3:4:5 into 00:01:02:03:04:05 -->
  <xsl:template name="expand_mac">
    <xsl:param name="macaddress"/>
    <xsl:choose>
      <xsl:when test="contains($macaddress,':')">
        <xsl:if test="string-length(substring-before($macaddress,':')) &lt; 2">
          <xsl:text>0</xsl:text>
        </xsl:if>
        <xsl:value-of select="substring-before($macaddress,':')"/>
        <xsl:text>:</xsl:text>
        <xsl:call-template name="expand_mac">
          <xsl:with-param name="macaddress" select="substring-after($macaddress,':')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="string-length($macaddress) &lt; 2">
          <xsl:text>0</xsl:text>
        </xsl:if>
        <xsl:value-of select="$macaddress" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- print out nothing for each host entry -->
  <xsl:template match="host">
    <!-- for duplicate entries, force the existance of the known-duplicate parameter -->
    <xsl:if test="macAddress">
      <xsl:call-template name="expand_mac">
        <xsl:with-param name="macaddress" select="macAddress"/>
      </xsl:call-template>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="macAddress" />
      <xsl:text>) </xsl:text>
      <xsl:value-of select="hostname" />
      <xsl:text>
</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
