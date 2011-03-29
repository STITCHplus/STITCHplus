<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:didl="urn:mpeg:mpeg21:2002:02-DIDL-NS" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" version="1.0" xmlns:skos="http://www.w3.org/2004/02/skos/core#">

  <xsl:template match="/">
		<xsl:element name="rdf:RDF">
			<xsl:apply-templates select="//oai:record" />
		</xsl:element>
  </xsl:template>

	<xsl:template match="oai:record">
		<xsl:choose>
			<xsl:when test="oai:header/oai:status = 'deleted'">
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="./oai:metadata/rdf:RDF/*" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
                        
