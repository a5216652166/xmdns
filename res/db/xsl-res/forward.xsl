<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

  <!-- print out a host entry -->
  <xsl:template match="host">
    <xsl:variable name="net_list">
      <xsl:call-template name="net_list"/>
    </xsl:variable>
    <xsl:variable name="domain">
      <xsl:call-template name="domain"/>
    </xsl:variable>

    <xsl:choose>

      <!-- The normal host entry that belongs to @ -->
      <xsl:when test="domainname=$domain">
        <xsl:text>;
; </xsl:text>
        <xsl:value-of select="description"/> (<xsl:value-of select="shortname"/>)<xsl:text>
</xsl:text>
        <!-- this make appropriate calls to show ns/cname,loc/a,aaaa,txt,rp,loc/srv,txt records -->
        <xsl:call-template name="show_net_records">
          <xsl:with-param name="net_list" select="$net_list"/>
          <xsl:with-param name="original_net_list" select="$net_list"/>
        </xsl:call-template>
        <xsl:text>
</xsl:text>
      </xsl:when>

      <!-- the special case of hostname=@ -->
      <xsl:when test="hostname=$domain">
        <xsl:text>; -- special case hostname == @
; </xsl:text>
        <xsl:value-of select="description"/><xsl:text>
</xsl:text>
        <!-- this make appropriate calls to show ns/cname,loc/a,aaaa,txt,rp,loc/srv records -->
        <xsl:call-template name="show_net_records">
          <xsl:with-param name="net_list" select="$net_list"/>
          <xsl:with-param name="original_net_list" select="$net_list"/>
          <xsl:with-param name="no_ns_short_circuit">true</xsl:with-param>
        </xsl:call-template>
        <xsl:text>
</xsl:text>
      </xsl:when>

      <!-- ignore the host -->
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <!--
    show_net_records will show the set of records for the current host with a
    priority list of allowed network names

	args: net_list
		net_list: CSV of network names (pirlnet-internal,pirlnet-dmz,globalnet)
  -->

  <xsl:template name="show_net_records">
    <xsl:param name="net_list"/>
    <xsl:param name="original_net_list"/>
    <xsl:param name="no_ns_short_circuit"/>

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

    <!-- In any particular domain file, records can only co-exist of types:
	ns,[a]
	ptr
	cname,[loc]
	a|aaaa,[txt|rp|loc|mx] (and sometimes ns)
	mx
	srv,txt
	-->

    <!-- debugging output
    <xsl:text>Checking for records in: </xsl:text>
    <xsl:value-of select="$priority_net"/>
    <xsl:text> ( </xsl:text>
    <xsl:value-of select="$other_net"/>
    <xsl:text> )
</xsl:text>
    -->

    <!-- base case, then record precedence, then next network -->
    <xsl:choose>

      <!-- out of networks? -->
      <xsl:when test="string-length($priority_net)=0">
        <xsl:text>; no RR for host in network list
</xsl:text>
      </xsl:when>

      <!-- ns records in the network we want? If so, ignore anything else. -->
      <xsl:when test="./ns[@net=$priority_net]">
	<xsl:call-template name="show_host_ns">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
        <!-- If we are defining a nameserver for the current zone, we are allowed
             to specify other attributes for the domain. Otherwise we can not.
        -->
        <xsl:if test="$no_ns_short_circuit">

	  <xsl:call-template name="show_host_a">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>
	  <xsl:call-template name="show_host_aaaa">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>
	  <xsl:call-template name="show_host_loc">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>
	  <xsl:call-template name="show_host_mx">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>
	  <xsl:call-template name="show_host_rp">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>
	  <xsl:call-template name="show_host_txt">
            <xsl:with-param name="net_list" select="$original_net_list"/>
	  </xsl:call-template>

        </xsl:if>
      </xsl:when>

      <!-- ptr records in the network we want? If so, ignore anything else. -->
      <xsl:when test="./ptr[@net=$priority_net]">
	<xsl:call-template name="show_host_ptr">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
      </xsl:when>

      <!-- cname records in the network we want? If so, we might look for LOC records. -->
      <xsl:when test="./cname[@net=$priority_net]">
        <!-- Multiple CNAME records will barf, actually; TODO: force this to 1 record -->
	<xsl:for-each select="./cname[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	IN CNAME	</xsl:text>
	  <xsl:value-of select="."/>
          <xsl:text>.
</xsl:text>
	</xsl:for-each>
	<xsl:call-template name="show_host_loc">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
      </xsl:when>

      <!-- a/aaaa records in the network we want? If so, let's display txt/rp/mx/loc records to go along-->
      <xsl:when test="./aaaa[@net=$priority_net] or ./a[@net=$priority_net] or ./mx[@net=$priority_net] or ./loc[@net=$priority_net] or ./rp[@net=$priority_net] or ./txt[@net=$priority_net]">

	<xsl:call-template name="show_host_a">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_aaaa">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_loc">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_mx">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_ns">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_rp">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_txt">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>

      </xsl:when>
<!--
      <xsl:when test="./mx[@net=$priority_net]">
	<xsl:call-template name="show_host_mx">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_ns">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
      </xsl:when>
-->

      <xsl:when test="./srv[@net=$priority_net] or ./txt[@net=$priority_net]">
	<xsl:call-template name="show_host_srv">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
	<xsl:call-template name="show_host_txt">
          <xsl:with-param name="net_list" select="$original_net_list"/>
	</xsl:call-template>
      </xsl:when>

      <!-- nothing found for this net, let's try the other_net -->
      <xsl:otherwise>
        <xsl:call-template name="show_net_records">
          <xsl:with-param name="net_list" select="$other_net"/>
          <xsl:with-param name="original_net_list" select="$net_list"/>
          <xsl:with-param name="no_ns_short_circuit" select="$no_ns_short_circuit"/>
        </xsl:call-template>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <xsl:include href="ip_functions.xsl"/>

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
          <xsl:text>.	IN A	</xsl:text>
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
          <xsl:text>.	IN AAAA	</xsl:text>
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
	  <xsl:text>.	IN MX 40 </xsl:text>
	  <xsl:call-template name="default_mx"/>
	  <xsl:text>.
</xsl:text>
        </xsl:if>
      </xsl:when>

      <xsl:when test="./mx[@net=$priority_net]">
        <xsl:for-each select="./mx[@net=$priority_net]">
          <xsl:value-of select="../hostname"/>
          <xsl:text>.	IN MX	</xsl:text>
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
          <xsl:text>.	IN NS	</xsl:text>
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
          <xsl:text>.	IN PTR	</xsl:text>
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
          <xsl:text>.	IN RP	</xsl:text>
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
          <xsl:text>.	IN SRV	</xsl:text>
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
          <xsl:text>.	IN TXT	</xsl:text>
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
