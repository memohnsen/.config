; extends
;
; Mute the text of completed checkbox items (e.g. "- [X] done"), like Doom's
; greyed-out done items. Targets the paragraph text of a listitem whose
; checkbox status is x/X. Highlight group set in lua/custom/plugins/orgmode.lua.

(listitem
  (checkbox status: (expr) @_status (#any-of? @_status "x" "X"))
  (paragraph) @org.checkbox.done)
