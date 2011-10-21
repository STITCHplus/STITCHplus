<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cc="http://creativecommons.org/ns#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:wgs84_pos="http://www.w3.org/2003/01/geo/wgs84_pos#" version="1.0">
<xsl:output method="text" omit-xml-declaration="yes"/>
<xsl:template match="/rdf:RDF">
{
	"label": {<xsl:call-template name="lang">
			<xsl:with-param name="labels" select="gn:Feature/gn:alternateName" />
		</xsl:call-template>
		"": ""
	},
	"properties": {
		<xsl:apply-templates select="gn:Feature/gn:*" />
		<xsl:apply-templates select="gn:Feature/wgs84_pos:*" />
		"": ""
	}
}

</xsl:template>

<xsl:template name="lang">
	<xsl:param name="labels" />
	<xsl:for-each select="$labels">
		<xsl:if test=". != ''">
			"<xsl:value-of select="@xml:lang" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		</xsl:if>
		,
	</xsl:for-each>
	
</xsl:template>

<xsl:template match="//gn:*">
	<xsl:if test=". != ''">
		"<xsl:value-of select="local-name(.)" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		,
	</xsl:if>
</xsl:template>

<xsl:template match="//wgs84_pos:*">
	<xsl:if test=". != ''">
		"<xsl:value-of select="local-name(.)" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		,
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
