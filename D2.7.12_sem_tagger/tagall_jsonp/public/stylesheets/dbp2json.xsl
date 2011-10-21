<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dbplu="http://lookup.dbpedia.org/" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/dbplu:ArrayOfResult">
{
	"numFound": <xsl:value-of select="count(/dbplu:ArrayOfResult/dbplu:Result)" />,
	"nResults": <xsl:value-of select="count(/dbplu:ArrayOfResult/dbplu:Result)" />,
	"docs": [
		<xsl:apply-templates select="//dbplu:Result" />
	]
}

</xsl:template>


	<xsl:template match="//dbplu:Result">
		{
			"label": "<xsl:value-of select="dbplu:Label" />",
			"uri": "<xsl:value-of select="dbplu:URI" />"
		}<xsl:if test="position() &lt; count(//dbplu:Result)">,</xsl:if>

	</xsl:template>

</xsl:stylesheet>
