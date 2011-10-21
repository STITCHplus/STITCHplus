<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:cluster="http://viaf.org/viaf/terms#" xmlns:xq="http://www.loc.gov/zing/cql/xcql/" xmlns:srw="http://www.loc.gov/zing/srw/" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="//channel">
{
	"numFound": <xsl:value-of select="//opensearch:totalResults" />,
	"nResults": <xsl:value-of select="count(//item)" />,
	"docs": [
		<xsl:apply-templates select="//item" />
	]
}

</xsl:template>


	<xsl:template match="//item">
		{
			"label": "<xsl:value-of select="title" />",
			"uri": "<xsl:value-of select="link" />"
		}<xsl:if test="position() &lt; count(//item)">,</xsl:if>

	</xsl:template>

</xsl:stylesheet>
