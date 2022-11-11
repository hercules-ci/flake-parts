<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns="http://docbook.org/ns/docbook"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="db:variablelist">
    <chapter>
      <title>
        <xsl:value-of select="$title"/>
      </title>
      <para>Overview:</para>
      <xsl:for-each select="db:varlistentry">
        <para><link xlink:href="#{db:term/@xml:id}"><xsl:copy-of select="db:term/db:option"/></link></para>
      </xsl:for-each>
      <xsl:apply-templates />
    </chapter>
  </xsl:template>
  <xsl:template match="db:varlistentry">
    <section>
      <title>
        <link xlink:href="#{db:term/@xml:id}" xml:id="{db:term/@xml:id}"><xsl:copy-of select="db:term/db:option"/></link>
      </title>
      <xsl:apply-templates select="db:listitem/*"/>
    </section>
  </xsl:template>
  <!-- Pandoc doesn't like block-level simplelist -->
  <!-- https://github.com/jgm/pandoc/issues/8086 -->
  <xsl:template match="db:simplelist">
    <para>
      <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
    </para>
  </xsl:template>
  <!-- Turn filename tags with href attrs into explicit links -->
  <xsl:template match="db:filename">
    <link xlink:href="{@xlink:href}">
      <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
    </link>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>