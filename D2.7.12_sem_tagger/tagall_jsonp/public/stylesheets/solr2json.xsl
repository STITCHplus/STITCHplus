<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/response">
{
	"numFound": <xsl:value-of select="//result/@numFound" />,
	"nResults": <xsl:value-of select="count(//doc)" />,
	"docs": [
		<xsl:apply-templates select="//doc" /> 
	]
}

</xsl:template>

	<xsl:template match="//doc">
		{
			"label": "<xsl:value-of select="arr[@name='label']/str" />",
			"uri": "<xsl:value-of select="str[@name='id']" />"
		}<xsl:if test="position() &lt; count(//doc)">,</xsl:if>

	</xsl:template>
</xsl:stylesheet>
