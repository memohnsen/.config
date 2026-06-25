; extends
;
; orgmode already ships queries/org/images.scm which handles plain image links
; like [[file:img.png]] / [[./img.png]]. It does NOT handle described links
; ([[./img.png][caption]]), so we only add that case here. Adding the plain
; `link` case again would make snacks render every image twice.
;
; Matches: [[./img.png][description]]  [[file:img.png][description]]

(link_desc
  (expr) @image.src
  (#gsub! @image.src "^file:" "")
  (#match? @image.src "\\v\\c\\.(png|jpe?g|gif|bmp|webp|svg|tiff|heic|avif)$")) @image
