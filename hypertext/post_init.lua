local M = {}

_M.common.xml = require "common.xml"
--_M.common.xml = require "xml"
_M.hypertext.zen = require "hypertext.zen"

local function openURL()
	local url
	local sel = buffer:get_sel_text()
	if #sel == 0 then
		url = buffer.filename
	else
		url = sel
	end
	local cmd
	if WIN32 then
		cmd = string.format('start "" "%s"', url)
		local p = io.popen(cmd)
		if not p then error(l.MENU_BROWSER_ERROR..url) end
	else
		cmd = string.format((MAC and 'open "file://%s"' or 'xdg-open "%s" &'), url)
		if os.execute(cmd) ~= 0 then error(l.MENU_BROWSER_ERROR..url) end
	end
end

-- hypertext-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
	keys.hypertext = {
		[keys.LANGUAGE_MODULE_PREFIX] = {
			m = { io.open_file,
			(_HOME..'/modules/hypertext/init.lua'):iconv('UTF-8', _CHARSET) },
		},
--		['cZ'] = {_M.hypertext.zen.process_zen},
		['c\n'] = {_M.hypertext.zen.process_zen},
		['cs\n'] = {_M.common.xml.completeClosingTag},
		['<'] = {_M.common.xml.autoTag},
		['/'] = {_M.common.xml.singleTag},
		['!'] = {_M.common.xml.completeComment},
		['?'] = {_M.common.xml.completePHP},
--		[' '] = {_M.common.xml.handleSpace},
		['\b'] = {_M.common.xml.handleBackspace},
		['c/'] = {_M.common.xml.toggleLineComment},
		ce = {_M.common.xml.encloseTag},
		cu = {openURL},
	}
end

local snippets = _G.snippets

if type(snippets) == 'table' then
	snippets.hypertext = {
		base = [[<base %1(target, href)="%2"/>]],
		baset = [[<base target="%1"/>]],
		baseh = [[<base href="%1"/>]],
		br = [[<br/>]],
		cdata = "<![CDATA[%0]]>",
		col = [[<col align="%1(left, right, center, justify, or char)"/>]],
		frame = [[<frame src="%1"/>]],
		frameset = [[<frameset>
	<frame src="%1"/>
	%0
</frameset>]],
		hr= [[<hr/>]],
		html = [[<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=%1(UTF-8)"/>
	</head>
	<body>
		%0
	</body>
</html>]],
		img = [[<img src="%1" width="%2" height="%3" alt="%4(%1)"/>]],
		input = [[<input type="%1" value="%2"/>]],
		link = [[<link rel="%1(stylesheet)" type="%2(text/css)" href="%3(stylesheet.css)"/>]],
		meta = [[<meta name="%1" content="%2"/>]],
		metah = [[<meta http-equiv="%1" content="%2"/>]],
		optgroup = [[<optgroup label="%1">
	<option value="%2">%0</option>
</optgroup>]],
		param = [[<param name="%1" value="%2"/>]],
		script = [[<script type="%1(text/javascript)">
	%0
</script>]],
		scriptsrc = [[<script type="%1(text/javascript)" src="%0"></script>]],
		select = [[<select>
	<optgroup label="%1">
		<option value="%2">%0</option>
	</optgroup>
</select>]],
		style = [[<style type="%1(text/css)">
	%0
</style>]],
		xhtml = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=%1(UTF-8)"/>
	</head>
	<body>
		%0
	</body>
</html>]],
		lorem = [[<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed elit
enim, sagittis at facilisis vitae, tempus sit amet felis. Cras elementum magna
ac sapien venenatis molestie. Suspendisse sit amet urna sem, vitae rutrum
urna. Mauris rutrum nulla vel magna egestas ornare. Maecenas eget enim est,
vitae molestie ligula. Sed vel fermentum ante. Aenean pharetra nisi nec mi
ultrices porta. Nullam porttitor urna sit amet quam placerat imperdiet. Ut
viverra dictum mauris, sollicitudin elementum magna placerat id. Proin
pharetra, quam in sollicitudin facilisis, mi purus pharetra ipsum, sed gravida
sapien lectus eu metus.</p>
<p>Suspendisse scelerisque erat vitae mauris ultricies tristique quis vel
turpis. Etiam rhoncus iaculis condimentum. Nullam vitae dui vel eros volutpat
tempor ac et massa. Fusce ullamcorper consectetur justo et pellentesque. Morbi
nisi dolor, viverra ut feugiat vel, venenatis nec nisi. Nullam et nulla magna,
sit amet faucibus enim. Aenean in massa quis sem fermentum sodales. Nam diam
orci, pulvinar non tempus sed, ullamcorper in felis. Morbi ac odio justo,
gravida tempor elit. Suspendisse at metus arcu. Pellentesque libero diam,
sodales nec vehicula sit amet, sodales vitae neque. Pellentesque habitant
morbi tristique senectus et netus et malesuada fames ac turpis egestas.</p>
<p>Cras blandit eleifend mi, id condimentum elit vehicula ac. Mauris nisl
quam, laoreet eget condimentum vitae, vulputate nec augue. Aliquam at odio
velit. Aliquam fermentum auctor elementum. Quisque sagittis tortor non velit
imperdiet mollis sit amet vel libero. Pellentesque semper viverra arcu, vitae
consequat lorem ullamcorper non. Duis vitae sagittis massa. Nunc fermentum
consequat dui, vitae rutrum diam fringilla in. Suspendisse potenti. Aenean
iaculis mauris ac tortor convallis rutrum. Morbi convallis scelerisque
feugiat. Sed laoreet vestibulum ante sed ullamcorper. Pellentesque ut quam ac
diam tempus dignissim. Maecenas tincidunt pulvinar magna vel consectetur.
Donec odio mi, vehicula et bibendum sed, pellentesque sed eros.</p>
<p>Vestibulum risus lectus, vestibulum in scelerisque eu, lobortis quis risus.
Aenean congue felis nec arcu ornare dapibus. Morbi sed odio justo, et placerat
orci. Praesent viverra, diam ut congue volutpat, sem libero placerat elit, eu
viverra purus orci at lacus. Nullam vel purus sapien. Class aptent taciti
sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nunc
ullamcorper auctor tortor nec tincidunt. Vivamus nec ipsum leo, vel ornare
nisi. Curabitur odio metus, ultricies eu pellentesque id, tempor eu enim.
Morbi iaculis vestibulum venenatis. Vivamus vitae augue quis nisi semper
fringilla a vulputate diam. Cras a est nisi. Ut iaculis bibendum sem, ut
iaculis odio tincidunt nec. Aliquam eget leo diam. Pellentesque at congue
tortor. Fusce convallis ornare lacus nec lobortis. Nullam non odio vitae nisi
vulputate tristique vel non quam. Mauris feugiat mi dignissim felis laoreet
pharetra. Cras molestie odio at velit rhoncus consequat. Sed suscipit
condimentum dui eu dictum.</p>
<p>Nullam pretium nunc arcu, ac scelerisque nulla. Sed pharetra feugiat
pulvinar. Nulla posuere ligula ipsum. Donec arcu lectus, congue eget
scelerisque eu, egestas a augue. Cras vel nisl enim. Aliquam erat volutpat.
Integer auctor consectetur elit sed dignissim. Duis posuere pulvinar mauris,
id condimentum nulla pharetra vitae. Donec pellentesque mauris ut nisl
facilisis id pellentesque ipsum volutpat. Nulla facilisi. Nunc blandit porta
lectus at luctus. Aenean interdum mi nec dolor aliquet facilisis. Quisque in
dolor elit, vel tempor tortor.</p>]],
	}
end

-- Totally legit method of extending set_buffer_properties
local old_set_buffer_properties = _M.hypertext.set_buffer_properties
function _M.hypertext.set_buffer_properties()
	old_set_buffer_properties()
	buffer.tab_width = 2
	buffer.use_tabs = true
	buffer.indent = 2
end

return M
