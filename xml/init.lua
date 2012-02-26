--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2012 Brian Schott
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

local M = {}

_M.common.xml = require "common.xml"

if type(_G.snippets) == "table" then
---
-- Container for xml-specific snippets.
-- @class table
-- @name snippets.xml
  _G.snippets.xml = {}
end

if type(_G.keys) == "table" then
---
-- Container for xml-specific key commands.
-- @class table
-- @name keys.xml
  _G.keys.xml = {}
end

function M.set_buffer_properties()
	buffer.indent = 2
end

_G.keys.xml = {
	[keys.LANGUAGE_MODULE_PREFIX] = {
		m = {io.open_file, (_USERHOME.."/modules/xml/init.lua"):iconv("UTF-8", _CHARSET)}
	},
	['cs\n'] = {_M.common.xml.completeClosingTag},
	['<'] = {_M.common.xml.autoTag},
	['/'] = {_M.common.xml.singleTag},
	['!'] = {_M.common.xml.completeComment},
	['?'] = {_M.common.xml.completePHP},
	[' '] = {_M.common.xml.handleSpace},
	['\b'] = {_M.common.xml.handleBackspace},
	['c/'] = {_M.common.xml.toggleLineComment},
	cR = {_M.common.xml.reformat},
	ce = {_M.common.xml.encloseTag},
	cM = {_M.common.xml.selectToMatching}
}

_G.snippets.xml = {
	xml = [[<?xml version="1.0" encoding="%1(UTF-8)"?>]],
	xsfe = [[<xsl:for-each select="%1">
	%0
</xsl:for-each>]],
	xsch= [[<xsl:choose>
	%0
</xsl:choose>]],
	xswh = [[<xsl:when test="%1">
	%0
</xsl:when>]],
	xsoth = [[<xsl:otherwise>
	%0
</xsl:otherwise>]],
	xsct = [[<xsl:call-template name="%0">
	%0
</xsl:call-template>]],
	xswp = [[<xsl:with-param name="%1" select="%0"/>]],
	xsvo = [[<xsl:value-of select="%0"/>]],
	xsif = [[<xsl:if test="%1">
	%0
</xsl:if>]],
}

return M
