<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- BEGIN: show_host_a -->
  <!-- Display A record for appropriate network -->
  <xsl:template name="show_host_a">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./a[@net=$priority_net]">
	<xsl:for-each select="./a[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN A	</xsl:text>
	  <xsl:value-of select="."/>
          <xsl:text>
</xsl:text>
	</xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_a">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_a -->

  <!-- BEGIN: show_host_aaaa -->
  <!-- Display A record for appropriate network -->
  <xsl:template name="show_host_aaaa">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./aaaa[@net=$priority_net]">
	<xsl:for-each select="./aaaa[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN AAAA	</xsl:text>
          <xsl:call-template name="fill_ip6">
            <xsl:with-param name="ip_address" select="."/>
          </xsl:call-template>
          <xsl:text>
</xsl:text>
	</xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_aaaa">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_a -->

  <!-- BEGIN: show_host_cname -->
  <xsl:template name="show_host_cname">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./cname[@net=$priority_net]">
        <xsl:for-each select="./cname[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.   </xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:text>IN CNAME    </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>.
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_aaaa">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  <!-- END: show_host_cname -->

  <!-- BEGIN: show_host_loc -->
  <xsl:template name="show_host_loc">
    <!-- No real support for LOC records yet... -->
    <xsl:param name="net_list"/>
  </xsl:template>
  <!-- END: show_host_loc -->

  <!-- BEGIN: show_host_mx -->
  <!-- Display MX record for appropriate network -->
  <xsl:template name="show_host_mx">
    <xsl:param name="net_list"/>

    <xsl:variable name="default_mx_value">
      <xsl:call-template name="default_mx"/>
    </xsl:variable>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <!-- short circuit and show default MX -->
      <xsl:when test="string-length($priority_net)=0">
        <xsl:if test="string-length($default_mx_value)>0">
          <xsl:value-of select="hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN MX 40 </xsl:text>
	  <xsl:call-template name="default_mx"/>
	  <xsl:text>.
</xsl:text>
        </xsl:if>
      </xsl:when>

      <xsl:when test="./mx[@net=$priority_net]">
        <xsl:for-each select="./mx[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN MX	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_mx">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_mx -->

  <!-- BEGIN: show_host_ns -->
  <!-- Display NS record for appropriate network -->
  <xsl:template name="show_host_ns">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./ns[@net=$priority_net]">
        <xsl:for-each select="./ns[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN NS	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>.
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_ns">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_ns -->

  <!-- BEGIN: show_host_ptr -->
  <!-- Display PTR record for appropriate network -->
  <xsl:template name="show_host_ptr">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <!-- short circuit -->
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./ptr[@net=$priority_net]">
        <xsl:for-each select="./ptr[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN PTR	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>.
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_ptr">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_ptr -->

  <!-- BEGIN: show_host_rp -->
  <!-- Display RP record for appropriate network -->
  <xsl:template name="show_host_rp">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <!-- short circuit -->
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./rp[@net=$priority_net]">
        <xsl:for-each select="./rp[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN RP	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_rp">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_rp -->

  <!-- BEGIN: show_host_srv -->
  <!-- Display SRV record for appropriate network -->
  <xsl:template name="show_host_srv">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <!-- short circuit -->
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./srv[@net=$priority_net]">
        <xsl:for-each select="./srv[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN SRV	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>.
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_srv">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_srv -->

  <!-- BEGIN: show_host_txt -->
  <!-- Display TXT record for appropriate network -->
  <xsl:template name="show_host_txt">
    <xsl:param name="net_list"/>

    <!-- if this network is defined then we use this definition -->
    <xsl:variable name="priority_net">
      <xsl:choose>
	<xsl:when test="contains($net_list, ',')">
          <xsl:value-of select="substring-before($net_list, ',')"/>
	</xsl:when>
	<xsl:otherwise>
          <xsl:value-of select="$net_list"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- otherwise we try these definitions -->
    <xsl:variable name="other_net">
      <xsl:value-of select="substring-after($net_list, ',')"/>
    </xsl:variable>

    <xsl:choose>
      <!-- short circuit -->
      <xsl:when test="string-length($priority_net)=0"/>

      <xsl:when test="./txt[@net=$priority_net]">
        <xsl:for-each select="./txt[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	</xsl:text>
          <xsl:if test="@ttl">
            <xsl:value-of select="@ttl"/>
	    <xsl:text> </xsl:text>
          </xsl:if>
	  <xsl:text>IN TXT	</xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_host_txt">
          <xsl:with-param name="net_list" select="$other_net"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- END: show_host_txt -->

</xsl:stylesheet>
