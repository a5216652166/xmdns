<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>
<!-- The idea here is that we ensure domains are registered correctly.
     If a domain is slightly mis-typed then this will catch it:
     (pir1net.lpl.arizona.edu != pirlnet.lpl.arizona.edu)
     Also, when adding domains, this helps to give an admin who does not read
     documentation a starting place to add the domain. -->

  <!-- print out domainname AND hostname for each entry, since an entry for the
       domain itself is needed -->
  <xsl:template match="host">
    <!-- for duplicate entries, force the existance of the known-duplicate parameter -->
    <xsl:value-of select="domainname" />
    <xsl:text> </xsl:text>
    <xsl:value-of select="hostname" />
    <xsl:text>
</xsl:text>
  </xsl:template>

</xsl:stylesheet>
