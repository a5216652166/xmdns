<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:strip-space elements="host_list"/>
  <xsl:template match="host_list">
    <html><head>
    <link href="hosts.css" rel="stylesheet" type="text/css"/>
    </head>
    <body bgcolor="#000000" text="#FFFFFF" link="#0000FF" vlink="#5555AA">
    <h1>Network Key</h1>
    <table>
      <tr><td width="25%">
        <div class="sonett">Sonett</div>
        <div class="hinet_dmz">HiNet DMZ</div>
        <div class="hinet_int">HiNet Int</div>
        <div class="pirlnet_dmz">PIRL DMZ</div>
        <div class="pirlnet_int">PIRL Int</div>
        <div class="securenet">Secure Net</div>
        <div class="printernet">Printer Net</div>
        <div class="hinet-san">Storage Net</div>
      </td></tr>
    </table>
    <div></div>
    <h1>Host List</h1>
    <table>
      <tr>
        <th class="hostname">Host Name</th>
        <th class="hostname">Domain</th>
        <th class="hostname">Network</th>
        <th class="description">Description</th>
      </tr>
    <!-- insert templated matches from definitiions below -->
    <xsl:apply-templates>
      <!-- sort by hostname -->
      <xsl:sort select="domainname"/>
      <xsl:sort select="hostname"/>
    </xsl:apply-templates>
    </table>
    </body>
    </html>
  </xsl:template>
  <!--
	Match all hosts with hinet.lpl.arizona.edu
  -->
  <xsl:template match="host">
    <!--
	store the hostname for internal use...
    -->
    <tr>
      <td class="hostname"><xsl:value-of select="shortname"/></td>
      <td class="hostname"><xsl:value-of select="domainname"/></td>
      <td>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">sonettnet</xsl:with-param>
          <xsl:with-param name="net_class">sonett</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">hinet-dmz</xsl:with-param>
          <xsl:with-param name="net_class">hinet_dmz</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">hinet-internal</xsl:with-param>
          <xsl:with-param name="net_class">hinet_int</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">pirlnet-dmz</xsl:with-param>
          <xsl:with-param name="net_class">pirlnet_dmz</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">pirlnet-internal</xsl:with-param>
          <xsl:with-param name="net_class">pirlnet_int</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">securenet</xsl:with-param>
          <xsl:with-param name="net_class">securenet</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">printernet</xsl:with-param>
          <xsl:with-param name="net_class">printernet</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="show_net_ip">
          <xsl:with-param name="net">hinet-san</xsl:with-param>
          <xsl:with-param name="net_class">hinet-san</xsl:with-param>
        </xsl:call-template>
	</td>
      <td class="description">
        <xsl:value-of select="description"/>
        <div class="action"><xsl:value-of select="action"/></div>
      </td>
    </tr>
  </xsl:template>

  <xsl:template name="show_net_ip">
    <xsl:param name="net" />
    <xsl:param name="net_class" />
    <xsl:variable name="anet"><xsl:text>a-</xsl:text><xsl:value-of select="$net"/></xsl:variable>
    <xsl:choose>
      <xsl:when test="./a[@net=$net] or ./aaaa[@net=$net]">
        <div>
          <xsl:attribute name="class">
            <xsl:value-of select="$net_class"/>
          </xsl:attribute>
          <div>
          <xsl:value-of select="./a[@net=$net]"/>
          <div>
          </div>
          <xsl:value-of select="./aaaa[@net=$net]"/>
          </div>
        </div>
      </xsl:when>
      <xsl:when test="./cname[@net=$net]">
        <div>
          <xsl:attribute name="class">
            <xsl:value-of select="$net_class"/>
          </xsl:attribute>
          <xsl:value-of select="./cname[@net=$net]"/>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <!-- y -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
