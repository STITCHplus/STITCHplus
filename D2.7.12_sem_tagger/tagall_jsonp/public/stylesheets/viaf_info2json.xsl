<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:viaf="http://viaf.org/ontology/1.1/#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:skosxl="http://www.w3.org/2008/05/skos-xl#" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:rdaGr2="http://RDVocab.info/ElementsGr2/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:rdaEnt="http://RDVocab.info/uri/schema/FRBRentitiesRDA/" xml:base="http://viaf.org/" version="1.0"> 
<xsl:output method="xml" omit-xml-declaration="yes"/>

<xsl:template match="/rdf:RDF">
{
	"label": {<xsl:call-template name="lang">
			<xsl:with-param name="labels" select="//foaf:name[1]" />
		</xsl:call-template>
	},
	"properties": {
		<xsl:apply-templates select="//rdaGr2:*" />
	}
}

</xsl:template>

<xsl:template name="lang">
	<xsl:param name="labels" />
	<xsl:for-each select="$labels">
		<xsl:if test=". != ''">
			"en": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		</xsl:if>
		<xsl:if test="position() &lt; count($labels)">,</xsl:if>
	</xsl:for-each>
	
</xsl:template>

<xsl:template match="//rdaGr2:*">
	<xsl:if test=". != ''">
		"<xsl:value-of select="local-name(.)" />": "<xsl:value-of select='translate(.,&#x27;"&#x27;,"&#x27;")' />"
		<xsl:if test="position() &lt; count(//rdaGr2:*)">,</xsl:if>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
