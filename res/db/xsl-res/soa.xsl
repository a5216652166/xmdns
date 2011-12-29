<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- print out a host entry -->
  <xsl:template match="domain">
    <xsl:choose>

      <!-- Generate SOA for target domain -->
      <xsl:when test="name=$target_domain">
        <xsl:text>;
;
; BIND 9 Zone file for </xsl:text>
        <xsl:value-of select="name"/>
        <xsl:text>
; This is written automatically from domain_list.xsl and contains any special
; mappings that do not fit into normal host entries (very rare occasion)
;
;
$TTL	</xsl:text>
        <xsl:value-of select="DTTL"/>
        <xsl:text>
@ IN SOA </xsl:text>
        <xsl:value-of select="PrimaryNS"/>
        <xsl:text>. </xsl:text>
        <xsl:value-of select="AdminMail"/>
        <xsl:text>. (
	</xsl:text>
	<xsl:choose>
	  <xsl:when test="Serial='DATE'">
	    <xsl:value-of select="$target_serial"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="Serial"/>
	  </xsl:otherwise>
	</xsl:choose>
        <xsl:text>	  ; Serial
	</xsl:text>
	<xsl:value-of select="Refresh"/>
        <xsl:text>	  ; Refresh
	</xsl:text>
	<xsl:value-of select="Retry"/>
        <xsl:text>	  ; Retry
	</xsl:text>
	<xsl:value-of select="Expire"/>
	<xsl:text>	  ; Expire
	</xsl:text>
	<xsl:value-of select="NCTTL"/>
	<xsl:text>	) ; Negative Cache TTL
; Any entries here have been specified by hand in the domain_list.xml file
;
; All other entries are updated via the host_list.xml file
$include "/etc/bind/views/</xsl:text>
	<xsl:value-of select="$target_view"/>
	<xsl:text>/zones/db-</xsl:text>
	<xsl:value-of select="$target_domain"/>
	<xsl:text>"
</xsl:text>
      </xsl:when>

      <!-- ignore the domain -->
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
