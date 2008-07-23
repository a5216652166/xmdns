<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="host_list"/>
  <xsl:template match="host_list">
    <xsl:apply-templates>
      <xsl:sort select="hostname"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="host">
      <xsl:text>dn: cn=</xsl:text>
      <xsl:value-of select="hostname" />
      <xsl:text>,ou=DNS,dc=lpl,dc=arizona,dc=edu
objectClass: top
objectClass: a-iphost
</xsl:text>



      <xsl:for-each select="./action">
        <xsl:text>action: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-globalnet">
        <xsl:text>a-globalnet: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-dmz">
        <xsl:text>a-hinet-dmz: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-internal">
        <xsl:text>a-hinet-internal: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-hinet-san">
        <xsl:text>a-hinet-san: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-dmz">
        <xsl:text>a-pirlnet-dmz: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-internal">
        <xsl:text>a-pirlnet-internal: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-pirlnet-san">
        <xsl:text>a-pirlnet-san: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-printernet">
        <xsl:text>a-printernet: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./a-securenet">
        <xsl:text>a-securenet: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./cname-globalnet">
        <xsl:text>cname-globalnet: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./cname-hinet-dmz">
        <xsl:text>cname-hinet-dmz: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./cname-pirlnet-internal">
        <xsl:text>cname-pirlnet-internal: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./description">
        <xsl:text>description: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="./macAddress">
        <xsl:text>macAddress: </xsl:text>
        <xsl:value-of select="." />
	<xsl:text>
</xsl:text>
      </xsl:for-each>



      <xsl:text>
</xsl:text>


  </xsl:template>
</xsl:stylesheet>
