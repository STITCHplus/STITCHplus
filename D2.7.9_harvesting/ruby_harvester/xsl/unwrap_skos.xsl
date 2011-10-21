<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:didl="urn:mpeg:mpeg21:2002:02-DIDL-NS" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" version="1.0">

  <xsl:template match="/">
		<xsl:element name="rdf:RDF">
			<xsl:apply-templates select="//rdf:RDF" />
		</xsl:element>
  </xsl:template>

	<xsl:template match="rdf:RDF/*">
		<xsl:copy-of select="." />
	</xsl:template>

</xsl:stylesheet>
                        
