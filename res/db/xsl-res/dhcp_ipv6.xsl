<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="host_list"/>
  <xsl:template match="host_list">
    <!-- insert templated matches from definitiions below -->
    <xsl:apply-templates>
      <!-- sort by hostname -->
      <xsl:sort select="hostname"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--
	turn a:b:c:d: ... into a-b-c-d- ...
  -->
  <xsl:template name="pretty_mac">
    <xsl:param name="macaddress"/>
    <xsl:choose>
      <xsl:when test="contains($macaddress,':')">
        <xsl:value-of select="substring-before($macaddress,':')"/>
        <!-- <xsl:text>-</xsl:text> -->
        <xsl:call-template name="pretty_mac">
          <xsl:with-param name="macaddress" select="substring-after($macaddress,':')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$macaddress"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
	Match all hosts with a mac-address
  -->
  <xsl:template match="host[dhcp6.client-id]">

    <!-- 
	Store the ip_address that we would like to use
    -->
    <xsl:variable name="ip_address">
      <xsl:value-of select="./aaaa[@net=$target_network]"/>
    </xsl:variable>

    <!--
	for each host with a $target_network ip, lets create a host
	definition for each macaddress that exists
    -->
    <xsl:if test="./aaaa[@net=$target_network]">

      <!--
	comment to make the file human-readable
      -->
      <xsl:text>
# </xsl:text>
      <xsl:value-of select="description"/>
      <xsl:text>
# ( </xsl:text>
      <xsl:value-of select="hostname"/>
      <xsl:text> )
</xsl:text>

      <!--
	host definitions per mac-address
      -->
      <xsl:for-each select="dhcp6.client-id">
        <xsl:text>
  host </xsl:text>
        <xsl:call-template name="pretty_mac">
          <xsl:with-param name="macaddress" select="." />
        </xsl:call-template>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$target_network"/>
	<xsl:text> {
    host-identifier option dhcp6.client-id </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>;
    fixed-address6 </xsl:text>
        <xsl:value-of select="$ip_address"/>
        <xsl:text>;
  }
</xsl:text>
      </xsl:for-each>
      <xsl:text>
</xsl:text>

    </xsl:if>
  </xsl:template>
  <!--
	Match all other hosts and null them out
  -->
  <xsl:template match="host"><!-- ;	<xsl:value-of select="hostname"/>. -->
  </xsl:template>
</xsl:stylesheet>
