-- Copyright 2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

-- This script uses Lua to generate tags and apidoc for the Textadept PHP
-- module. To regenerate, download the PHP documentation in "Many HTML files"
-- format and place this script in the unzipped directory. Modify the filter
-- as necessary and then run 'lua gen_adeptsense.lua'.

-- Filter the API?
local FILTER = true
-- If so, reject filenames that start with these prefixes.
local filter = {
  aggregate = false,
  aggregation = false,
  apache = false,
  apc = false,
  apd = false,
  array = false,
  assert = false,
  base64 = false,
  base = false,
  bbcode = false,
  bcompiler = false,
  bind = false,
  bson = false,
  cairo = false,
  calcul = false,
  cal = false,
  call = false,
  chdb = false,
  chunk = false,
  class = false,
  classkit = false,
  com = false,
  connection = false,
  convert = false,
  count = false,
  crack = false,
  create = false,
  ctype = false,
  cubrid = false,
  curl = false,
  cyrus = false,
  date = false,
  db2 = false,
  dba = false,
  dbase = false,
  dbplus = false,
  dbx = false,
  debug = false,
  define = false,
  dio = false,
  disk = false,
  dns = false,
  domattribute = false,
  domdocument = false,
  domdocumenttype = false,
  domelement = false,
  dom = false,
  domnode = false,
  domprocessinginstruction = false,
  domxml = false,
  domxsltstylesheet = false,
  dotnet = false,
  easter = false,
  enchant = false,
  ereg = false,
  eregi = false,
  error = false,
  event = false,
  exif = false,
  expect = false,
  extension = false,
  ezmlm = false,
  fam = false,
  fbsql = false,
  fdf = false,
  file = false,
  filepro = false,
  filter = false,
  finfo = false,
  forward = false,
  fribidi = false,
  ftp = false,
  func = false,
  ['function'] = false,
  gc = false,
  gd = false,
  geoip = false,
  get = false,
  gmp = false,
  gnupg = false,
  gopher = false,
  grapheme = false,
  gupnp = false,
  halt = false,
  haruannotation = false,
  harudestination = false,
  harudoc = false,
  haruencoder = false,
  harufont = false,
  haruimage = false,
  haruoutline = false,
  harupage = false,
  hash = false,
  header = false,
  headers = false,
  highlight = false,
  html = false,
  htmlspecialchars = false,
  httpdeflatestream = false,
  http = false,
  httpinflatestream = false,
  httpmessage = false,
  httpquerystring = false,
  httprequest = false,
  httprequestpool = false,
  httpresponse = false,
  hwapi = false,
  hw = false,
  ibase = false,
  iconv = false,
  id3 = false,
  idn = false,
  ifx = false,
  ifxus = false,
  ignore = false,
  iis = false,
  image = false,
  imagickdraw = false,
  imagick = false,
  imagickpixel = false,
  imagickpixeliterator = false,
  imap = false,
  import = false,
  include = false,
  inclued = false,
  inet = false,
  ['in'] = false,
  ingres = false,
  ini = false,
  inotify = false,
  interface = false,
  intl = false,
  is = false,
  iterator = false,
  java = false,
  json = false,
  judy = false,
  kadm5 = false,
  lcg = false,
  ldap = false,
  libxml = false,
  lzf = false,
  magic = false,
  mailparse = false,
  maxdb = false,
  mb = false,
  mcrypt = false,
  md5 = false,
  mdecrypt = false,
  memcache = false,
  memory = false,
  method = false,
  m = false,
  mhash = false,
  mime = false,
  ming = false,
  money = false,
  move = false,
  mqseries = false,
  msession = false,
  msg = false,
  msql = false,
  mssql = false,
  mt = false,
  mysql = false,
  mysqli = false,
  ncurses = false,
  newt = false,
  nl = false,
  notes = false,
  nsapi = false,
  number = false,
  oauth = false,
  ob = false,
  oci = false,
  odbc = false,
  openal = false,
  openssl = false,
  output = false,
  override = false,
  ovrimos = false,
  parse = false,
  parsekit = false,
  pcntl = false,
  pdf = false,
  pdo = false,
  pg = false,
  php = false,
  posix = false,
  preg = false,
  printer = false,
  print = false,
  proc = false,
  property = false,
  ps = false,
  pspell = false,
  px = false,
  qdom = false,
  quoted = false,
  radius = false,
  rar = false,
  read = false,
  readline = false,
  recode = false,
  register = false,
  rename = false,
  require = false,
  restore = false,
  rpm = false,
  rrd = false,
  runkit = false,
  samconnection = false,
  sammessage = false,
  sca = false,
  sdo = false,
  sem = false,
  session = false,
  set = false,
  sha1 = false,
  shell = false,
  shm = false,
  shmop = false,
  show = false,
  similar = false,
  simplexml = false,
  snmp2 = false,
  snmp3 = false,
  snmp = false,
  socket = false,
  solr = false,
  spl = false,
  sql = false,
  sqlite = false,
  ssdeep = false,
  ssh2 = false,
  stats = false,
  stomp = false,
  stream = false,
  str = false,
  strip = false,
  substr = false,
  svn = false,
  swf = false,
  swish = false,
  swishresult = false,
  swishresults = false,
  swishsearch = false,
  sybase = false,
  sys = false,
  tcpwrap = false,
  tidy = false,
  time = false,
  timezone = false,
  token = false,
  trigger = false,
  udm = false,
  unregister = false,
  use = false,
  user = false,
  utf8 = false,
  var = false,
  variant = false,
  version = false,
  vpopmail = false,
  w32api = false,
  wddx = false,
  win32 = false,
  wincache = false,
  xattr = false,
  xdiff = false,
  xml = false,
  xmlrpc = false,
  xmlwriter = false,
  xpath = false,
  xptr = false,
  xslt = false,
  yaml = false,
  yaz = false,
  yp = false,
  zend = false,
  ziparchive = false,
  zip = false,
  zlib = false,
}

-- Formats a chunk of HTML into plain text.
local function prepare(s)
  if not s then return nil end
  return s:match('^%s*(.-)%s*$'): -- trim
           gsub('<i>(.-)</i>', '`%1`'): -- use `` for variable names
           gsub('<[^>]+>', ''): -- strip HTML
           gsub('&(%a+);', { gt = '>' }): -- substitute HTML entities
           gsub('\r?\n', ' '): -- replace newlines
           gsub(' +', ' ') -- squeeze multiple spaces
end

-- Match strings.
local FUNC = '<h1[^>]*>(.-)</h1>'
local LINK = '<a[^>]*>(.-)</a>'
local SHORT_DESC = '<title>(.-)</title>'
local LONG_DESC = '(<p class="[^"]-rdfs%-comment"[^>]*>.-)</div>'
local PARA = '<p[^>]*>(.-)</p>'
local SIGNATURE = '<div class="[^"]-dc%-description">(.-)</div>'
local TS = '([%(%[=]) '
local LS = ' ([,%(%)%]=])'
local PARAMETERS = '<div class="[^"]-parameters"[^>]*>(.-)</div>'
local PARAM = '<dt[^>]*>(.-)</dt>'
local BACKTICK = '^`([^`]+)`'
local RET = '<div class="[^"]-returnvalues"[^>]*>(.-)</div>'
local RET2 = '<p[^>]*>(.-)</p>'
local FNOTES = '<div class="[^"]-notes"[^>]*>(.-)</div>'
local NOTE = '<blockquote[^>]*>(.-)</blockquote>'
local SEEALSO = '<div class="[^"]-seealso"[^>]*>(.-)</div>'
local SEEALSO_FUNC = '<li[^>]*>(.-)</li>'
local IDENTIFIER = '([%w_]+)$'
local CTAG_CONSTANT = '<tt>([^<]+)</tt>'
local CTAG_FUNC = '<li><a[^>]*>([^<]+)</a>'
local SYMBOL = '^([%w_]+)[^%w_]+([%w_]+)'
local TAG = '%s\t_\t0;"\t%s\t%s\n'

local lfs = require 'lfs'

local api = io.open('api', 'wb')
local ctags = io.open('tags', 'wb')
for file in lfs.dir('.') do
  local func = file:match('^function%.([%w-]+)%.html$') or
               file:match('^ref%.([%w-]+)%.html$') or
               file:match('^([%w-]+)%.constants%.html$')
  if func and (not FILTER or not filter[func:match('^%w+')]) then
    local f = io.open(file)
    local text = f:read('*all')
    f:close()

    if file:find('^function') then
      -- Generate apidoc for this function.

      -- Function name.
      func = text:match(FUNC)
      if func then
        print('Processing', file)
        text = text:gsub(LINK, '%1') -- strip links

        -- Function description.
        local desc = {}
        local short_desc = text:match(SHORT_DESC)
        desc[#desc + 1] = short_desc..'.'
        local long_desc = text:match(LONG_DESC)
        if long_desc then
          for para in long_desc:gmatch(PARA) do
            desc[#desc + 1] = prepare(para)
          end
        end

        -- Function signature.
        local signature = prepare(text:match(SIGNATURE))
        local ffunc = func:gsub('%-', '%%-')
        if signature and signature:find(ffunc) then
          signature = signature:gsub(TS, '%1'): -- strip trailing space
                                gsub(LS, '%1'): -- strip leading space
                                match(ffunc..'.+$')..
                                  ' ['..signature:match('^(.-)%s*'..ffunc)..']'
        end

        -- Function parameters.
        local params = {}
        local parameters = text:match(PARAMETERS)
        if parameters then
          for param in parameters:gmatch(PARAM) do
            params[#params + 1] = prepare(param):gsub(BACKTICK, '%1')
          end
        end

        -- Function return value.
        local ret = text:match(RET)
        if ret then ret = prepare(text:match(RET2)) end

        -- Function notes.
        local notes = {}
        local fnotes = text:match(FNOTES)
        if fnotes then
          for note in fnotes:gmatch(NOTE) do
            notes[#notes + 1] = prepare(note)
          end
        end

        -- Function seealso.
        local see = {}
        local seealso = text:match(SEEALSO)
        if seealso then
          for func in seealso:gmatch(SEEALSO_FUNC) do
            see[#see + 1] = prepare(func)
          end
        end

        -- Create, format, and write the apidoc.
        local apidoc = { 'fmt -w 80 -s <<\'EOF\'' }
        apidoc[2] = func:match(IDENTIFIER)..' '..(signature or func)
        apidoc[3] = table.concat(desc, ' ')
        for _, v in ipairs(params) do apidoc[#apidoc + 1] = '@param '..v end
        if ret then apidoc[#apidoc + 1] = '@return '..ret end
        for _, v in ipairs(notes) do apidoc[#apidoc + 1] = '@note '..v end
        for _, v in ipairs(see) do apidoc[#apidoc + 1] = '@see '..v end
        apidoc[#apidoc + 1] = 'EOF\n'
--        print(table.concat(apidoc, '\n'))
        local p = io.popen(table.concat(apidoc, '\n'))
        text = p:read('*all'):gsub('\r?\n', '\\n')
        api:write(text)
        api:write('\n')
      end
    else
      -- Generate ctags.
      print('Processing', file)
      text = text:gsub('&gt;', '>') -- replace HTML entity

      local classes = {}

      -- Write constants.
      for constant in text:gmatch(CTAG_CONSTANT) do
        local ext_fields, class = '', nil
        if constant:find('%->') or constant:find('::') then
          class, constant = constant:match(SYMBOL)
          ext_fields = 'class:'..class
          classes[class] = true
        end
        ctags:write(TAG:format(constant, 'd', ext_fields))
      end

      -- Write functions.
      for func in text:gmatch(CTAG_FUNC) do
        local ext_fields, class = '', nil
        if func:find('%->') or func:find('::') then
          class, func = func:match(SYMBOL)
          ext_fields = 'class:'..class
          classes[class] = true
        end
        ctags:write(TAG:format(func, 'f', ext_fields))
      end

      -- Write classes.
      for class in pairs(classes) do ctags:write(TAG:format(class, 'c', '')) end
    end
  end
end
api:close()
ctags:close()
