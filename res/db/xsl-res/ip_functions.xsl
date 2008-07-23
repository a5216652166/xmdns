<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- automatically match a host_list, look for a net_name template for information -->
  <xsl:template match="host_list">
    <!-- insert templated matches from definitiions below -->

    <xsl:apply-templates>
      <!-- sort by hostname -->
      <xsl:sort select="hostname"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--
	Define a way to get the last number in an ip address:
        aa.bb.cc.dd  ->  dd
  -->
  <xsl:template name="reverse_ip">
    <xsl:param name="ip_address"/>
    <xsl:choose>
      <xsl:when test="contains($ip_address,'.')">
        <xsl:call-template name="reverse_ip">
          <xsl:with-param name="ip_address" select="substring-after($ip_address,'.')"/>
        </xsl:call-template>
        <xsl:value-of select="substring-before($ip_address,'.')"/>
        <xsl:text>.</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$ip_address"/>
        <xsl:text>.</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
	Take a full IPv6 address, reverse it and split nibbles up with .
  -->
  <xsl:template name="reverse_ip6">
    <xsl:param name="ip_address"/>
    <xsl:choose>
      <!-- ignore : -->
      <xsl:when test="substring($ip_address,1,1)=':'">
        <xsl:call-template name="reverse_ip6">
          <xsl:with-param name="ip_address" select="substring($ip_address,2)"/>
        </xsl:call-template>
      </xsl:when>
      <!-- post-print -->
      <xsl:when test="string-length($ip_address)>1">
        <xsl:call-template name="reverse_ip6">
          <xsl:with-param name="ip_address" select="substring($ip_address,2)"/>
        </xsl:call-template>
        <xsl:value-of select="substring($ip_address,1,1)"/>
        <xsl:text>.</xsl:text>
      </xsl:when>
      <!-- print last nibble -->
      <xsl:otherwise>
	<xsl:value-of select="$ip_address"/>
        <xsl:text>.</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
	To make things easy, take an IPv6 address and fully qualify it:
	fe80::1 -> fe80:0000:0000:0000:0000:0000:0000:0001
	::1 -> 0000:0000:0000:0000:0000:0000:0000:0001
	1:: -> 0001:0000:0000:0000:0000:0000:0000:0000
	:: -> 0000:0000:0000:0000:0000:0000:0000:0000
  -->

  <xsl:template name="fill_ip6">
    <xsl:param name="ip_address"/>
    <xsl:variable name="prefix" select="substring-before($ip_address,'::')"/>
    <xsl:variable name="suffix" select="substring-after($ip_address,'::')"/>

    <!-- print out the ip based on :: or not -->
    <xsl:choose>
      <xsl:when test="substring-before($ip_address, '::')!=substring-after($ip_address,'::')">

        <!-- print out prefix -->
        <xsl:call-template name="fill_ip6_portion">
          <xsl:with-param name="ip_address" select="$prefix"/>
        </xsl:call-template>

        <!-- print out middle then full suffix -->
        <xsl:call-template name="fill_ip6_middle">
          <xsl:with-param name="prefix" select="$prefix"/>
          <xsl:with-param name="suffix" select="$suffix"/>
        </xsl:call-template>

        <!-- print out middle then full suffix -->
        <xsl:call-template name="fill_ip6_portion">
          <xsl:with-param name="ip_address" select="$suffix"/>
        </xsl:call-template>

      </xsl:when>
      <xsl:otherwise>

        <!-- print out whole IP -->
        <xsl:call-template name="fill_ip6_portion">
          <xsl:with-param name="ip_address" select="$ip_address"/>
        </xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- fully qualifies each segment of an IPv6 address -->
  <xsl:template name="fill_ip6_middle">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:call-template name="fill_ip6_middle_real">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="prefix_len">0</xsl:with-param>
      <xsl:with-param name="suffix_len">0</xsl:with-param>
      <xsl:with-param name="state">0</xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- fully qualifies each segment of an IPv6 address -->
  <xsl:template name="fill_ip6_middle_real">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="prefix_len"/>
    <xsl:param name="suffix_len"/>
    <xsl:param name="state"/><!-- base = 0, parse = 1, print = 2 -->
    <xsl:param name="print"/><!-- number of segments to print -->

    <xsl:if test="$state=0 and $prefix!=''">
      <xsl:text>:</xsl:text>
    </xsl:if>

    <!-- how to fill out the middle -->
    <xsl:choose>

      <xsl:when test="$state=2">
        <xsl:text>0000</xsl:text>
        <xsl:if test="$print > 1">
          <xsl:text>:</xsl:text>
          <xsl:call-template name="fill_ip6_middle_real">
	    <xsl:with-param name="state">2</xsl:with-param>
            <xsl:with-param name="prefix_len" select="$prefix_len"/>
            <xsl:with-param name="suffix_len" select="$suffix_len"/>
            <xsl:with-param name="print" select="$print - 1"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>

      <xsl:when test="$prefix='' and $suffix=''">
        <xsl:call-template name="fill_ip6_middle_real">
	  <xsl:with-param name="state">2</xsl:with-param>
          <xsl:with-param name="print" select="8 - $suffix_len - $prefix_len"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>

        <xsl:call-template name="fill_ip6_middle_real">
          <xsl:with-param name="prefix" select="substring-after($prefix,':')"/>
          <xsl:with-param name="suffix" select="substring-after($suffix,':')"/>
	  <xsl:with-param name="state">1</xsl:with-param>

	  <!-- compute the length of the prefix -->
          <xsl:with-param name="prefix_len">
            <xsl:choose>
              <xsl:when test="$prefix=''">
                <xsl:value-of select="$prefix_len"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$prefix_len + 1"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

	  <!-- compute the length of the suffix -->
          <xsl:with-param name="suffix_len">
            <xsl:choose>
              <xsl:when test="$suffix=''">
                <xsl:value-of select="$suffix_len"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$suffix_len + 1"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>

        </xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>

    <!-- <xsl:text>[MIDDLE]</xsl:text> -->

    <xsl:if test="$state=0 and $suffix!=''">
      <xsl:text>:</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- fully qualifies each segment of an IPv6 address -->
  <xsl:template name="fill_ip6_portion">
    <xsl:param name="ip_address"/>
    <xsl:variable name="suffix" select='substring-after($ip_address,":")'/>
    <xsl:variable name="segment" select="substring-before($ip_address,':')"/>

    <!-- choose between using $segment/$ip_address -->
    <xsl:choose>
      <!-- use $segment and recurse -->
      <xsl:when test="string-length($segment) > 0">
        <!-- prefix a bunch of zeros -->
        <xsl:choose>
          <xsl:when test="string-length($segment) = 4">
            <xsl:value-of select="$segment"/>
          </xsl:when>
          <xsl:when test="string-length($segment) = 3">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$segment"/>
          </xsl:when>
          <xsl:when test="string-length($segment) = 2">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$segment"/>
          </xsl:when>
          <xsl:when test="string-length($segment) = 1">
            <xsl:text>000</xsl:text>
            <xsl:value-of select="$segment"/>
          </xsl:when>
        </xsl:choose>
        <!-- output IPv6 segment seperator -->
        <xsl:text>:</xsl:text>
        <!-- recurse to fill out rest of address -->
        <xsl:call-template name="fill_ip6_portion">
          <xsl:with-param name="ip_address" select="$suffix"/>
        </xsl:call-template>
      </xsl:when>

      <!-- use $ip_address and don't recurse -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="string-length($ip_address) = 4">
            <xsl:value-of select="$ip_address"/>
          </xsl:when>
          <xsl:when test="string-length($ip_address) = 3">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$ip_address"/>
          </xsl:when>
          <xsl:when test="string-length($ip_address) = 2">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$ip_address"/>
          </xsl:when>
          <xsl:when test="string-length($ip_address) = 1">
            <xsl:text>000</xsl:text>
            <xsl:value-of select="$ip_address"/>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- from an ipv4 address with a mask (CIDR) generate a zone name -->
  <xsl:template match="network"></xsl:template>
  <xsl:template name="gen-ipv4-zone-name">
    <xsl:param name="ip_range"/>
    <xsl:variable name="rev_ip_address">
      <xsl:call-template name="reverse_ip">
        <xsl:with-param name="ip_address" select="substring-before($ip_range,'/')"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="truncate_rev_ip4">
      <xsl:with-param name="ip_address" select="$rev_ip_address"/>
      <xsl:with-param name="ip_mask" select="substring-after($ip_range,'/')"/>
    </xsl:call-template>
  </xsl:template>

  <!-- trim a reversed ipv4 zone name down to the right length -->
  <xsl:template name="truncate_rev_ip4">
    <xsl:param name="ip_address"/>
    <xsl:param name="ip_mask"/>
    <!-- Mask must be divided on a byte boundary -->
    <xsl:choose>
      <xsl:when test="$ip_mask=32">
        <xsl:value-of select="$ip_address"/>
      </xsl:when>
      <xsl:when test="$ip_mask=24">
        <xsl:value-of select="substring-after($ip_address,'.')"/>
      </xsl:when>
      <xsl:when test="$ip_mask=16">
        <xsl:value-of select="substring-after(substring-after($ip_address,'.'),'.')"/>
      </xsl:when>
      <xsl:when test="$ip_mask=8">
        <xsl:value-of select="substring-after(substring-after(substring-after($ip_address,'.'),'.'),'.')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$ip_mask mod 8 = 0 and $ip_mask &lt; 32">
      <xsl:value-of select="substring($ip_address,65 - ($ip_mask div 2))"/>
    </xsl:if>
    <xsl:text>in-addr.arpa.</xsl:text>
  </xsl:template>

  <!-- from an ipv6 address with a mask (CIDR) generate a zone name -->
  <xsl:template name="gen-ipv6-zone-name">
    <xsl:param name="ip_range"/>
    <xsl:variable name="rev_ip_address">
      <xsl:call-template name="reverse_ip6">
        <xsl:with-param name="ip_address">
          <xsl:call-template name="fill_ip6">
            <xsl:with-param name="ip_address" select="substring-before($ip_range,'/')"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="truncate_rev_ip6">
      <xsl:with-param name="ip_address" select="$rev_ip_address"/>
      <xsl:with-param name="ip_mask" select="substring-after($ip_range,'/')"/>
    </xsl:call-template>
    <xsl:text>ip6.arpa.</xsl:text>
  </xsl:template>

  <!-- trim a reversed ipv6 zone name down to the right length -->
  <xsl:template name="truncate_rev_ip6">
    <xsl:param name="ip_address"/>
    <xsl:param name="ip_mask"/>
    <!-- Mask must be divided on a nibble boundary -->
    <xsl:if test="$ip_mask mod 4 = 0 and $ip_mask &lt; 65">
      <xsl:value-of select="substring($ip_address,65 - ($ip_mask div 2))"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
