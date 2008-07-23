<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml"/>
<xsl:strip-space elements="host_list"/>
  <xsl:template match="host_list">
    <host_list>
    <!-- insert templated matches from definitiions below -->
    <xsl:apply-templates>
      <!-- sort by hostname -->
      <xsl:sort select="hostname"/>
    </xsl:apply-templates>
    </host_list>
  </xsl:template>
  <!--
	Match all hosts with hinet.lpl.arizona.edu
  -->
  <xsl:template match="host[domainname='hint.lpl.arizona.edu' or hostname='hint.lpl.arizona.edu']">
    <!--
	store the hostname for internal use...
    -->
    <xsl:variable name="current_hostname">
      <xsl:value-of select="hostname"/>
    </xsl:variable><xsl:text>;
; </xsl:text>
    <xsl:value-of select="description"/> (<xsl:value-of select="shortname"/>)<xsl:text>
</xsl:text>
    <!--
	decide on which address range to use and use it
	use for-each statements to support dns load balancing
    -->
    <xsl:choose>
      <!-- global network -->
      <xsl:when test="cname-globalnet">
        <xsl:for-each select="./cname-globalnet">
          <xsl:value-of select="$current_hostname"/>.	IN CNAME <xsl:value-of select="."/><xsl:text>.
</xsl:text>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="a-globalnet">
        <xsl:for-each select="./a-globalnet">
          <xsl:value-of select="$current_hostname"/>.	IN A <xsl:value-of select="."/><xsl:text>
</xsl:text>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <!--
	Match all other hosts and null them out
  -->
  <xsl:template match="host"><!-- ;	<xsl:value-of select="hostname"/>. -->
    <host>


      <xsl:for-each select="./hostname">
        <hostname><xsl:value-of select="." /></hostname>
      </xsl:for-each>
      <xsl:for-each select="./shortname">
        <shortname><xsl:value-of select="." /></shortname>
      </xsl:for-each>
      <xsl:for-each select="./domainname">
        <domainname><xsl:value-of select="." /></domainname>
      </xsl:for-each>
      <xsl:for-each select="./action">
        <action><xsl:value-of select="." /></action>
      </xsl:for-each>
      <xsl:for-each select="./a-globalnet">
        <a-globalnet><xsl:value-of select="." /></a-globalnet>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-dmz">
        <a-hinet-dmz><xsl:value-of select="." /></a-hinet-dmz>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-internal">
        <a-hinet-internal><xsl:value-of select="." /></a-hinet-internal>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-san">
        <a-hinet-san><xsl:value-of select="." /></a-hinet-san>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-dmz">
        <a-pirlnet-dmz><xsl:value-of select="." /></a-pirlnet-dmz>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-internal">
        <a-pirlnet-internal><xsl:value-of select="." /></a-pirlnet-internal>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-san">
        <a-pirlnet-san><xsl:value-of select="." /></a-pirlnet-san>
      </xsl:for-each>
      <xsl:for-each select="./a-printernet">
        <a-printernet><xsl:value-of select="." /></a-printernet>
      </xsl:for-each>
      <xsl:for-each select="./a-securenet">
        <a-securenet><xsl:value-of select="." /></a-securenet>
      </xsl:for-each>
      <xsl:for-each select="./cname-globalnet">
        <cname-globalnet><xsl:value-of select="." /></cname-globalnet>
      </xsl:for-each>
      <xsl:for-each select="./cname-hinet-dmz">
        <cname-hinet-dmz><xsl:value-of select="." /></cname-hinet-dmz>
      </xsl:for-each>
      <xsl:for-each select="./cname-pirlnet-internal">
        <cname-pirlnet-internal><xsl:value-of select="." /></cname-pirlnet-internal>
      </xsl:for-each>
      <xsl:for-each select="./description">
        <description><xsl:value-of select="." /></description>
      </xsl:for-each>
      <xsl:for-each select="./macAddress">
        <macAddress><xsl:value-of select="." /></macAddress>
      </xsl:for-each>


    </host>
  </xsl:template>
</xsl:stylesheet>
