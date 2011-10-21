<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:didl="urn:mpeg:mpeg21:2002:02-DIDL-NS" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" version="1.0">

  <xsl:template match="/">
		<OAI-PMH>
			<xsl:apply-templates select="//oai:error" />
			<xsl:apply-templates select="//oai:ListRecords" />
		</OAI-PMH>
  </xsl:template>

	<xsl:template match="oai:error">
		<xsl:element name="error">
			<xsl:attribute name="code"><xsl:value-of select="@code" /></xsl:attribute>
			<xsl:value-of select="." />
		</xsl:element>
	</xsl:template>


	<xsl:template match="oai:ListRecords">
		<ListRecords>
			<xsl:apply-templates select="oai:resumptionToken" />
		</ListRecords>
	</xsl:template>

	<xsl:template match="oai:resumptionToken">
		<resumptionToken>
			<xsl:value-of select="." />
		</resumptionToken>
	</xsl:template>
</xsl:stylesheet>
                        
