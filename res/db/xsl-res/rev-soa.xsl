<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- print out a host entry -->
  <xsl:template match="network">
    <xsl:if test="name=$target_network">
    <xsl:choose>

      <!-- Generate SOA for target domain -->
      <xsl:when test="name=$target_network">
        <xsl:text>;
;
; BIND 9 Zone file for </xsl:text>
        <xsl:value-of select="name"/>
        <xsl:text>
; This is written automatically from domain_list.xsl and contains any special
; mappings that do not fit into normal host entries (very rare occasion)
;
;
$TTL	3600
@ IN SOA </xsl:text>
        <xsl:value-of select="ns"/>
        <xsl:text>. root.</xsl:text>
        <xsl:value-of select="ns"/>
        <xsl:text>. (
	1	; Serial
	604800	; Refresh
	86400	; Retry
	2419200	; Expire
	604800	) ; Negative Cache TTL
</xsl:text>
        <xsl:for-each select="ns">
	  <xsl:text>@	IN	NS	</xsl:text>
	  <xsl:value-of select="."/>
	  <xsl:text>.
</xsl:text>
        </xsl:for-each>
	<xsl:text>$include "/etc/bind/reverse/zones/</xsl:text>
	<xsl:value-of select="$target_proto"/>
	<xsl:text>-</xsl:text>
	<xsl:value-of select="$target_network"/>
	<xsl:text>"
</xsl:text>
      </xsl:when>

      <!-- ignore the domain -->
      <xsl:otherwise/>
    </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
