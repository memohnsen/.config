; extends
;
; Mute the text of completed checkbox items (e.g. "- [X] done"), like Doom's
; greyed-out done items. Targets the paragraph text of a listitem whose
; checkbox status is x/X. Highlight group set in lua/custom/plugins/orgmode.lua.

(listitem
  (checkbox status: (expr) @_status (#any-of? @_status "x" "X"))
  (paragraph) @org.checkbox.done)

; Give the text inside #+begin_... / #+end_... blocks the same subtle
; background as the block delimiters.
(block
  contents: (contents) @org.block.background)

(block
  name: (expr) @_name
  contents: (contents) @org.quote
  (#any-of? @_name "quote" "QUOTE"))

(block
  name: (expr) @_name
  contents: (contents) @org.block.code
  (#any-of? @_name "src" "SRC" "example" "EXAMPLE" "export" "EXPORT" "comment" "COMMENT"))
