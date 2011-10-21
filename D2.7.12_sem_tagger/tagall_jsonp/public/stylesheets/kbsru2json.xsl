<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:srw="http://www.loc.gov/zing/srw/" xmlns:tel="http://krait.kb.nl/coop/tel/handbook/telterms.html" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/" xmlns:dcx="http://krait.kb.nl/coop/tel/handbook/telterms.html" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:expand="http://kbresearch.nl/exapnd" xmlns:solr="http://solr/" version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/srw:searchRetrieveResponse">
{
	"numFound": <xsl:value-of select="//srw:numberOfRecords" />,
	"nResults": <xsl:value-of select="count(//srw:record)" />,
	"docs": [
		<xsl:apply-templates select="//srw:record/srw:recordData" />
	]
}

</xsl:template>

	<xsl:template match="//srw:record/srw:recordData">
		{
			"label": "<xsl:value-of select="prefLabel" />",
			"uri": "<xsl:value-of select="Concept" />"
		}<xsl:if test="position() &lt; count(//srw:record)">,</xsl:if>

	</xsl:template>
</xsl:stylesheet>
