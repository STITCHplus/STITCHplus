<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:srw="http://www.loc.gov/zing/srw/" 
xmlns:tel="http://krait.kb.nl/coop/tel/handbook/telterms.html" 
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/" 
xmlns:dcx="http://krait.kb.nl/coop/tel/handbook/telterms.html" 
xmlns:dc="http://purl.org/dc/elements/1.1/" 
xmlns:dcterms="http://purl.org/dc/terms/" 
xmlns:solr="http://solr/" 
xmlns:srw_dc="info:srw/schema/1/dc-v1.1" 
xmlns:mods="http://www.loc.gov/mods" 
xmlns:marcrel="http://www.loc.gov/marc.relators/" 
xmlns:expand="http://www.kbresearch.nl/expand" 
xmlns:skos="http://www.w3.org/2004/02/skos/core#" 
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
version="1.0">

<xsl:output method="text" omit-xml-declaration="yes"/>
<xsl:template match="/srw:searchRetrieveResponse">
{
	"label": {<xsl:call-template name="lang">
			<xsl:with-param name="labels" select="//srw_dc:expand/rdf:RDF/skos:Concept/skos:prefLabel" />
		</xsl:call-template>
	}
	"properties": {
		<xsl:apply-templates select="//srw_dc:dc/skos:Concept/*" />
	}
}

</xsl:template>

<xsl:template name="lang">
	<xsl:param name="labels" />
	<xsl:for-each select="$labels">
		<xsl:if test=". != ''">
			"<xsl:value-of select="@xml:lang" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		</xsl:if>
		<xsl:if test="position() &lt; count($labels)">,</xsl:if>
	</xsl:for-each>
	
</xsl:template>
<xsl:template match="//srw_dc:dc/skos:Concept/*">
	<xsl:if test=". != ''">
		"<xsl:value-of select="local-name(.)" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		<xsl:if test="position() &lt; count(//srw_dc:dc/skos:Concept/*)">,</xsl:if>
	</xsl:if>
</xsl:template>
</xsl:stylesheet>
