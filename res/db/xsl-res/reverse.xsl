<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- print out a host entry -->
  <xsl:template match="host">

    <xsl:variable name="ip_version">
      <xsl:call-template name="ip_version"/>
    </xsl:variable>

    <xsl:variable name="node_filter">
      <xsl:choose>
        <xsl:when test="$ip_version='IPv4'">
          <xsl:text>a</xsl:text>
        </xsl:when>
        <xsl:when test="$ip_version='IPv6'">
          <xsl:text>aaaa</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>NO_SUCH_PROTOCOL</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="network_filter">
      <xsl:call-template name="net"/>
    </xsl:variable>

    <!-- we are doing reverse, are we doing v4 or v6? -->
    <xsl:choose>
      <!-- doing IPv4 reverse zone -->
      <xsl:when test="$ip_version='IPv4'">

        <!-- only display when relevant nodes exist -->
        <xsl:if test="./a[@net=$network_filter]">

          <!-- Human readable label -->
          <xsl:text>;
; </xsl:text>
          <xsl:value-of select="description"/> (<xsl:value-of select="shortname"/>)<xsl:text>
</xsl:text>

          <xsl:call-template name="print_rev_4">
            <xsl:with-param name="net">
              <xsl:call-template name="net"/>
            </xsl:with-param>
          </xsl:call-template>

        </xsl:if>

      </xsl:when>
      <!-- doing IPv6 reverse zone -->
      <xsl:when test="$ip_version='IPv6'">

        <!-- only display when relevant nodes exist -->
        <xsl:if test="./aaaa[@net=$network_filter]">

          <!-- Human readable label -->
          <xsl:text>;
; </xsl:text>
          <xsl:value-of select="description"/> (<xsl:value-of select="shortname"/>)<xsl:text>
</xsl:text>

          <xsl:call-template name="print_rev_6">
            <xsl:with-param name="net">
              <xsl:call-template name="net"/>
            </xsl:with-param>
          </xsl:call-template>

        </xsl:if>
      </xsl:when>

    </xsl:choose>

    <!-- manual ptr records in the network we want? If so, ignore anything else. -->
    <xsl:if test="./ptr[@net=$network_filter]">
      <xsl:call-template name="print_ptr">
        <xsl:with-param name="net">
          <xsl:call-template name="net"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>

  <!-- print out reverse records for specified network (IPv4) -->
  <xsl:template name="print_rev_4">
    <xsl:param name="net"/>

    <xsl:for-each select="./a[@net=$net]">
      <xsl:call-template name="reverse_ip">
        <xsl:with-param name="ip_address">
          <xsl:value-of select="."/>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:text>in-addr.arpa.	IN PTR </xsl:text>
      <xsl:value-of select="../hostname"/>
      <xsl:text>.
</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- print out reverse records for specified network (IPv6) -->
  <xsl:template name="print_rev_6">
    <xsl:param name="net"/>

    <xsl:for-each select="./aaaa[@net=$net]">
      <xsl:call-template name="reverse_ip6">
        <xsl:with-param name="ip_address">
          <xsl:call-template name="fill_ip6">
            <xsl:with-param name="ip_address" select="."/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:text>ip6.arpa. IN PTR </xsl:text>
      <xsl:value-of select="../hostname"/>
      <xsl:text>.
</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- print out manual reverse records for specified network -->
  <xsl:template name="print_ptr">
    <xsl:param name="net"/>

    <xsl:for-each select="./ptr[@net=$net]">
      <xsl:value-of select="."/>
      <xsl:text>	IN PTR </xsl:text>
      <xsl:value-of select="../hostname"/>
      <xsl:text>.
</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:include href="ip_functions.xsl"/>

</xsl:stylesheet>
<!--

  A6 records are still experimental, AAAA seems to be the standard so we
  will use AAAA and simple IN PTR records for reverse resolution. The kame
  project does this:

    www.kame.net. 86400 IN AAAA 2001:0200:0000:8002:0203:47ff:fea5:3085
    5.8.0.3.5.a.e.f.f.f.7.4.3.0.2.0.2.0.0.8.0.0.0.0.0.0.2.0.1.0.0.2.ip6.arpa. 86400 IN PTR orange.kame.net.

  Also note that the ip6.arpa. tree is used instead of the ip6.int. tree
  which seems to have been deprecated before A6 records are widely used?
  http://cr.yp.to/djbdns/killa6.html - reasons against A6 records
  http://www.zytrax.com/books/dns/ch8/a6.html - states that A6 is not used

  The A6 standard is considerably more complex than the AAAA
  standard and is seen as a crufty system. A6 will not be deployed
  by these scripts for now.
  (AAAA - RFC 1886)
  (A6   - RFC 2874)

-->
