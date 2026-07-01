local ok, ls = pcall(require, 'luasnip')
if not ok then return end

local s = ls.snippet
local i = ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt

local function tmpl(trig, body, nodes) return s({ trig = trig, wordTrig = false }, fmt(body, nodes)) end

ls.add_snippets('org', {
  tmpl('<s', '#+begin_src {}\n{}\n#+end_src', { i(1, 'lang'), i(0) }),
  tmpl('<e', '#+begin_example\n{}\n#+end_example', { i(0) }),
  tmpl('<q', '#+begin_quote\n{}\n#+end_quote', { i(0) }),
  tmpl('<v', '#+begin_verse\n{}\n#+end_verse', { i(0) }),
  tmpl('<c', '#+begin_center\n{}\n#+end_center', { i(0) }),
  tmpl('<C', '#+begin_comment\n{}\n#+end_comment', { i(0) }),
  tmpl('<l', '#+begin_export latex\n{}\n#+end_export', { i(0) }),
  tmpl('<h', '#+begin_export html\n{}\n#+end_export', { i(0) }),
  tmpl('<a', '#+begin_export ascii\n{}\n#+end_export', { i(0) }),
}, { type = 'snippets', key = 'org_tempo' })
