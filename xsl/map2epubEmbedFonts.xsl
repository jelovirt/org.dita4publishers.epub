<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:epubtrans="urn:d4p:epubtranstype"
  xmlns:gmap="http://dita4publishers/namespaces/graphic-input-to-output-map"
  exclude-result-prefixes="xs df relpath epubtrans"
  version="2.0">
  
  <!-- =========================================
       Manages embedding of fonts in the 
       generated EPUB.
       
       The embedding is done by adding entries
       to the graphic map so the font files
       are included in the EPUB. 
       
       The fonts to be embedded are defined in 
       an XML font manifest file, the location
       of which is specified as a runtime parameter.
       
       ========================================= -->
  
 
  <xsl:template match="*" mode="additional-graphic-refs" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
<!--    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] additional-graphic-refs: embed fonts override: <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>

    <!-- If there is a font manifest specified, process it to add 
         references to each font to the set of graphic references.
      -->
    <xsl:if test="$epubFontManifestUri != ''">
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] additional-graphic-refs: $epubFontManifestUri="<xsl:value-of select="$epubFontManifestUri"/>"</xsl:message>
      </xsl:if>

      <xsl:message> + [INFO] Font manifest specified as "<xsl:value-of select="$epubFontManifestUri"/>"</xsl:message>
      <xsl:message> + [INFO] Processing font manifest...</xsl:message>
      <xsl:variable name="fontManifest" as="document-node()?" 
        select="epubtrans:getFontManifestDoc($epubFontManifestUri)"/>
      <xsl:choose>
        <xsl:when test="not($fontManifest)">
          <xsl:message> - [WARN] Font manifest file "<xsl:value-of select="$epubFontManifestUri"/>" not parsed. Fonts will not be embedded.</xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$doDebug">
            <xsl:message> + [DEBUG] additional-graphic-refs: Applying templates to font manifest in mode epubtrans:font-graphic-refs...</xsl:message>
          </xsl:if>
          
          <xsl:apply-templates select="$fontManifest/*" mode="epubtrans:font-graphic-refs">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>              
          </xsl:apply-templates>
          <xsl:if test="$doDebug">
            <xsl:message> + [DEBUG] additional-graphic-refs: Font manifest processing done.</xsl:message>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:message> + [INFO] Font manifest processing complete.</xsl:message>
    </xsl:if>
    <xsl:next-match/><!-- Enable additional extensions -->
  </xsl:template>
  
  <xsl:template mode="epubtrans:font-graphic-refs" match="font-manifest">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] epubtrans:font-graphic-refs: Element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>
    
    <xsl:apply-templates mode="#current" select="font-set">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template mode="epubtrans:font-graphic-refs" match="font-set">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] epubtrans:font-graphic-refs: Element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>
    

    <xsl:apply-templates mode="#current" select="font">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  
  <xsl:template mode="epubtrans:font-graphic-refs" match="font">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] epubtrans:font-graphic-refs: Element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>

    <xsl:variable name="baseURI" as="xs:string" select="relpath:getParent(string(base-uri(.)))"/>
    <xsl:variable name="uri" as="xs:string" select="@uri"/>
    <xsl:variable name="fontURI" as="xs:string"
      select="if (matches($uri, '^\w+:.+'))
          then $uri
          else relpath:newFile($baseURI, $uri)
      "
    />
    <xsl:message> + [INFO] Font embedding: Including font "<xsl:value-of select="$fontURI"/>"</xsl:message>
    <gmap:graphic-ref href="{$fontURI}" filename="{relpath:getName($fontURI)}">
      <xsl:sequence select="(@obfuscate, ../@obfuscate)[1]"/>
    </gmap:graphic-ref>
  </xsl:template>
  
  <xsl:template mode="epubtrans:font-graphic-refs" match="* | text()" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] epubtrans:font-graphic-refs: Element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>
    
    <!-- Ignore by default -->
  </xsl:template>
  
  <!-- ============================================
       Set the MIME types for fonts appropriately
       ============================================ -->
  
  <xsl:template mode="getMimeType" match="gmap:filename[@extension = ('ttf', 'otf', 'ttc')]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="font-type" as="xs:string"
      select="if (@extension = ('ttf', 'otf', 'ttc', 'cff')) then 'sfnt'
              else @extension
      "
    />
    <xsl:sequence select="concat('application/font-', $font-type)"/>
  </xsl:template>
  
  <xsl:template mode="getMimeType" match="gmap:filename[@extension = ('css')]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:sequence select="'text/css'"/>
  </xsl:template>
  
  <xsl:template mode="getMimeType" match="gmap:filename[@extension = ('js')]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:sequence select="'text/javascript'"/>
  </xsl:template>
  

  <!-- Handle font files specially: Put in font directory -->
  <xsl:template mode="gmap:get-output-url" match="gmap:graphic-ref" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        
    <xsl:variable name="absoluteUrl" as="xs:string" select="@href"/>
    <xsl:variable name="filename" as="xs:string" select="@filename"/>
    <xsl:variable name="namePart" as="xs:string" select="relpath:getNamePart($filename)"/>
    <xsl:variable name="extension" as="xs:string" select="relpath:getExtension($filename)"/>
    <xsl:variable name="key"
      select="
      if (count(preceding-sibling::*[@filename = $filename]) > 0)
      then concat($namePart, '-', count(preceding-sibling::*[@filename = $filename]) + 1, '.', $extension)
      else $filename
      "/>
    <xsl:choose>
      <xsl:when test="$extension = ('ttf', 'ttc', 'otf', 'otc', 'cff', 'woff')">
        <xsl:sequence select="relpath:newFile($fontsOutputPath, $key)"/>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Gets the font manifest file, if a URI has been specified, otherwise
       returns an empty sequence.
    -->
  <xsl:function name="epubtrans:getFontManifestDoc" as="document-node()?">
    <xsl:param name="epubFontManifestURI" as="xs:string"/>
    
    <xsl:variable name="result" as="document-node()?" 
      select="if ($epubFontManifestUri != '') 
                 then document($epubFontManifestUri)
                 else ()"
    />
    <xsl:if test="$epubFontManifestUri != '' and not($result)">
      <xsl:message> - [WARN] epubtrans:getFontManifestDoc(): Failed to find font manifest at URI "<xsl:value-of select="$epubFontManifestUri"/>".</xsl:message>
    </xsl:if>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
</xsl:stylesheet>