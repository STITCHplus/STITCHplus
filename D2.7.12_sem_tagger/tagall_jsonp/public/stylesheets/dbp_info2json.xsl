<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dbpprop="http://dbpedia.org/property/" xmlns:dbpedia-owl="http://dbpedia.org/ontology/" xmlns:foaf="http://xmlns.com/foaf/0.1/" version="1.0">
<xsl:output method="text" omit-xml-declaration="yes"/>
<xsl:template match="/rdf:RDF">
{
	"label": {<xsl:call-template name="lang">
			<xsl:with-param name="labels" select="//rdfs:label" />
		</xsl:call-template>
		"": ""
	},
	"properties": {
		<xsl:apply-templates select="//dbpprop:*" />
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

<xsl:template match="//dbpprop:*">
	<xsl:if test=". != ''">
		"<xsl:value-of select="local-name(.)" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		,
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
