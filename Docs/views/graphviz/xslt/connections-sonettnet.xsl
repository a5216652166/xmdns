<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="host_list"/>

  <xsl:template match="host_list">
    <!-- insert templated matches from definitiions below -->
    
    <xsl:text>digraph connections {
  graph [ sep=0.2, bgcolor = "black" ];
  sonettnet [ color = "blue", fontcolor = "blue" ];
  hinet_dmz [ color = "yellow", fontcolor = "yellow" ];
  hinet_int [ color = "orange", fontcolor = "orange" ];
  pirlnet_dmz [ color = "blue", fontcolor = "blue" ];
  pirlnet_int [ color = "purple", fontcolor = "purple" ];
  securenet [ color = "red", fontcolor = "red" ];
  printernet [ color = "grey", fontcolor = "grey" ];
  hinet_san [ color = "lightgrey", fontcolor = "lightgrey" ];
</xsl:text>

    <xsl:apply-templates>
      <!-- sort by shortname -->
      <xsl:sort select="shortname"/>
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template name="usable_shortname">
    <xsl:param name="shortname"/>
    <xsl:value-of select="substring-before($shortname,'-')"/>
    <xsl:choose>
      <xsl:when test="contains($shortname,'-')">
	<xsl:text>_</xsl:text>
	<xsl:call-template name="usable_shortname">
	  <xsl:with-param name="shortname" select="substring-after($shortname,'-')"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$shortname"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
	Match all wanted hosts
  -->
  <xsl:template match="host">
    <xsl:if test="a-sonettnet">

    <!--
	Change all - to _ in shortname
    -->
    <xsl:variable name="nice_shortname">
      <xsl:call-template name="usable_shortname">
        <xsl:with-param name="shortname" select="shortname"/>
      </xsl:call-template>
    </xsl:variable>

    <!--
	Make a stylized entry for the host
    -->
    <xsl:value-of select="$nice_shortname"/>
    <xsl:text>[ color="#000000ff", fontcolor = "white", labelfontsize = 10 ];
</xsl:text>

	<!--
	  Global Net Connections
	-->
        <xsl:if test="a-sonettnet">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> sonettnet [ color = "blue" ];
</xsl:text>
	</xsl:if>

	<!--
	  HiNet DMZ Connections
	-->
        <xsl:if test="a-hinet-dmz">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> hinet_dmz [ color = "yellow" ];
</xsl:text>
	</xsl:if>

	<!--
	  HiNet Internal Connections
	-->
        <xsl:if test="a-hinet-internal">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> hinet_int [ color = "orange" ];
</xsl:text>
	</xsl:if>

	<!--
	  PIRLNet DMZ Connections
	-->
        <xsl:if test="a-pirlnet-dmz">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> pirlnet_dmz [ color = "blue" ];
</xsl:text>
	</xsl:if>

	<!--
	  PIRLNet Internal Connections
	-->
        <xsl:if test="a-pirlnet-internal">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> pirlnet_int [ color = "purple" ];
</xsl:text>
	</xsl:if>

	<!--
	  Secure Net Connections
	-->
        <xsl:if test="a-securenet">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> securenet [ color = "red" ];
</xsl:text>
	</xsl:if>

	<!--
	  Printer Net Connections
	-->
        <xsl:if test="a-printernet">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> printernet [ color = "grey" ];
</xsl:text>
	</xsl:if>

	<!--
	  Storage Net Connections
	-->
        <xsl:if test="a-hinet-san">
	  <xsl:value-of select="$nice_shortname"/>
	  <xsl:text> -> hinet_san [ color = "lightgrey" ];
</xsl:text>
	</xsl:if>

  </xsl:if>
  </xsl:template>

</xsl:stylesheet>
