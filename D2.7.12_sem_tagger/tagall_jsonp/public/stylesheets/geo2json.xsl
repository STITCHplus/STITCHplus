<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cc="http://creativecommons.org/ns#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:wgs84_pos="http://www.w3.org/2003/01/geo/wgs84_pos#" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="//rdf:RDF">
{
	"numFound": <xsl:value-of select="count(//gn:Feature)" />,
	"nResults": <xsl:value-of select="count(//gn:Feature)" />,
	"docs": [
		<xsl:apply-templates select="//gn:Feature" />
	]
}

</xsl:template>


	<xsl:template match="//gn:Feature">
		{
			"label": "<xsl:value-of select="gn:name" />",
			"uri": "<xsl:value-of select="@rdf:about" />"
		}<xsl:if test="position() &lt; count(//gn:Feature)">,</xsl:if>

	</xsl:template>

</xsl:stylesheet>
