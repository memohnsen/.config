(setq user-full-name "Maddisen Mohnsen"
      user-mail-address "memohnsen@gmail.com")

(setq doom-font (font-spec :family "JetBrains Mono NL" :size 13))

;; Keep buffer lines compact without changing font size or horizontal spacing.
(setq-default line-spacing 0)

;; Always wrap long lines and never shift a window horizontally as point moves.
(setq-default truncate-lines nil
              word-wrap t)
(setq truncate-partial-width-windows nil
      auto-hscroll-mode nil)
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))

(defun mm/force-soft-wrap-h ()
  "Wrap long lines in every regular buffer and reset horizontal scrolling."
  (unless (minibufferp)
    (visual-line-mode 1)
    (setq-local truncate-lines nil
                word-wrap t)
    (dolist (window (get-buffer-window-list (current-buffer) nil t))
      (set-window-hscroll window 0))))

(add-hook 'after-change-major-mode-hook #'mm/force-soft-wrap-h 100)
(global-visual-line-mode 1)

(after! org-modern
  (setq org-modern-fold-stars
        '(("▶" . "▼") ("▷" . "▽") ("▶" . "▼") ("▷" . "▽") ("▸" . "▾"))))

(defvar mm/zig-onedark-font-lock-settings nil
  "Zig Tree-sitter overrides matching Neovim's One Dark captures.")

(defun mm/zig-ts-max-font-lock-h ()
  "Enable full Zig highlighting and Neovim-compatible captures."
  ;; zig-ts-mode treats enum members as generic properties and its later
  ;; constant rule can overwrite container type definitions.  Neovim captures
  ;; those as @constant and @type, respectively.
  (setq-local treesit-font-lock-settings
              (append zig-ts--font-lock-settings
                      mm/zig-onedark-font-lock-settings))
  (setq-local treesit-font-lock-level 4)
  (treesit-font-lock-recompute-features)
  (font-lock-flush))

(after! zig-ts-mode
  (setq mm/zig-onedark-font-lock-settings
        (treesit-font-lock-rules
         :language 'zig
         :feature 'definition
         :override t
         '((enum_declaration
            (container_field (identifier) @font-lock-constant-face))
           (variable_declaration
            (identifier) @font-lock-type-face
            "=" [(struct_declaration)
                 (enum_declaration)
                 (union_declaration)
                 (opaque_declaration)]))))
  (add-hook 'zig-ts-mode-hook #'mm/zig-ts-max-font-lock-h))

(defconst mm/zig-max-inline-parameters 3
  "Maximum Zig parameters allowed before forcing a multiline list.")

(defconst mm/zig-max-inline-expression-length 100
  "Maximum width of a Zig expression before forcing it multiline.")

(defun mm/zig-logical-binary-p (node)
  "Return non-nil when NODE is a Zig `and' or `or' expression."
  (when (and node (string= (treesit-node-type node) "binary_expression"))
    (when-let ((operator (treesit-node-child-by-field-name node "operator")))
      (member (treesit-node-type operator) '("and" "or")))))

(defun mm/zig-logical-operator-ends (node)
  "Return the end positions of every logical operator below NODE."
  (let (positions)
    (cl-labels ((walk (candidate)
                  (when (string= (treesit-node-type candidate)
                                 "binary_expression")
                    (when (mm/zig-logical-binary-p candidate)
                      (push (treesit-node-end
                             (treesit-node-child-by-field-name candidate
                                                                "operator"))
                            positions))
                    (dolist (child (treesit-node-children candidate t))
                      (when (string= (treesit-node-type child)
                                     "binary_expression")
                        (walk child))))))
      (walk node))
    positions))

(defun mm/zig-force-multiline-lists-before-save-h ()
  "Add trailing commas that make `zig fmt' preserve multiline lists.

This mirrors the Neovim Tree-sitter save hook: enums, structs, unions, and
anonymous struct initializers with more than one field are forced multiline,
as are parameter lists with more than `mm/zig-max-inline-parameters'
parameters."
  (when (and (derived-mode-p 'zig-mode 'zig-ts-mode)
             (treesit-language-available-p 'zig))
    (save-restriction
      (widen)
      (let* ((parser (or (seq-find
                          (lambda (candidate)
                            (eq (treesit-parser-language candidate) 'zig))
                          (treesit-parser-list))
                         (treesit-parser-create 'zig)))
             (root (treesit-parser-root-node parser))
             edits)
        (dolist (capture
                 (treesit-query-capture
                  root
                  '((enum_declaration) @container
                    (struct_declaration) @container
                    (union_declaration) @container
                    (initializer_list) @initializer
                    (if_expression) @if-expression
                    (parameters) @parameters)))
          (let* ((kind (car capture))
                 (node (cdr capture)))
            (if (eq kind 'if-expression)
                (let* ((text (treesit-node-text node t))
                       (children (treesit-node-children node))
                       (consequence (treesit-node-child node 1 t))
                       (else-token
                        (seq-find
                         (lambda (child)
                           (string= (treesit-node-type child) "else"))
                         children))
                       ;; Literals such as `null' are anonymous Tree-sitter
                       ;; nodes, so take the child directly following `else'.
                       (alternative (cadr (memq else-token children))))
                  (when (and (> (string-width text)
                                mm/zig-max-inline-expression-length)
                             (not (string-match-p "\n" text)))
                    (when consequence
                      (push (cons (treesit-node-start consequence) "\n") edits))
                    (when else-token
                      (push (cons (treesit-node-start else-token) "\n") edits))
                    ;; Preserve `else if' on one line, but split a final else body.
                    (when (and alternative
                               (not (string= (treesit-node-type alternative)
                                             "if_expression")))
                      (push (cons (treesit-node-start alternative) "\n") edits))))
              (let* ((item-type (pcase kind
                                  ('container "container_field")
                                  ('initializer "assignment_expression")
                                  (_ "parameter")))
                     (items (seq-filter
                             (lambda (child)
                               (string= (treesit-node-type child) item-type))
                             (treesit-node-children node t)))
                     (minimum (if (eq kind 'parameters)
                                  mm/zig-max-inline-parameters
                                1))
                     (last-item (car (last items))))
                (when (and (> (length items) minimum)
                           last-item
                           (memq (char-before (treesit-node-end node)) '(?} ?\)))
                           (not (eq (char-after (treesit-node-end last-item)) ?,)))
                  (push (cons (treesit-node-end last-item) ",") edits))))))
        ;; `zig fmt' preserves intentional line breaks after logical operators.
        ;; Only split the root of a long chain so nested captures do not add
        ;; duplicate newlines.
        (dolist (capture
                 (treesit-query-capture
                  root '((binary_expression) @logical-expression)))
          (let* ((node (cdr capture))
                 (text (treesit-node-text node t))
                 (parent (treesit-node-parent node)))
            (when (and (mm/zig-logical-binary-p node)
                       (not (mm/zig-logical-binary-p parent))
                       (> (string-width text)
                          mm/zig-max-inline-expression-length)
                       (not (string-match-p "\n" text)))
              (dolist (position (mm/zig-logical-operator-ends node))
                (push (cons position "\n") edits)))))
        (atomic-change-group
          (save-excursion
            (dolist (edit (sort (delete-dups edits)
                                (lambda (left right) (> (car left) (car right)))))
              (goto-char (car edit))
              (insert (cdr edit)))))))))

(defun mm/zig-format-on-save-setup-h ()
  "Format Zig synchronously before save, after enforcing multiline lists."
  ;; Doom normally routes Zig through Apheleia after the first disk write.
  ;; Keep Zig's save path synchronous so the Tree-sitter edit reaches `zig fmt'
  ;; before the file is written.
  (setq-local apheleia-inhibit t)
  (when (bound-and-true-p apheleia-mode)
    (apheleia-mode -1))
  (zig-format-on-save-mode 1)
  (remove-hook 'before-save-hook
               #'mm/zig-force-multiline-lists-before-save-h t)
  (add-hook 'before-save-hook
            #'mm/zig-force-multiline-lists-before-save-h -90 t))

(add-hook! '(zig-mode-hook zig-ts-mode-hook)
  #'mm/zig-format-on-save-setup-h)

(defun mm/zig-preformat-before-write-a (&rest _)
  "Run Zig's multiline pre-pass even when the buffer is unmodified."
  (when (derived-mode-p 'zig-mode 'zig-ts-mode)
    (mm/zig-force-multiline-lists-before-save-h)))

;; `save-buffer' normally skips `before-save-hook' for an unchanged buffer.
;; Run the structural pre-pass before that check so older inline code can be
;; reformatted simply by writing the file.
(advice-add #'save-buffer :before #'mm/zig-preformat-before-write-a)

(after! evil
  ;; Evil's :w has its own write path, so cover it directly as well.
  (advice-add #'evil-write :before #'mm/zig-preformat-before-write-a))

(setq doom-theme 'doom-one)

(after! gcmh
  ;; The startup cap prevents a large one-time allocation peak.  Once editing,
  ;; retain Doom's performance-oriented threshold so completion and LSP JSON
  ;; processing do not trigger garbage collection too frequently.  Doom's LSP
  ;; module temporarily doubles this while a language server is active.
  (setq gcmh-high-cons-threshold (* 64 1024 1024)))

(defface mm-modeline-mode-normal
  '((t (:foreground "#000000" :background "#98e06c" :weight bold)))
  "Face for normal state in the lualine-style modeline.")

(defface mm-modeline-mode-insert
  '((t (:foreground "#000000" :background "#5aa9ff" :weight bold)))
  "Face for insert state in the lualine-style modeline.")

(defface mm-modeline-mode-visual
  '((t (:foreground "#000000" :background "#d787ff" :weight bold)))
  "Face for visual state in the lualine-style modeline.")

(defface mm-modeline-mode-command
  '((t (:foreground "#000000" :background "#ffd866" :weight bold)))
  "Face for command state in the lualine-style modeline.")

(defface mm-modeline-mode-terminal
  '((t (:foreground "#000000" :background "#56d4dd" :weight bold)))
  "Face for terminal state in the lualine-style modeline.")

(defface mm-modeline-mode-replace
  '((t (:foreground "#000000" :background "#ff5f6d" :weight bold)))
  "Face for replace state in the lualine-style modeline.")

(defface mm-modeline-branch
  '((t (:foreground "#d8dee9" :background "#161b22")))
  "Face for the branch section in the lualine-style modeline.")

(defface mm-modeline-workspace-current
  '((t (:foreground "#000000" :background "#5aa9ff" :weight bold)))
  "Face for the current workspace in the modeline.")


(defun mm/apply-onedark-faces ()
  "Tune Doom's theme to match the Neovim onedark palette."
  (custom-set-faces!
    '(default :foreground "#d8dee9" :background "#000000")
    '(fringe :foreground "#6b7280" :background "#000000")
    '(vertical-border :foreground "#161b22" :background "#000000")
    '(window-divider :foreground "#161b22" :background "#000000")
    '(tooltip :foreground "#d8dee9" :background "#0d1117")
    '(company-tooltip :foreground "#d8dee9" :background "#0d1117")
    '(company-tooltip-selection :foreground "#000000" :background "#5aa9ff")
    '(company-scrollbar-bg :background "#0d1117")
    '(company-scrollbar-fg :background "#21262d")
    '(solaire-default-face :foreground "#d8dee9" :background "#000000")
    '(solaire-hl-line-face :background "#0d1117")
    '(font-lock-comment-face :foreground "#6b7280" :slant normal)
    '(font-lock-doc-face :foreground "#6b7280" :slant normal)
    '(font-lock-string-face :foreground "#98e06c")
    '(font-lock-function-name-face :foreground "#5aa9ff")
    '(font-lock-keyword-face :foreground "#d787ff")
    '(font-lock-builtin-face :foreground "#56d4dd")
    '(font-lock-preprocessor-face :foreground "#56d4dd")
    '(font-lock-type-face :foreground "#ffd866")
    '(font-lock-constant-face :foreground "#ff9f43")
    '(font-lock-number-face :foreground "#ff9f43")
    '(font-lock-variable-name-face :foreground "#d8dee9")
    '(font-lock-property-name-face :foreground "#56d4dd")
    '(font-lock-property-use-face :foreground "#56d4dd")
    '(font-lock-variable-use-face :foreground "#d8dee9")
    '(font-lock-function-call-face :foreground "#5aa9ff")
    '(font-lock-operator-face :foreground "#d8dee9")
    '(font-lock-bracket-face :foreground "#d8dee9")
    '(font-lock-delimiter-face :foreground "#d8dee9")
    ;; Eglot's semantic-token faces layer over Tree-sitter in Zig buffers.
    ;; Match the corresponding One Dark LSP groups used by Neovim.
    '(eglot-semantic-static :foreground "#ff9f43")
    '(eglot-semantic-parameter :foreground "#ff5f6d")
    '(eglot-semantic-variable :foreground "#d8dee9")
    '(eglot-semantic-function :foreground "#5aa9ff")
    '(eglot-semantic-type :foreground "#ffd866")
    ;; Rust-specific Tree-sitter and rust-analyzer semantic categories.
    '(font-lock-escape-face :foreground "#ff5f6d")
    '(rust-ampersand-face :foreground "#d8dee9")
    '(eglot-semantic-macro :foreground "#56d4dd")
    '(eglot-semantic-namespace :foreground "#ffd866")
    '(eglot-semantic-enumMember :foreground "#ff9f43")
    '(line-number :foreground "#6b7280" :background "#000000")
    '(line-number-current-line :foreground "#d8dee9" :background "#0d1117")
    '(hl-line :background "#0d1117")
    '(region :background "#21262d")
    '(mode-line :foreground "#d8dee9" :background "#0d1117")
    '(mode-line-buffer-id :foreground "#5aa9ff" :weight bold)
    '(doom-modeline :foreground "#d8dee9" :background "#0d1117")
    '(doom-modeline-bar :background "#5aa9ff")
    '(doom-modeline-bar-inactive :background "#000000")
    '(doom-modeline-emphasis :foreground "#d8dee9" :background "#0d1117")
    '(doom-modeline-highlight :foreground "#5aa9ff" :background "#0d1117")
    '(mm-modeline-mode-normal :foreground "#000000" :background "#98e06c" :weight bold)
    '(mm-modeline-mode-insert :foreground "#000000" :background "#5aa9ff" :weight bold)
    '(mm-modeline-mode-visual :foreground "#000000" :background "#d787ff" :weight bold)
    '(mm-modeline-mode-command :foreground "#000000" :background "#ffd866" :weight bold)
    '(mm-modeline-mode-terminal :foreground "#000000" :background "#56d4dd" :weight bold)
    '(mm-modeline-mode-replace :foreground "#000000" :background "#ff5f6d" :weight bold)
    '(mm-modeline-branch :foreground "#d8dee9" :background "#161b22")
    '(mm-modeline-workspace-current :foreground "#000000" :background "#5aa9ff" :weight bold)
    '(doom-modeline-buffer-file :foreground "#5aa9ff" :weight bold)
    '(doom-modeline-buffer-path :foreground "#5aa9ff" :weight bold)
    '(doom-modeline-buffer-modified :foreground "#56d4dd" :background "#0d1117" :weight bold)
    '(doom-modeline-buffer-major-mode :foreground "#d8dee9" :background "#0d1117")
    '(doom-modeline-project-dir :foreground "#d8dee9" :background "#0d1117")
    '(doom-modeline-project-root-dir :foreground "#5aa9ff" :background "#0d1117")
    '(doom-modeline-vcs-default :foreground "#6b7280" :background "#0d1117")
    '(solaire-mode-line-face :foreground "#d8dee9" :background "#0d1117")
    '(solaire-mode-line-inactive-face :foreground "#6b7280" :background "#000000")
    '(mode-line-inactive :foreground "#6b7280" :background "#000000")
    '(centaur-tabs-default :foreground "#d8dee9" :background "#000000")
    '(centaur-tabs-selected :foreground "#000000" :background "#5aa9ff" :weight normal)
    '(centaur-tabs-selected-modified :foreground "#000000" :background "#5aa9ff" :weight normal)
    '(centaur-tabs-unselected :foreground "#6b7280" :background "#000000" :weight normal)
    '(centaur-tabs-unselected-modified :foreground "#56d4dd" :background "#000000" :weight normal)
    '(centaur-tabs-close-unselected :foreground "#6b7280" :background "#000000")
    '(centaur-tabs-close-selected :foreground "#000000" :background "#5aa9ff")
    '(centaur-tabs-modified-marker-unselected :foreground "#56d4dd" :background "#000000")
    '(centaur-tabs-modified-marker-selected :foreground "#000000" :background "#5aa9ff")
    '(centaur-tabs-active-bar-face :background "#5aa9ff")
    '(tab-line :foreground "#d8dee9" :background "#000000")
    '(tab-line-tab :foreground "#d8dee9" :background "#000000")
    '(tab-line-tab-current :foreground "#000000" :background "#5aa9ff")
    '(tab-line-tab-inactive :foreground "#6b7280" :background "#000000")
    '(header-line :foreground "#d8dee9" :background "#000000")))


(add-hook 'doom-load-theme-hook #'mm/apply-onedark-faces)

(setq display-line-numbers-type 'relative)


(global-display-line-numbers-mode 1)


(dolist (hook '(term-mode-hook
                ghostel-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))


(dolist (hook '(term-mode-hook
                ghostel-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook hook #'mm/disable-terminal-process-query))

(after! doom-modeline
  (setq doom-modeline-bar-width 0
        doom-modeline-buffer-file-name-style 'relative-to-project
        doom-modeline-check 'full
        doom-modeline-icon t
        doom-modeline-major-mode-icon nil
        doom-modeline-modal nil)

  (defun mm/modeline-evil-state ()
    "Return the current Evil state like lualine's mode component."
    (upcase
     (if (bound-and-true-p evil-local-mode)
         (symbol-name evil-state)
       (format-mode-line mode-name))))

  (defun mm/modeline-mode-face ()
    "Return the lualine onedark face for the current mode/state."
    (pcase (and (bound-and-true-p evil-local-mode) evil-state)
      ('normal 'mm-modeline-mode-normal)
      ('insert 'mm-modeline-mode-insert)
      ('visual 'mm-modeline-mode-visual)
      ('ghostel 'mm-modeline-mode-terminal)
      ('replace 'mm-modeline-mode-replace)
      ('operator 'mm-modeline-mode-command)
      ('motion 'mm-modeline-mode-normal)
      (_ 'mm-modeline-mode-normal)))

  (defun mm/modeline-file-name ()
    "Return the current file name relative to the project when possible."
    (let ((name (or buffer-file-name (buffer-name))))
      (if buffer-file-name
          (let* ((root (or (ignore-errors (doom-project-root))
                           (locate-dominating-file buffer-file-name ".git")
                           default-directory))
                 (relative (file-relative-name buffer-file-name root)))
            (concat relative
                    (cond (buffer-read-only " RO")
                          ((buffer-modified-p) " [+]")
                          (t ""))))
        name)))

  (defun mm/modeline-git-root ()
    "Return the Git root for the current buffer."
    (when-let ((file buffer-file-name))
      (locate-dominating-file file ".git")))

  (defun mm/modeline-git-branch ()
    "Return Git branch information maintained by VC without starting Git."
    (when (and (boundp 'vc-mode) vc-mode)
      (string-remove-prefix
       "Git:"
       (string-trim (substring-no-properties vc-mode)))))

  (defun mm/modeline-git-diff ()
    "Return nil.

Per-file diff counts required a synchronous Git subprocess during every
modeline redisplay. VC's gutter remains the lightweight live diff display."
    nil)

  (defun mm/modeline-diagnostic-counts ()
    "Return diagnostics as E:/W:/I:/H: counts like lualine."
    (let ((error 0)
          (warning 0)
          (info 0)
          (hint 0))
      (cond
       ((bound-and-true-p flymake-mode)
        (dolist (diag (flymake-diagnostics (point-min) (point-max)))
          (pcase (flymake-diagnostic-type diag)
            (:error (cl-incf error))
            (:warning (cl-incf warning))
            (_ (cl-incf info)))))
       ((bound-and-true-p flycheck-mode)
        (dolist (item (flycheck-count-errors flycheck-current-errors))
          (pcase (flycheck-error-level-compilation-level (car item))
            (2 (cl-incf error (cdr item)))
            (1 (cl-incf warning (cdr item)))
            (0 (cl-incf info (cdr item)))))))
      (let ((parts nil))
        (when (> error 0)
          (push (propertize (format "E:%d" error) 'face 'doom-modeline-urgent) parts))
        (when (> warning 0)
          (push (propertize (format "W:%d" warning) 'face 'doom-modeline-warning) parts))
        (when (> info 0)
          (push (propertize (format "I:%d" info) 'face 'doom-modeline-info) parts))
        (when (> hint 0)
          (push (propertize (format "H:%d" hint) 'face 'doom-modeline-info) parts))
        (when parts
          (concat " " (string-join (nreverse parts) " "))))))

  (doom-modeline-def-segment mm-mode
    "Show Evil mode like lualine_a."
    (propertize (format " %s " (mm/modeline-evil-state))
                'face (mm/modeline-mode-face)))

  (doom-modeline-def-segment mm-branch
    "Show Git branch like lualine_b."
    (when-let ((branch (mm/modeline-git-branch)))
      (unless (string-empty-p branch)
        (propertize (format " %s " branch) 'face 'mm-modeline-branch))))

  (doom-modeline-def-segment mm-diff
    "Show diff counts like lualine_b."
    (mm/modeline-git-diff))

  (doom-modeline-def-segment mm-diagnostics
    "Show diagnostics like lualine_b."
    (mm/modeline-diagnostic-counts))

  (doom-modeline-def-segment mm-file
    "Show file path like lualine_c filename path=1."
    (concat " " (propertize (mm/modeline-file-name)
                            'face 'doom-modeline-buffer-file)))

  (doom-modeline-def-segment mm-workspaces
    "Show all open Doom workspaces like the Neovim lualine workspace component."
    (when (and (bound-and-true-p persp-mode)
               (fboundp '+workspace-list-names)
               (fboundp '+workspace-current-name)
               (ignore-errors (+workspace-current)))
      (ignore-errors
        (let ((names (+workspace-list-names))
              (current-name (+workspace-current-name)))
          (when names
            (let ((index 0))
              (concat
               " "
               (mapconcat
                #'identity
                (mapcar
                 (lambda (name)
                   (setq index (1+ index))
                   (propertize
                    (format " %d:%s " index name)
                    'face (if (equal name current-name)
                              'mm-modeline-workspace-current
                            'doom-modeline)))
                 names)
                ""))))))))

  (doom-modeline-def-segment mm-location
    "Show line and column like lualine_z location."
    (format " %d:%d " (line-number-at-pos) (current-column)))

  (doom-modeline-def-modeline 'main
    '(mm-mode mm-branch mm-diff mm-diagnostics mm-file)
    '(mm-workspaces mm-location))

  (doom-modeline-def-modeline 'dashboard
    '(mm-mode mm-file)
    '(mm-workspaces mm-location)))

(after! centaur-tabs
  (setq centaur-tabs-height 14
        centaur-tabs-bar-height 16
        centaur-tabs-set-close-button nil
        centaur-tabs-show-new-tab-button nil
        centaur-tabs-show-navigation-buttons nil
        centaur-tabs-left-edge-margin " "
        centaur-tabs-right-edge-margin " "
        centaur-tabs-icons-prefix "")


(defun mm/apply-centaur-tabs-onedark ()
    "Keep centaur-tabs' fill/background matched to Neovim onedark."
    (set-face-attribute centaur-tabs-display-line nil
                        :foreground "#d8dee9"
                        :background "#000000"
                        :box nil
                        :overline nil
                        :underline nil)
    (set-face-attribute 'centaur-tabs-default nil
                        :foreground "#d8dee9"
                        :background "#000000"
                        :height 0.9)
    (dolist (face '(centaur-tabs-selected
                    centaur-tabs-selected-modified
                    centaur-tabs-unselected
                    centaur-tabs-unselected-modified))
      (set-face-attribute face nil :height 0.9))
    (centaur-tabs-display-update))
  (add-hook 'doom-load-theme-hook #'mm/apply-centaur-tabs-onedark)
  (mm/apply-centaur-tabs-onedark))

(after! treemacs
  ;; Keep the project drawer visually aligned with Neo-tree: compact nesting,
  ;; a quiet background, blue project/folder accents, and one clear selection.
  (setq treemacs-width 34
        treemacs-indentation 1
        treemacs-indent-guide-style 'line
        treemacs-space-between-root-nodes nil
        treemacs-collapse-dirs 0
        treemacs-show-hidden-files t)

  (custom-set-faces!
    '(treemacs-window-background-face :foreground "#d8dee9" :background "#000000")
    '(treemacs-hl-line-face :foreground "#d8dee9" :background "#161b22" :extend t)
    '(treemacs-root-face :foreground "#5aa9ff" :weight bold :underline nil :height 1.0)
    '(treemacs-directory-face :foreground "#5aa9ff" :weight normal)
    '(treemacs-directory-collapsed-face :foreground "#5aa9ff")
    '(treemacs-file-face :foreground "#d8dee9")
    '(treemacs-git-unmodified-face :foreground "#d8dee9")
    '(treemacs-git-modified-face :foreground "#ffd866")
    '(treemacs-git-added-face :foreground "#98e06c")
    '(treemacs-git-untracked-face :foreground "#56d4dd")
    '(treemacs-git-ignored-face :foreground "#6b7280" :slant italic)
    '(treemacs-git-conflict-face :foreground "#ff5f6d" :weight bold)
    '(treemacs-fringe-indicator-face :foreground "#5aa9ff"))

  (treemacs-indent-guide-mode 1)

  ;; Simple Git mode only decorates files.  Extended mode also marks ignored
  ;; build/cache directories such as `.zig-cache', `zig-out', and `zig-pkg'.
  (when-let ((python (executable-find "python3")))
    (setq treemacs-python-executable python)
    (treemacs-git-mode 'extended))

  (treemacs-define-RET-action 'file-node-open #'treemacs-visit-node-close-treemacs)
  (treemacs-define-RET-action 'file-node-closed #'treemacs-visit-node-close-treemacs))

(defun mm/treemacs-no-wrap-h ()
  "Keep Treemacs entries on one clipped line, like Neo-tree."
  (visual-line-mode -1)
  (setq-local truncate-lines t
              word-wrap nil)
  (dolist (window (get-buffer-window-list (current-buffer) nil t))
    (set-window-hscroll window 0)))

(add-hook 'treemacs-mode-hook #'mm/treemacs-no-wrap-h 110)

(defun mm/treemacs-apply-git-faces-now-h ()
  "Apply cached Git faces to every visible Treemacs node."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'treemacs-mode)
        (treemacs-apply-annotations-in-buffer buffer)))))

(defun mm/treemacs-apply-git-faces-h (&rest _)
  "Apply Git faces after Treemacs has finished its asynchronous refresh."
  (run-at-time 0.6 nil #'mm/treemacs-apply-git-faces-now-h))

(after! treemacs
  (add-hook 'treemacs-post-project-refresh-functions
            #'mm/treemacs-apply-git-faces-h))

(setq scroll-margin 20
      maximum-scroll-margin 0.5
      scroll-conservatively 101
      scroll-preserve-screen-position t)

;; Without fine undo, evil amalgamates each insert session into one undo step by
;; stripping undo boundaries up to `evil-undo-list-pointer'
;; (`evil-refresh-undo-step'). When that pointer goes stale -- e.g. after
;; `buffer-undo-list' is truncated by `undo-limit' or GC'd -- the strip runs all
;; the way back to buffer creation, merging the whole history into a single step.
;; A lone `u' then reverts everything and dumps point at the top of the file.
;; Fine undo disables that amalgamation, so each change is its own step.
(setq evil-want-fine-undo t)

(use-package! indent-bars
  :hook ((prog-mode conf-mode) . indent-bars-mode)
  :config
  (setq indent-bars-color '("#5aa9ff" :face-bg nil :blend 0)
        indent-bars-prefer-character t
        indent-bars-no-stipple-char ?|
        indent-bars-display-on-blank-lines t
        ;; The current-depth idle timer can run before a perspective-restored
        ;; buffer has a live window position, producing a nil marker error.
        indent-bars-highlight-current-depth nil
        indent-bars-current-depth-color '("#ffd866" :face-bg nil :blend 0)))

;; Keep completion suggestions usable in both GUI and terminal Emacs.

(after! company
  (setq company-idle-delay 0
        company-minimum-prefix-length 1
        ;; Keep an exact candidate visible while point remains in the word.
        ;; Company will still close normally when a separator ends the prefix.
        company-abort-on-unique-match nil
        company-tooltip-limit 14
        ;; Merge LSP/CAPF candidates with identifiers already used in the
        ;; current buffer (and other buffers in the same major mode).
        company-backends '((company-capf :with company-dabbrev-code))
        company-dabbrev-code-ignore-case t
        company-selection-wrap-around t
        company-auto-complete nil
        company-auto-commit nil)
  (setq-default company-backends '((company-capf :with company-dabbrev-code)))
  ;; Navigate LSP candidates immediately.  Company's default TAB command
  ;; expands the longest common prefix before it starts moving through them.
  (define-key company-active-map [tab] #'company-select-next)
  (define-key company-active-map (kbd "TAB") #'company-select-next)
  (define-key company-active-map [backtab] #'company-select-previous)
  (global-company-mode 1))

(defun mm/company-merge-buffer-words-h ()
  "Merge LSP, same-language buffer words, and snippets in code buffers."
  (when (derived-mode-p 'prog-mode)
    ;; Doom's `+company-init-backends-h' prepends a standalone `company-capf'
    ;; when Company starts.  That backend wins before a later merged backend
    ;; can run, so replace the final buffer-local value after Doom's hook.
    (setq-local company-backends
                '((company-capf :with company-dabbrev-code company-yasnippet)))))

(after! company
  (add-hook 'company-mode-hook #'mm/company-merge-buffer-words-h 90))


(map! :i "C-SPC" #'company-complete
      :i "C-@" #'company-complete)


(defun mm/rust-company-complete-after-trigger ()
  "Trigger LSP completion after Rust access and namespace syntax."
  (when (and (derived-mode-p 'rust-mode 'rustic-mode 'rust-ts-mode)
             (bound-and-true-p eglot--managed-mode)
             (or (eq last-command-event ?.)
                 (and (eq last-command-event ?:)
                      (eq (char-before (1- (point))) ?:))))
    (company-manual-begin)))


(add-hook! '(rust-mode-hook rustic-mode-hook rust-ts-mode-hook)
  (defun mm/rust-save-setup-h ()
    (company-mode 1)
    (setq-local company-minimum-prefix-length 1
                ;; Was 0.08, which fired a completion request to rust-analyzer
                ;; after nearly every keystroke. `.'/`::' still complete
                ;; instantly via `mm/rust-company-complete-after-trigger'.
                company-idle-delay 0.2
                company-backends '((company-capf :with company-dabbrev-code)))
    (add-hook 'before-save-hook #'mm/rust-organize-imports nil t)
    (add-hook 'post-self-insert-hook #'mm/rust-company-complete-after-trigger nil t)))





(add-hook! '(rust-mode-hook
             rustic-mode-hook
             rust-ts-mode-hook)
  #'mm/rust-eglot-start-h)

(use-package! which-key
  :demand t
  :config
  (which-key-mode 1))

(after! which-key
  ;; `override-state' is an Evil/General implementation marker, not a key.
  (unless (string-match-p "override-state" which-key--ignore-non-evil-keys-regexp)
    (setq which-key--ignore-non-evil-keys-regexp
          (concat "\\(?:" which-key--ignore-non-evil-keys-regexp
                  "\\|override-state\\)")))
  ;; Remove the old leader-group labels from earlier config loads as well as
  ;; from future startups.  Individual active bindings provide their own
  ;; descriptions via `map!'.
  (setq which-key-replacement-alist
        (cl-remove-if
         (lambda (entry)
           (member (and (consp (cdr entry))
                        (cdr (cdr entry)))
                   '("buffer" "code" "debugger" "evaluate" "file" "git"
                     "help" "insert" "multiple cursors" "notes" "open"
                     "project" "quit/session" "toggle"
                     "universal argument" "workspace/windows")))
         which-key-replacement-alist))
  (which-key-add-key-based-replacements
    doom-leader-key "leader"
    (concat doom-leader-key " TAB") "workspace"
    (concat doom-leader-key " b") "bookmark"
    (concat doom-leader-key " c") "code"
    (concat doom-leader-key " j") "Mise task"
    (concat doom-leader-key " m") "Multicursor"
    (concat doom-leader-key " o") "Org"
    (concat doom-leader-key " s") "search")
  (when doom-leader-alt-key
    (which-key-add-key-based-replacements
      doom-leader-alt-key "leader"
      (concat doom-leader-alt-key " TAB") "workspace"
      (concat doom-leader-alt-key " b") "bookmark"
      (concat doom-leader-alt-key " c") "code"
      (concat doom-leader-alt-key " j") "Mise task"
      (concat doom-leader-alt-key " m") "Multicursor"
      (concat doom-leader-alt-key " o") "Org"
      (concat doom-leader-alt-key " s") "search"))
  ;; Undo the old filter that hid SPC m before it became Multicursor.
  (advice-remove #'which-key--get-bindings
                 #'mm/which-key-filter-removed-leader-bindings))

(defun mm/toggle-which-key ()
  "Toggle Which-Key globally, hiding its popup when disabling it."
  (interactive)
  (which-key-mode 'toggle)
  (message "Which-Key %s" (if (default-value 'which-key-mode) "enabled" "disabled")))

(defun mm/toggle-diagnostics ()
  "Show or hide the Flycheck diagnostics window."
  (interactive)
  (require 'flycheck)
  (if-let ((window (get-buffer-window flycheck-error-list-buffer
                                      (selected-frame))))
      (quit-window nil window)
    (flycheck-list-errors)))

(defconst mm/left-reading-gutter-ratio 0.30
  "Fraction of a window reserved as a left reading gutter.")

(defun mm/apply-left-reading-gutter (window)
  "Recalculate the proportional left reading gutter for WINDOW."
  (when (and (window-live-p window)
             (window-parameter window 'mm-left-reading-gutter))
    (let* ((frame (window-frame window))
           (char-width (max 1 (frame-char-width frame)))
           (columns (max 1
                         (floor (/ (* (window-pixel-width window)
                                      mm/left-reading-gutter-ratio)
                                   char-width))))
           (original (window-parameter
                      window 'mm-left-reading-gutter-original-margins)))
      (unless (equal (window-margins window)
                     (cons columns (cdr-safe original)))
        (set-window-margins window columns (cdr-safe original))))))

(defun mm/refresh-left-reading-gutters (frame)
  "Refresh enabled reading gutters after windows resize in FRAME."
  (walk-windows #'mm/apply-left-reading-gutter 'no-minibuf frame))

(defun mm/toggle-left-reading-gutter ()
  "Toggle a 30% left gutter in the selected window."
  (interactive)
  (let ((window (selected-window)))
    (if (window-parameter window 'mm-left-reading-gutter)
        (let ((original (window-parameter
                         window 'mm-left-reading-gutter-original-margins)))
          (set-window-parameter window 'mm-left-reading-gutter nil)
          (set-window-parameter window 'mm-left-reading-gutter-original-margins nil)
          (set-window-margins window (car-safe original) (cdr-safe original))
          (message "Left reading gutter disabled"))
      (set-window-parameter window 'mm-left-reading-gutter-original-margins
                            (window-margins window))
      (set-window-parameter window 'mm-left-reading-gutter t)
      (mm/apply-left-reading-gutter window)
      (message "Left reading gutter: 30%%"))))

(add-hook 'window-size-change-functions #'mm/refresh-left-reading-gutters)

(map! :leader
      :desc "Repeat Action" "'" #'vertico-repeat
      :desc "Jump to bookmark" "RET" #'bookmark-jump
      :desc "Find files" "SPC" #'mm/project-find-file
      :desc "File explorer" "e" #'+treemacs/toggle
      :desc "Git" "g" #'magit-status
      :desc "Toggle LSP hints globally" "h" #'mm/toggle-lsp-inlay-hints
      :desc "Toggle diagnostics" "d" #'mm/toggle-diagnostics
      :desc "Toggle Which-Key" "w" #'mm/toggle-which-key
      :desc "Terminal Popup" "t" #'mm/toggle-bottom-terminal
      :desc "Terminal Window" "T" #'mm/open-ghostel-frame
      :desc "Toggle left reading gutter" "z" #'mm/toggle-left-reading-gutter
      (:prefix ("b" . "Bookmark")
       :desc "Set bookmark" "m" #'bookmark-set
       :desc "Delete bookmark" "M" #'bookmark-delete)
      (:prefix ("c" . "code")
       :desc "LSP Execute code action" "a" #'eglot-code-actions
       :desc "LSP Rename" "r" #'eglot-rename
       :desc "LSP Find declaration" "j" #'eglot-find-declaration
       :desc "Jump to symbol in current workspace" "J" #'consult-eglot-symbols
       :desc "Format buffer/region" "f" #'+format/region-or-buffer
       :desc "List errors" "x" #'+default/diagnostics
       :desc "Toggle Codex" "c" #'mm/codex-toggle
       :desc "Toggle Cursor" "u" #'mm/cursor-toggle
       :desc "Toggle OpenCode" "o" #'mm/opencode-toggle)
      :desc "Mise task" "j" #'mm/mise-select
      (:prefix ("m" . "Multicursor")
       :desc "Select all matches" "a" #'evil-mc-make-all-cursors
       :desc "Add next match" "n" #'evil-mc-make-and-goto-next-match
       :desc "Add previous match" "p" #'evil-mc-make-and-goto-prev-match
       :desc "Skip next match" "N" #'evil-mc-skip-and-goto-next-match
       :desc "Skip previous match" "P" #'evil-mc-skip-and-goto-prev-match
       :desc "Add cursor below" "j" #'evil-mc-make-cursor-move-next-line
       :desc "Add cursor above" "k" #'evil-mc-make-cursor-move-prev-line
       :desc "Cursors at line beginnings" "b" #'evil-mc-make-cursor-in-visual-selection-beg
       :desc "Cursors at line endings" "e" #'evil-mc-make-cursor-in-visual-selection-end
       :desc "Undo last cursor" "u" #'evil-mc-undo-last-added-cursor
       :desc "Remove all cursors" "q" #'evil-mc-undo-all-cursors
       :desc "Pause cursors" "s" #'evil-mc-pause-cursors
       :desc "Resume cursors" "r" #'evil-mc-resume-cursors)
      (:prefix ("o" . "Org")
       :desc "Daily note" "d" #'mm/open-daily-org
       :desc "Find Org note" "f" #'mm/find-org-note
       :desc "Grep Org notes" "g" #'mm/grep-org-notes
       :desc "Org Agenda" "a" #'org-agenda-list
       :desc "Org Capture" "c" #'org-capture)
      (:prefix ("s" . "Search")
       :desc "Current word" "w" #'mm/search-project-symbol-at-point
       :desc "Project" "p" #'mm/search-project
       :desc "Diagnostics" "d" #'mm/search-diagnostics
       :desc "Repeat last search" "r" #'mm/repeat-last-search
       :desc "Buffer" "b" #'mm/search-buffer
       :desc "TODO" "t" #'mm/search-project-todos)
      (:prefix ("TAB" . "Workspace")
       :desc "Next workspace" "TAB" #'+workspace/switch-right
       :desc "Load workspace" "l" #'mm/workspace-load
       :desc "New workspace" "n" #'mm/workspace-new-from-project
       :desc "Close workspace" "d" #'mm/workspace-kill
       :desc "Delete saved workspace" "D" #'mm/workspace-delete
       :desc "Workspace 1" "1" (cmd! (+workspace/switch-to 0))
       :desc "Workspace 2" "2" (cmd! (+workspace/switch-to 1))
       :desc "Workspace 3" "3" (cmd! (+workspace/switch-to 2))
       :desc "Workspace 4" "4" (cmd! (+workspace/switch-to 3))))

;; Let Doom/Projectile discover projects kept in ~/dev subfolders.
;; Use `SPC p p` to switch projects, or `SPC p a` to add one manually.

(defconst mm/aerospace-ghostel-helper
  (expand-file-name "scripts/aerospace-place-ghostel" doom-user-dir)
  "Detached helper that places a Ghostel frame without blocking Emacs.")

(defun mm/open-ghostel-frame ()
  "Open a repo-root Ghostel frame on the left at 37% screen width."
  (interactive)
  ;; Declare Ghostel's special variables before dynamically binding them below.
  ;; Loading the deferred package from inside the binding prevents Ghostel from
  ;; initializing and leaves an empty frame behind.
  (require 'ghostel)
  (let* ((origin-buffer (window-buffer (selected-window)))
         (root
          (with-current-buffer origin-buffer
            (or (ignore-errors (doom-project-root))
                (when-let ((project (project-current nil default-directory)))
                  (project-root project))
                (locate-dominating-file default-directory ".git")
                default-directory)))
         (window-token (format "Ghostel-%d-%d"
                               (emacs-pid) (truncate (* 1000 (float-time)))))
         (workarea (frame-monitor-attribute 'workarea (selected-frame)))
         (target-width (max 320 (round (* (nth 2 workarea) 0.37))))
         (background (face-background 'default (selected-frame) t))
         (frame (make-frame `((title . ,window-token)
                              (background-color . ,background)
                              (ns-transparent-titlebar . t)
                              (ns-appearance . dark))))
        (display-buffer-alist nil)
        (ghostel-buffer-name (generate-new-buffer-name "*ghostel-frame*")))
    (set-face-background 'default background frame)
    (select-frame-set-input-focus frame)
    (with-selected-frame frame
      ;; `default-directory' is buffer-local, so bind it only after selecting
      ;; the new frame's inherited buffer.
      (let ((default-directory (file-name-as-directory root)))
        (ghostel)))
    ;; Never call AeroSpace synchronously from Emacs: its accessibility query
    ;; can wait on Emacs's UI thread and deadlock both processes.
    (when (file-executable-p mm/aerospace-ghostel-helper)
      (let ((process
             (start-process "aerospace-place-ghostel" nil
                            mm/aerospace-ghostel-helper
                            (number-to-string (emacs-pid))
                            window-token
                            (number-to-string target-width))))
        (set-process-query-on-exit-flag process nil)))
    ;; Keep the unique title only long enough for the detached helper to find
    ;; the new native window.
    (run-at-time 5 nil #'modify-frame-parameters frame '((title . nil)))))


(after! eshell
  (setq eshell-aliases-file (expand-file-name "eshell/aliases" doom-user-dir))
  
  (defun eshell/z (&rest args)
    "Navigate to directory using zoxide."
    (if (null args)
        (eshell/cd)
      (let* ((cmd (concat "zoxide query " (mapconcat #'shell-quote-argument args " ")))
             (dir (string-trim (shell-command-to-string cmd))))
        (if (and dir (not (string-empty-p dir)) (file-accessible-directory-p dir))
            (eshell/cd dir)
          (eshell-printn (format "zoxide: no match found for %s" (car args)))))))

  (defun mm/zoxide-add-dir ()
    "Add current directory to zoxide."
    (start-process "zoxide-add" nil "zoxide" "add" default-directory))

  (add-hook 'eshell-directory-change-hook #'mm/zoxide-add-dir))

(defun mm/apply-ghostel-vivid-faces ()
  "Apply the shared true-black vivid palette to Ghostel."
  (custom-set-faces!
    '(ghostel-default :foreground "#d8dee9" :background "#000000")
    '(ghostel-color-black :foreground "#000000")
    '(ghostel-color-red :foreground "#ff5f6d")
    '(ghostel-color-green :foreground "#98e06c")
    '(ghostel-color-yellow :foreground "#ffd866")
    '(ghostel-color-blue :foreground "#5aa9ff")
    '(ghostel-color-magenta :foreground "#d787ff")
    '(ghostel-color-cyan :foreground "#56d4dd")
    '(ghostel-color-white :foreground "#d8dee9")
    '(ghostel-color-bright-black :foreground "#6b7280")
    '(ghostel-color-bright-red :foreground "#ff7b86")
    '(ghostel-color-bright-green :foreground "#b3f58c")
    '(ghostel-color-bright-yellow :foreground "#ffe38a")
    '(ghostel-color-bright-blue :foreground "#80bcff")
    '(ghostel-color-bright-magenta :foreground "#e6a0ff")
    '(ghostel-color-bright-cyan :foreground "#7cebf2")
    '(ghostel-color-bright-white :foreground "#ffffff"))
  ;; Ghostel's renderer caches the ANSI palette internally.  Updating the
  ;; Emacs faces alone does not affect programs such as eza that emit indexed
  ;; ANSI colors, so push the new palette into every live terminal as well.
  (when (fboundp 'ghostel-sync-theme)
    (ghostel-sync-theme)))

(add-hook 'doom-load-theme-hook #'mm/apply-ghostel-vivid-faces)

(use-package! ghostel
  :defer t
  :init
  ;; Keep the downloaded native module outside straight's package checkout so
  ;; package rebuilds cannot replace a module that Emacs currently has loaded.
  (setq ghostel-module-directory (expand-file-name "ghostel/" doom-user-dir)
        ghostel-module-auto-install 'download
        ghostel-shell "/opt/homebrew/bin/fish")
  :config
  (setq ghostel-buffer-name-function nil
        ghostel-query-before-killing nil
        ghostel-bold-color 'bright)
  (mm/apply-ghostel-vivid-faces))

(defun mm/ghostel-popup-double-escape ()
  "Preserve the first Escape and close this bottom popup on the second."
  (interactive)
  (if (eq last-command #'mm/ghostel-popup-double-escape)
      (when (window-live-p (selected-window))
        (delete-window (selected-window)))
    (if (eq evil-state 'insert)
        (evil-ghostel--escape)
      (evil-force-normal-state))))

(defun mm/setup-ghostel-popup-double-escape-h ()
  "Install double-Escape closing only in bottom Ghostel popup buffers."
  (when (string-prefix-p "*doom:ghostel-popup:" (buffer-name))
    (dolist (state '(insert normal visual operator motion))
      (evil-local-set-key state (kbd "<escape>")
                          #'mm/ghostel-popup-double-escape))))

(defun mm/evil-ghostel-forward-or-accept (count)
  "Move right in scrollback, or let Fish handle Right Arrow at its prompt.

At the end of live input Fish uses Right Arrow to accept its full gray
autosuggestion.  Evil-Ghostel normally keeps `l' entirely inside Emacs, so the
shell never receives that key."
  (interactive "p")
  (if (and (fboundp 'evil-ghostel--prompt-active-p)
           (evil-ghostel--prompt-active-p))
      (progn
        (dotimes (_ (or count 1))
          (ghostel-send-key "right"))
        (when (fboundp 'evil-ghostel--sync-render)
          (evil-ghostel--sync-render))
        (when (fboundp 'evil-ghostel--reset-cursor-point)
          (evil-ghostel--reset-cursor-point)))
    (evil-forward-char count)))

(use-package! evil-ghostel
  :after (ghostel evil)
  :hook ((ghostel-mode . evil-ghostel-mode)
         (evil-ghostel-mode . mm/setup-ghostel-popup-double-escape-h))
  :config
  (evil-define-key* 'normal evil-ghostel-mode-map
    (kbd "l") #'mm/evil-ghostel-forward-or-accept))

;; Use Doom's popup manager so this behaves like Doom's former vterm popup,
;; rather than a regular side-window split.
(set-popup-rule! "^\\*doom:ghostel-popup:"
  :size 0.25 :vslot -4 :select t :quit nil :ttl nil)


(defun mm/disable-terminal-process-query ()
  "Do not prompt before closing terminal buffers created from this config."
  (when-let ((process (get-buffer-process (current-buffer))))
    (set-process-query-on-exit-flag process nil)))

(defun mm/terminal-buffer-p (&optional buffer)
  "Return non-nil when BUFFER is a terminal-like buffer."
  (with-current-buffer (or buffer (current-buffer))
    (derived-mode-p 'ghostel-mode 'term-mode 'shell-mode 'eshell-mode)))


(defun mm/ghostel-popup-buffer-name ()
  "Return the Ghostel popup buffer name for the current workspace."
  (format "*doom:ghostel-popup:%s*"
          (if (bound-and-true-p persp-mode)
              (safe-persp-name (get-current-persp))
            "main")))


(defun mm/toggle-bottom-terminal ()
  "Toggle the Doom-managed Ghostel popup for the current workspace."
  (interactive)
  (let* ((buffer-name (mm/ghostel-popup-buffer-name))
         (buffer (get-buffer buffer-name))
         (window (and buffer (get-buffer-window buffer))))
    (if window
        (delete-window window)
      (let ((ghostel-buffer-name buffer-name))
        (ghostel)))))


(defvar-local mm/ghostel-follow-timer nil
  "Idle timer that keeps pumping Ghostel output after programmatic sends.")

(defun mm/ghostel-follow-tick (buffer deadline)
  "Drain and redraw Ghostel BUFFER until DEADLINE.

This is a named timer function rather than a closure because Doom tangles this
configuration without lexical binding enabled."
  (if (and (buffer-live-p buffer)
           (< (float-time) deadline))
      (with-current-buffer buffer
        (when (and (derived-mode-p 'ghostel-mode)
                   (bound-and-true-p ghostel--process)
                   (process-live-p ghostel--process))
          (accept-process-output ghostel--process 0.01 nil t)
          (when (fboundp 'ghostel--redraw-now)
            (ghostel--redraw-now buffer))))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when (timerp mm/ghostel-follow-timer)
          (cancel-timer mm/ghostel-follow-timer))
        (setq mm/ghostel-follow-timer nil)))))

(defun mm/ghostel-ensure-ready (&optional timeout)
  "Wait briefly for the current Ghostel PTY to become ready."
  (let ((deadline (+ (float-time) (or timeout 1.0))))
    (while (and (not (and (bound-and-true-p ghostel--process)
                          (process-live-p ghostel--process)
                          (bound-and-true-p ghostel--term)))
                (< (float-time) deadline))
      (accept-process-output nil 0.05))))

(defun mm/ghostel-flush-output (&optional seconds)
  "Drain Ghostel PTY output and force a redraw for SECONDS (default 0.25)."
  (when (and (derived-mode-p 'ghostel-mode)
             (bound-and-true-p ghostel--process)
             (process-live-p ghostel--process))
    (let ((deadline (+ (float-time) (or seconds 0.25))))
      (while (< (float-time) deadline)
        (accept-process-output ghostel--process 0.05 nil t))
      (when (fboundp 'ghostel--redraw-now)
        (ghostel--redraw-now (current-buffer) t))
      (when (and (fboundp 'ghostel--anchor-window)
                 (window-live-p (selected-window)))
        (ghostel--anchor-window (selected-window) t))
      (redisplay t))))

(defun mm/ghostel-start-follow (&optional seconds)
  "Keep draining/redrawing the current Ghostel buffer for SECONDS."
  (when mm/ghostel-follow-timer
    (cancel-timer mm/ghostel-follow-timer)
    (setq mm/ghostel-follow-timer nil))
  (let ((buffer (current-buffer))
        (deadline (+ (float-time) (or seconds 8.0))))
    (setq mm/ghostel-follow-timer
          (run-with-timer 0.05 0.1 #'mm/ghostel-follow-tick buffer deadline))))

(defun mm/send-command-to-current-terminal (command)
  "Send COMMAND to the current terminal buffer."
  (cond
   ((derived-mode-p 'ghostel-mode)
    ;; Ghostel is a real PTY: shells expect CR to submit a line, not LF.
    ;; Also force follow/redraw so programmatic sends paint immediately,
    ;; even when Evil is in normal state.
    (mm/ghostel-ensure-ready)
    (when (and (bound-and-true-p evil-local-mode)
               (not (memq evil-state '(insert emacs))))
      (evil-insert-state))
    (when (and (fboundp 'ghostel--anchor-window)
               (window-live-p (selected-window)))
      (ghostel--anchor-window (selected-window) t))
    (ghostel-send-string (concat command "\r"))
    (mm/ghostel-flush-output)
    (mm/ghostel-start-follow)
    t)
   ((derived-mode-p 'term-mode)
    (term-send-raw-string (concat command "\n"))
    t)
   ((derived-mode-p 'shell-mode)
    (goto-char (point-max))
    (insert command)
    (comint-send-input)
    t)
   ((derived-mode-p 'eshell-mode)
    (goto-char (point-max))
    (insert command)
    (eshell-send-input)
    t)))


(defun mm/run-shell-command-in-bottom-window (command directory)
  "Run COMMAND in DIRECTORY in a bottom shell-like window."
  (cond
   ((mm/terminal-buffer-p)
    (mm/send-command-to-current-terminal command))
   (t
    (let ((default-directory directory))
      (let ((ghostel-buffer-name (generate-new-buffer-name "*ghostel*")))
        (ghostel)
        (with-current-buffer (current-buffer)
          (mm/send-command-to-current-terminal command)))))))

(defun mm/run-command-in-full-terminal (command directory)
  "Run COMMAND in a fresh full-window Ghostel buffer at DIRECTORY."
  (let ((default-directory directory)
        (ghostel-buffer-name (generate-new-buffer-name "*mise-run*")))
    (ghostel)
    (with-current-buffer (current-buffer)
      (mm/send-command-to-current-terminal command))))

;; `SPC o t` toggles the Ghostel popup; `SPC o T` opens Ghostel in a new frame.

(after! flycheck
  (remove-hook 'flycheck-mode-hook #'+syntax-init-popups-h)
  (setq flycheck-display-errors-function #'flycheck-display-error-messages))

(use-package! flyover
  :hook ((flycheck-mode . flyover-mode)
         (flymake-mode . flyover-mode))
  :config
  (setq flyover-checkers '(flycheck flymake)
        flyover-levels '(error warning info)
        flyover-use-theme-colors t
        flyover-background-lightness 20
        flyover-text-tint 'lighter
        flyover-text-tint-percent 15
        flyover-icon-tint 'lighter
        flyover-icon-tint-percent 15
        flyover-icon-background-tint 'darker
        flyover-icon-background-tint-percent 30
        flyover-show-icon nil
        flyover-error-icon ""
        flyover-warning-icon ""
        flyover-info-icon ""
        flyover-border-style 'none
        flyover-virtual-line-type nil
        flyover-hide-checker-name t
        flyover-show-at-eol t
        flyover-line-position-offset 0
        ;; Keep inline diagnostics on their source line; text beyond the
        ;; window edge is clipped instead of creating continuation lines.
        flyover-wrap-messages nil
        flyover-max-line-length 100
        flyover-display-mode 'always
        flyover-hide-during-completion t
        flyover-debounce-interval 0.2
        flyover-cursor-debounce-interval 0.3)

  (defun mm/flyover-keep-cursor-before-eol-a (text)
    "Keep point visually before Flyover's end-of-line annotation."
    (when (and flyover-show-at-eol (not (string-empty-p text)))
      (put-text-property 0 1 'cursor t text))
    text)

  (defun mm/flyover-available-columns (overlay window)
    "Return columns available after OVERLAY in WINDOW's current visual line."
    ;; `posn-at-point' can report a position after a long after-string, so hide
    ;; the annotation while measuring the source position.
    (let ((after-string (overlay-get overlay 'after-string)))
      (unwind-protect
          (progn
            (overlay-put overlay 'after-string nil)
            (when-let* ((posn (posn-at-point (overlay-start overlay) window))
                        (xy (posn-x-y posn)))
              ;; Reserve a column so a glyph touching the right edge cannot
              ;; create a continuation line because of pixel rounding.
              (max 0 (/ (max 0 (- (window-body-width window t)
                                  (car xy)
                                  (window-font-width window)))
                        (window-font-width window)))))
        (overlay-put overlay 'after-string after-string))))

  (defun mm/flyover-clip-eol-overlay (overlay)
    "Clip OVERLAY's annotation before it can wrap onto another visual line."
    (when (and flyover-show-at-eol
               (overlayp overlay)
               (overlay-buffer overlay)
               (overlay-get overlay 'after-string))
      (let* ((full-text (or (overlay-get overlay 'mm/flyover-full-text)
                            (overlay-get overlay 'after-string)))
             (windows (get-buffer-window-list (overlay-buffer overlay) nil t))
             (widths (delq nil
                           (mapcar (lambda (window)
                                     (mm/flyover-available-columns overlay window))
                                   windows))))
        (overlay-put overlay 'mm/flyover-full-text full-text)
        (when widths
          ;; An overlay has one after-string even when its buffer is visible in
          ;; several windows, so fit it to the narrowest visible occurrence.
          (let ((width (apply #'min widths)))
            (overlay-put overlay 'after-string
                         (if (zerop width)
                             ""
                           (truncate-string-to-width
                            full-text width nil nil "…"))))))))

  (defun mm/flyover-clip-new-overlay-a (overlay &rest _)
    "Clip a newly configured Flyover OVERLAY."
    (mm/flyover-clip-eol-overlay overlay))

  (defun mm/flyover-reclip-window-overlays (window &rest _)
    "Reclip Flyover annotations displayed in WINDOW."
    (when (window-live-p window)
      (with-current-buffer (window-buffer window)
        (when (bound-and-true-p flyover-mode)
          (dolist (overlay flyover--overlays)
            (mm/flyover-clip-eol-overlay overlay))))))

  (defun mm/flyover-reclip-frame-overlays (frame)
    "Reclip Flyover annotations after windows in FRAME change size."
    (dolist (window (window-list frame 'no-minibuffer))
      (mm/flyover-reclip-window-overlays window)))

  (advice-remove #'flyover--build-final-overlay-string
                 #'mm/flyover-keep-cursor-before-eol-a)
  (advice-add #'flyover--build-final-overlay-string :filter-return
              #'mm/flyover-keep-cursor-before-eol-a)
  (advice-remove #'flyover--configure-overlay
                 #'mm/flyover-clip-new-overlay-a)
  (advice-add #'flyover--configure-overlay :after
              #'mm/flyover-clip-new-overlay-a)
  (add-hook 'window-scroll-functions #'mm/flyover-reclip-window-overlays)
  (add-hook 'window-size-change-functions #'mm/flyover-reclip-frame-overlays))

(let ((paths (seq-filter (lambda (path)
                           (not (or (string-prefix-p "/nix/" path)
                                    (string-prefix-p (expand-file-name "~/.nix-profile/") path)
                                    ;; A retired standalone Zig install left this
                                    ;; directory on the GUI launch PATH.  It must
                                    ;; not shadow mise's `zig' shim.
                                    (string= path "/usr/local/bin/zig"))))
                         (split-string (or (getenv "PATH") "") path-separator t))))
  (setenv "PATH" (string-join paths path-separator))
  (setq exec-path (append paths (list exec-directory))))
(dolist (path '("~/.local/share/mise/shims" "/opt/homebrew/bin" "~/.cargo/bin" "~/.local/bin" "~/.bun/bin"))
  (let ((expanded-path (expand-file-name path)))
    (when (file-directory-p expanded-path)
      (add-to-list 'exec-path expanded-path)
      (setenv "PATH" (concat expanded-path ":" (getenv "PATH"))))))

;; The graphical login session may outlive a Nix removal.  Do not inherit its
;; deleted shell path when Emacs starts processes.
(setenv "SHELL" "/opt/homebrew/bin/fish")
(setq shell-file-name "/opt/homebrew/bin/fish"
      explicit-shell-file-name "/opt/homebrew/bin/fish")

(defun mm/prune-deleted-nix-workspace-buffers ()
  "Discard unmodified workspace buffers for Nix files removed during migration."
  (dolist (buffer (buffer-list))
    (when-let ((file (buffer-file-name buffer)))
      (when (and (string-match-p
                  (rx (or "/.config/home-manager/"
                          "/.config/nix/"
                          "/flake.nix" "/flake.lock" "/shell.nix" "/default.nix"))
                  file)
                 (not (file-exists-p file))
                 (not (buffer-modified-p buffer)))
        (kill-buffer buffer)))))

(add-hook 'emacs-startup-hook
          (lambda () (run-at-time 1 nil #'mm/prune-deleted-nix-workspace-buffers)))

(after! project
  (defun mm/project-try-cargo (dir)
    (when-let ((root (locate-dominating-file dir "Cargo.toml")))
      (cons 'mm/cargo root)))

  (cl-defmethod project-root ((project (head mm/cargo)))
    (cdr project))

  ;; Projectile's project type is a cons cell in this Doom/Emacs pairing.
  ;; Teach project.el (and Marginalia) how to obtain its root.
  (cl-defmethod project-root ((project (head projectile)))
    (cdr project))

  (add-hook 'project-find-functions #'mm/project-try-cargo))


(defun mm/project-find-file ()
  "Find a file case-insensitively in this or any known project."
  (interactive)
  (when (fboundp 'projectile-invalidate-cache)
    (projectile-invalidate-cache nil))
  (let ((completion-ignore-case t)
        (read-file-name-completion-ignore-case t)
        ;; Disable smart-case here so even uppercase input stays insensitive.
        (orderless-smart-case nil))
    (mm/with-evil-minibuffer-nav
     (if (projectile-project-p)
         #'projectile-find-file
       (progn
         (unless (projectile-known-projects)
           (projectile-discover-projects-in-search-path)
           (projectile-save-known-projects))
         #'projectile-find-file-in-known-projects)))))


(after! projectile
  (setq projectile-project-search-path '(("~/dev" . 1)
                                         ("~/dev" . 2)
                                         ("~/dev" . 3)
                                         ("~/dev" . 4))
        projectile-auto-discover t)
  (add-to-list 'projectile-globally-ignored-directories "zig-pkg")
  (add-to-list 'projectile-globally-ignored-directories ".zig-cache")
  (run-with-idle-timer
   2 nil
   (lambda ()
     (when (file-accessible-directory-p "~/dev")
       (projectile-discover-projects-in-search-path)
       (projectile-save-known-projects)))))

(setq rustic-lsp-client 'eglot
      rustic-lsp-server 'rust-analyzer
      rustic-lsp-check-command "check")


(defun mm/rust-organize-imports ()
  "Organize Rust imports with rust-analyzer before saving."
  (when (and (derived-mode-p 'rust-mode 'rustic-mode 'rust-ts-mode)
             (bound-and-true-p eglot--managed-mode))
    (eglot-code-actions nil nil "source.organizeImports" t)))


(defun mm/rust-eglot-start-h ()
  "Start rust-analyzer through Eglot for Rust buffers."
  (when buffer-file-name
    (run-at-time
     0.1 nil
     (lambda (buffer)
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (when (derived-mode-p 'rustic-mode 'rust-mode 'rust-ts-mode)
             (require 'eglot)
             (condition-case err
                 ;; `eglot-ensure' is idempotent: it no-ops if a server is
                 ;; already managing this buffer, so it can't race with Doom's
                 ;; own `rustic-setup-lsp'. (The old raw `(eglot ...)' call could
                 ;; open a second, conflicting connection.)
                 (unless (bound-and-true-p eglot--managed-mode)
                   (eglot-ensure))
               (error
                (message "Rust Eglot failed: %s" (error-message-string err))))))))
     (current-buffer))))

(defun mm/zig-tool-executable (tool)
  "Return a reliable executable path for Zig TOOL.

GUI Emacs does not always inherit mise's shell PATH.  Prefer the active PATH,
then fall back to the installed mise ZLS and Homebrew Zig locations."
  (or (executable-find tool)
      (seq-find #'file-executable-p
                (pcase tool
                  ("zls" (file-expand-wildcards
                          "~/.local/share/mise/installs/zls/*/zls"))
                  ("zig" '("/opt/homebrew/bin/zig"))))))

(defconst mm/zig-zls-executable (mm/zig-tool-executable "zls"))
(defconst mm/zig-executable (mm/zig-tool-executable "zig"))

(defun mm/zig-eglot-start-h ()
  "Start one ZLS instance for the current Zig project."
  (when (and buffer-file-name mm/zig-zls-executable)
    (require 'eglot)
    (unless (bound-and-true-p eglot--managed-mode)
      (eglot-ensure))))

(defun mm/zig-company-complete-after-trigger-h ()
  "Request ZLS completion after Zig's high-value trigger characters."
  (when (and (derived-mode-p 'zig-mode 'zig-ts-mode)
             (bound-and-true-p eglot--managed-mode)
             (memq last-command-event '(?. ?@ ?\")))
    (company-manual-begin)))

(defun mm/zig-build (step)
  "Run `zig build STEP' from the current project root."
  (interactive "sZig build step: ")
  (let* ((root (or (when-let ((project (project-current nil)))
                     (project-root project))
                   default-directory))
         (command (format "cd %s && %s build %s"
                          (shell-quote-argument root)
                          (shell-quote-argument (or mm/zig-executable "zig"))
                          (shell-quote-argument step))))
    (compilation-start command 'compilation-mode
                       (lambda (_) (format "*zig build %s*" step)))))

(defun mm/zig-build-check ()
  "Run the fast, non-linking Zig `check' build step."
  (interactive)
  (mm/zig-build "check"))

(defun mm/zig-build-test ()
  "Run the Zig `test' build step on demand."
  (interactive)
  (mm/zig-build "test"))

(add-hook! '(zig-mode-hook zig-ts-mode-hook)
  #'mm/zig-eglot-start-h
  (defun mm/zig-editor-speed-setup-h ()
    ;; Keep normal typing quiet; punctuation above requests completions instantly.
    (setq-local company-minimum-prefix-length 1
                ;; Match Neovim Blink's immediate keyword trigger.
                company-idle-delay 0
                company-backends '((company-capf :with company-dabbrev-code)))
    (add-hook 'post-self-insert-hook
              #'mm/zig-company-complete-after-trigger-h nil t)))

(after! eglot
  (add-to-list 'eglot-server-programs
               '((rust-mode rustic-mode rust-ts-mode) . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((conf-toml-mode toml-ts-mode) . ("taplo" "lsp" "stdio")))
  ;; Start Taplo as soon as a TOML buffer is visited.
  (add-hook 'conf-toml-mode-hook #'eglot-ensure)
  (add-hook 'toml-ts-mode-hook #'eglot-ensure)
  ;; Register both Zig major modes explicitly.  The absolute fallback makes
  ;; ZLS work from a GUI launch even when mise's shims are not in its PATH.
  (when mm/zig-zls-executable
    (dolist (mode '(zig-mode zig-ts-mode))
      (setf (alist-get mode eglot-server-programs)
            `(,mm/zig-zls-executable
              :initializationOptions (:zig_exe_path ,mm/zig-executable)))))
  (setq eglot-autoshutdown t)
  ;; Apply the global hint preference whenever Eglot starts managing a buffer.
   (add-hook 'eglot-managed-mode-hook #'mm/apply-global-lsp-inlay-hints-h)
  (setq-default eglot-workspace-configuration
                '(:gopls (:completeUnimported t)
                  ;; Let ZLS discover the project's `check' step.  It compiles
                  ;; without linking, and incremental compilation makes save
                  ;; diagnostics substantially cheaper than also running tests.
                  :zls (:build_on_save_args ["-fincremental"]
                        :semantic_tokens "partial")
                  :rust-analyzer
                  ( ;; Default features only. `:allFeatures t' forces
                    ;; rust-analyzer to analyze every feature of every crate,
                    ;; which balloons memory/CPU and is a top cause of stalls in
                    ;; large workspaces.
                   :cargo (:buildScripts (:enable t))
                   ;; `cargo check' (not clippy) on save, and only the current
                   ;; crate rather than the whole workspace. Full-workspace
                   ;; clippy-on-save is the main reason rust-analyzer appears to
                   ;; "freeze": it can't answer highlight/completion requests
                   ;; while the check runs. Use SPC r for clippy on demand.
                   :check (:command "check" :workspace :json-false)
                   :checkOnSave t
                   ;; Skip the up-front symbol-indexing pass that stalls the
                   ;; first several seconds after opening a big project.
                   :cachePriming (:enable :json-false)
                   ;; Don't scan/watch build artifacts.
                   :files (:exclude ["target" ".git"])))))

(defconst mm/mise-config-names '("mise.toml" ".mise.toml"))

(defun mm/mise-config-p (file)
  "Return non-nil when FILE is a Mise configuration."
  (and file
       (member (file-name-nondirectory file) mm/mise-config-names)
       (file-regular-p file)))

(defun mm/mise-config-in-directory-p (directory)
  "Return the Mise configuration path in DIRECTORY, or nil."
  (cl-some (lambda (name)
             (let ((path (expand-file-name name directory)))
               (and (file-regular-p path) path)))
           mm/mise-config-names))

(defun mm/current-session-directory ()
  "Return the active Doom workspace's project root, when available.

Workspace restoration can leave buffers from another project visible briefly.
Mise tasks must follow the active workspace rather than whichever buffer was
selected during that transition."
  (when-let* ((workspace (and (fboundp '+workspace-current)
                              (+workspace-current))))
    (or (persp-parameter '+workspace-project workspace)
        (persp-parameter 'last-project-root workspace))))

(defun mm/mise-root (&optional start)
  "Return the nearest directory containing a Mise configuration."
  (let* ((start (expand-file-name (or start (mm/current-buffer-directory))))
         (candidates (cl-delete-duplicates
                      (delq nil
                            (list (mm/current-session-directory)
                                  start
                                  default-directory
                                  (when (fboundp 'doom-project-root)
                                    (ignore-errors (doom-project-root)))
                                  (when (fboundp 'projectile-project-root)
                                    (ignore-errors (projectile-project-root)))
                                  (when (fboundp 'project-current)
                                    (when-let ((project (project-current nil start)))
                                      (project-root project)))
                                  (ignore-errors
                                    (locate-dominating-file start ".git"))))
                      :test (lambda (a b)
                              (string-equal (expand-file-name a)
                                            (expand-file-name b)))))
         (root (cl-some (lambda (candidate)
                          (locate-dominating-file candidate #'mm/mise-config-in-directory-p))
                        candidates)))
    (or root
        (user-error "No mise.toml found above %s" start))))

(defun mm/mise-config-path (&optional start)
  "Return the nearest Mise configuration path."
  (when-let ((root (ignore-errors (mm/mise-root start))))
    (mm/mise-config-in-directory-p root)))

(defun mm/mise--call (directory &rest args)
  "Run `mise' ARGS in DIRECTORY and return (EXIT-CODE . OUTPUT)."
  (let* ((directory (expand-file-name directory))
         (default-directory directory)
         (buffer (generate-new-buffer " *mm-mise*"))
         (destination (list buffer null-device))
         exit-code)
    (unwind-protect
        (progn
          (setq exit-code
                (cond
                 ((executable-find "mise")
                  (apply #'call-process "mise" nil destination nil args))
                 (t
                  (user-error "The `mise' executable is not available on Emacs's PATH"))))
          (cons exit-code
                (with-current-buffer buffer (buffer-string))))
      (kill-buffer buffer))))

(defun mm/mise-tasks (&optional directory)
  "Return Mise task names for DIRECTORY (or `mm/mise-root')."
  (let* ((directory (expand-file-name (or directory (mm/mise-root))))
         (result (mm/mise--call directory "tasks" "ls" "--name-only"))
         (exit-code (car result))
         (output (string-trim (cdr result)))
         (tasks (and (zerop exit-code) (split-string output "\n" t))))
    (unless (zerop exit-code)
      (user-error "Failed to list Mise tasks in %s%s"
                  directory
                  (if (string-empty-p output) "" (concat ":\n" output))))
    (or tasks
        (user-error "No Mise tasks found in %s" directory))))

(defun mm/mise-select ()
  "Pick a Mise task with completion and run it in a terminal."
  (interactive)
  (let* ((directory (mm/mise-root))
         (task (completing-read "Mise task: "
                                  (mm/mise-tasks directory)
                                  nil t)))
    (mm/mise task directory t)))

(defun mm/mise (task directory &optional popup close-on-exit)
  "Run Mise TASK in DIRECTORY.

When POPUP is non-nil, use the Ghostel popup.  When CLOSE-ON-EXIT is non-nil,
close that popup after the recipe exits."
  (unless (executable-find "mise")
    (user-error "The `mise' executable is not available on Emacs's PATH"))
  (let ((command (format "mise run %s" (shell-quote-argument task))))
    (cond
     ;; `run' is interactive: use a dedicated full-window terminal.
     ;; All other tasks retain their existing popup flow.
     ((string= task "run")
      (mm/run-command-in-full-terminal command directory))
     ((and popup close-on-exit)
      (mm/run-program-in-popup-terminal command directory))
     (popup
      (mm/run-command-in-popup-terminal command directory))
     (t
      (mm/run-shell-command-in-bottom-window command directory)))))

(after! dape
  (add-to-list 'dape-configs
               `(codelldb
                 modes (rust-mode rust-ts-mode rustic-mode)
                 ensure dape-ensure-command
                 command ,(expand-file-name "~/.config/doom/debug-adapters/codelldb/adapter/codelldb")
                 command-args ("--port" :autoport)
                 :type "lldb"
                 :request "launch"
                 :cwd dape-cwd
                 :program dape-buffer-default)))

(after! hl-todo
  (setq hl-todo-keyword-faces
        '(("FIX" mm/comment-error-keyword bold)
          ("FIXME" mm/comment-error-keyword bold)
          ("BUG" mm/comment-error-keyword bold)
          ("FIXIT" mm/comment-error-keyword bold)
          ("ISSUE" mm/comment-error-keyword bold)
          ("TODO" mm/comment-todo-keyword bold)
          ("UNIMPLEMENTED" mm/comment-todo-keyword bold)
          ("HACK" mm/comment-warning-keyword bold)
          ("WARN" mm/comment-warning-keyword bold)
          ("WARNING" mm/comment-warning-keyword bold)
          ("XXX" mm/comment-warning-keyword bold)
          ("PERF" mm/comment-perf-keyword bold)
          ("OPTIM" mm/comment-perf-keyword bold)
          ("PERFORMANCE" mm/comment-perf-keyword bold)
          ("OPTIMIZE" mm/comment-perf-keyword bold)
          ("NOTE" mm/comment-note-keyword bold)
          ("INFO" mm/comment-info-keyword bold)
          ("TEST" mm/comment-test-keyword bold)
          ("TESTING" mm/comment-test-keyword bold)
          ("PASSED" mm/comment-test-keyword bold)
          ("FAILED" mm/comment-test-keyword bold))
        hl-todo-exclude-modes (delq 'org-mode hl-todo-exclude-modes))
  (when global-hl-todo-mode
    (global-hl-todo-mode -1)
    (global-hl-todo-mode 1)))

(setq org-directory "~/dev/org/")

(defun mm/archive-done-org-tasks-on-save ()
  "Archive completed non-recurring tasks when saving the main todo.org file."
  (when (and buffer-file-name
             (string= (file-truename buffer-file-name)
                      (file-truename (expand-file-name "todo.org" org-directory))))
    (let ((script (expand-file-name "scripts/archive-done-org-tasks" doom-user-dir)))
      (when (file-executable-p script)
        (let ((exit-code (call-process script nil "*Archive Done Org Tasks*" t
                                       (expand-file-name org-directory))))
          (if (zerop exit-code)
              (progn
                (revert-buffer :ignore-auto :noconfirm)
                (message "Archived completed non-recurring tasks from todo.org"))
            (message "Done task archive failed; see *Archive Done Org Tasks*")))))))


(add-hook 'after-save-hook #'mm/archive-done-org-tasks-on-save)

(defun mm/open-daily-org ()
  "Open today's daily Org note."
  (interactive)
  (let* ((daily-dir (expand-file-name "daily/" org-directory))
         (file (expand-file-name (format-time-string "%Y-%m-%d.org") daily-dir)))
    (make-directory daily-dir t)
    (find-file file)
    (when (= (buffer-size) 0)
      (insert "#+title: " (format-time-string "%A, %B %e, %Y") "\n\n"
              "* What I did\n"
              "* TODO \n\n"
              "* Notes\n\n"))))

(defun mm/find-org-note ()
  "Find an Org note under `org-directory'."
  (interactive)
  (let ((default-directory (expand-file-name org-directory)))
    (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
      (let ((file (completing-read "Org note: "
                                   (directory-files-recursively default-directory "\\.org\\'")
                                   nil t)))
        (find-file file)))))

(defun mm/grep-org-notes ()
  "Live grep Org notes under `org-directory'."
  (interactive)
  (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
    (consult-ripgrep org-directory nil)))

(defvar-local mm/org--last-fontified-window-start nil
  "Last Org window start handled by `mm/org-fontify-visible-after-jump-h'.")

(defun mm/org-fontify-visible-after-jump-h ()
  "Fontify the visible part of an Org buffer after a jump or scroll.

Org's JIT fontifier can reach a distant location before it has seen the
opening line of a source block.  That leaves the block unfontified until it is
visited line by line.  Start at the enclosing block header when there is one,
so Doom's `org-modern' display and native source highlighting appear as soon
as the location is shown."
  (when (and (derived-mode-p 'org-mode)
             (eq (window-buffer (selected-window)) (current-buffer)))
    (let ((window-start (window-start)))
      (unless (equal window-start mm/org--last-fontified-window-start)
        (setq mm/org--last-fontified-window-start window-start)
        (save-excursion
          (goto-char window-start)
          (font-lock-ensure
           (or (org-babel-where-is-src-block-head) window-start)
           (window-end nil t)))))))

(defun mm/org-enable-visible-jit-fontification-h ()
  "Enable jump-aware fontification in the current Org buffer."
  (add-hook 'post-command-hook #'mm/org-fontify-visible-after-jump-h nil t))

(after! org
  ;; Apply the targeted JIT-fontification repair only in Org buffers; it does
  ;; not alter font-lock behavior in other Doom modes.
  (add-hook 'org-mode-hook #'mm/org-enable-visible-jit-fontification-h)
  (setq org-agenda-files (directory-files-recursively (expand-file-name org-directory) "\\.org$")
        org-agenda-show-all-dates nil
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-timestamp-if-done t
        org-agenda-prefix-format
        '((agenda . " %i %-12:c%?-12t% s")
          (todo . " %i %-12:c")
          (tags . " %i %-12:c")
          (search . " %i %-12:c"))
        org-agenda-custom-commands
        '(("a" "Agenda"
           ((agenda ""
                    ((org-super-agenda-groups nil)
                     (org-agenda-sorting-strategy
                      '(time-up priority-down category-keep))))
            (todo "TODO"
                  ((org-agenda-overriding-header "Backlog")
                   (org-super-agenda-groups nil)
                   (org-agenda-sorting-strategy
                    '(priority-down category-keep))
                   (org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline)))))))
        org-log-done 'time
        org-clock-persist t
        org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAIT(w)" "|" "DONE(d!)" "CANCELLED(c@)"))
        org-capture-templates
        `(("t" "Todo" entry
           (file+headline ,(expand-file-name "todo.org" org-directory) "Inbox")
           "* TODO %?\n  %U\n")
          ("n" "Note" entry
           (file+headline ,(expand-file-name "notes.org" org-directory) "Notes")
           "* %?\n  %U\n")
          ("d" "Daily note" entry
          (file+olp+datetree ,(expand-file-name "daily-log.org" org-directory))
           "* %?\n  %U\n")))
  (map! :map org-mode-map
        :n "gx" #'org-open-at-point
        :n "gh" #'evil-first-non-blank
        :n "gl" #'evil-end-of-line)
  (org-clock-persistence-insinuate))

(after! evil-org
  ;; `evil-org-mode' is a minor mode, so its state maps outrank both Evil's
  ;; defaults and `org-mode-map'.  Use the starred form to replace its
  ;; `org-up-element'/`org-down-element' bindings rather than being overwritten
  ;; when Evil Org initializes its auxiliary maps.
  (evil-define-key* '(normal motion) evil-org-mode-map
    (kbd "g h") #'evil-first-non-blank
    (kbd "g l") #'evil-end-of-line))

(use-package! org-super-agenda
  :after org-agenda
  :config
  (org-super-agenda-mode)
  (setq org-super-agenda-groups
        '((:name "Today" :time-grid t :scheduled today)
          (:name "Next" :todo "NEXT")
          (:name "Due soon" :deadline future)
          (:name "Overdue" :deadline past)
          (:name "Waiting" :todo "WAIT"))))

(defun mm/org-agenda-line-next (&optional count)
  "Move down COUNT physical lines in agenda buffers without agenda side effects."
  (interactive "p")
  (forward-line (or count 1))
  (back-to-indentation))

(defun mm/org-agenda-line-previous (&optional count)
  "Move up COUNT physical lines in agenda buffers without agenda side effects."
  (interactive "p")
  (forward-line (- (or count 1)))
  (back-to-indentation))

(defun mm/org-project-names ()
  "Return known PROJECT property values from agenda files."
  (delete-dups
   (delq nil
         (org-map-entries
          (lambda ()
            (when-let ((project (org-entry-get nil "PROJECT")))
              (unless (string-empty-p project)
                project)))
          nil
          'agenda))))

(defun mm/org-agenda-marker-at-line ()
  "Return the Org marker for the current agenda line, if any."
  (let ((pos (line-beginning-position))
        (end (line-end-position))
        marker)
    (while (and (< pos end) (not marker))
      (setq marker (or (get-text-property pos 'org-hd-marker)
                       (get-text-property pos 'org-marker))
            pos (next-property-change pos nil end)))
    marker))

(defun mm/org-agenda-project-at-line ()
  "Return the PROJECT property for the current agenda line, if any."
  (when-let ((marker (mm/org-agenda-marker-at-line)))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (org-entry-get nil "PROJECT" t)))))

(defface mm/org-agenda-calendar-personal
  '((t (:foreground "#d7ecff" :background "#1f3a52" :weight semi-bold :extend t)))
  "Face for personal calendar events in Org Agenda.")

(defface mm/org-agenda-calendar-teamworks
  '((t (:foreground "#fff0c2" :background "#4a3a16" :weight semi-bold :extend t)))
  "Face for Teamworks calendar events in Org Agenda.")

(defface mm/org-agenda-calendar-pg
  '((t (:foreground "#f2dcff" :background "#3d2a4f" :weight semi-bold :extend t)))
  "Face for P&G calendar events in Org Agenda.")

(defface mm/org-agenda-calendar-household
  '((t (:foreground "#ffdede" :background "#4f2626" :weight semi-bold :extend t)))
  "Face for Household events in Org Agenda.")

(defun mm/org-agenda-calendar-at-line ()
  "Return the CALENDAR property for the current agenda line, if any."
  (when-let ((marker (mm/org-agenda-marker-at-line)))
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char marker)
        (org-entry-get nil "CALENDAR" t)))))

(defun mm/org-agenda-calendar-face (calendar)
  "Return the agenda face for CALENDAR."
  (pcase calendar
    ("memohnsen@gmail.com" 'mm/org-agenda-calendar-personal)
    ("Teamworks H2F" 'mm/org-agenda-calendar-teamworks)
    ("P&G" 'mm/org-agenda-calendar-pg)
    ("Home" 'mm/org-agenda-calendar-household)
    (_ 'org-agenda-calendar-event)))

(defun mm/org-agenda-color-calendar-events ()
  "Color agenda lines generated from the synced macOS calendar."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when-let* ((calendar (mm/org-agenda-calendar-at-line))
                    (face (mm/org-agenda-calendar-face calendar)))
          (add-face-text-property (line-beginning-position)
                                  (line-end-position)
                                  face
                                  t)
          (end-of-line)
          (insert " " (propertize (format "[%s]" calendar) 'face face)))
        (forward-line 1)))))

(defun mm/org-agenda-space-between-days ()
  "Insert extra vertical space before each agenda day header."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when (and (get-text-property (line-beginning-position) 'org-agenda-date-header)
                   (not (bobp)))
          (beginning-of-line)
          (unless (save-excursion
                    (forward-line -2)
                    (looking-at-p "\\s-*$"))
            (insert "\n")))
        (forward-line 1)))))

(defun mm/org-agenda-align-projects ()
  "Display agenda PROJECT values in a right-aligned column."
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when-let ((project (mm/org-agenda-project-at-line)))
        (let* ((label (format "[%s]" project))
               (label (if (> (length label) 28)
                          (concat (substring label 0 27) "]")
                        label)))
          (end-of-line)
          (insert
           (propertize
            " "
            'display `(space :align-to (- right ,(1+ (length label)))))
           (propertize label 'face 'org-tag))))
      (forward-line 1))))

(defun mm/org-agenda-set-priority ()
  "Set the priority for the agenda item at point."
  (interactive)
  (let* ((choice (completing-read "Priority: " '("A" "B" "C" "none") nil t))
         (priority (if (string= choice "none") ?\s (string-to-char choice))))
    (org-agenda-priority priority)))

(defun mm/org-agenda-set-project ()
  "Set or clear the PROJECT property for the agenda item at point."
  (interactive)
  (let ((project (string-trim
                  (completing-read "Project (empty clears): "
                                   (mm/org-project-names)))))
    (org-agenda-with-point-at-orig-entry nil
      (if (string-empty-p project)
          (org-delete-property "PROJECT")
        (org-entry-put nil "PROJECT" project)))
    (org-agenda-redo)
    (if (string-empty-p project)
        (message "Cleared project")
      (message "Project: %s" project))))

(defun mm/org-calendar-select ()
  "Select the date at point while Org is reading a date from Calendar."
  (interactive)
  (if (fboundp 'org-calendar-select)
      (org-calendar-select)
    (if-let ((date (calendar-cursor-to-date))
             (minibuffer-window (active-minibuffer-window)))
        (let* ((time (org-encode-time 0 0 0 (nth 1 date) (nth 0 date) (nth 2 date)))
               (date-string (format-time-string "%Y-%m-%d" time)))
          (setq org-ans1 date-string)
          (with-current-buffer (window-buffer minibuffer-window)
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert date-string)))
          (exit-minibuffer))
      (keyboard-quit))))

(after! calendar
  (define-key calendar-mode-map (kbd "h") #'calendar-backward-day)
  (define-key calendar-mode-map (kbd "j") #'calendar-forward-week)
  (define-key calendar-mode-map (kbd "k") #'calendar-backward-week)
  (define-key calendar-mode-map (kbd "l") #'calendar-forward-day)
  (define-key calendar-mode-map (kbd "H") #'calendar-backward-month)
  (define-key calendar-mode-map (kbd "L") #'calendar-forward-month)
  (define-key calendar-mode-map (kbd "RET") #'mm/org-calendar-select)
  (define-key calendar-mode-map (kbd "<return>") #'mm/org-calendar-select)
  (after! evil
    (evil-define-key* '(normal motion) calendar-mode-map
      (kbd "h") #'calendar-backward-day
      (kbd "j") #'calendar-forward-week
      (kbd "k") #'calendar-backward-week
      (kbd "l") #'calendar-forward-day
      (kbd "H") #'calendar-backward-month
      (kbd "L") #'calendar-forward-month
      (kbd "RET") #'mm/org-calendar-select
      (kbd "<return>") #'mm/org-calendar-select)))

(defun mm/org-agenda-schedule-from-calendar (arg)
  "Schedule the agenda item at point, starting date selection in Calendar."
  (interactive "P")
  (let ((org-read-date-display-type 'calendar)
        (minibuffer-setup-hook (cons #'mm/select-calendar-window
                                     minibuffer-setup-hook)))
    (org-agenda-schedule arg)))

(defvar mm/org-agenda-view-keymap
  '(("j" . mm/org-agenda-line-next)
    ("k" . mm/org-agenda-line-previous)
    ("p" . mm/org-agenda-set-priority)
    ("P" . mm/org-agenda-set-project)
    ("s" . mm/org-agenda-schedule-from-calendar)
    ("d" . org-agenda-day-view)
    ("w" . org-agenda-week-view)
    ("m" . org-agenda-month-view)
    ("y" . org-agenda-year-view)
    ("." . org-agenda-goto-today)
    ("f" . org-agenda-later)
    ("b" . org-agenda-earlier))
  "Agenda bindings that should win over Org and Evil defaults.")

(defun mm/org-agenda-define-view-keys (keymap)
  "Install agenda view keys into KEYMAP."
  (dolist (binding mm/org-agenda-view-keymap)
    (define-key keymap (kbd (car binding)) (cdr binding))))

(defun mm/org-agenda-setup-view-keys ()
  "Apply agenda view keys after Org/Evil agenda modes initialize."
  (mm/org-agenda-define-view-keys org-agenda-mode-map)
  (when (boundp 'evil-org-agenda-mode-map)
    (mm/org-agenda-define-view-keys evil-org-agenda-mode-map))
  (when (boundp 'org-super-agenda-header-map)
    (mm/org-agenda-define-view-keys org-super-agenda-header-map))
  (when (fboundp 'evil-local-set-key)
    (dolist (binding mm/org-agenda-view-keymap)
      (evil-local-set-key 'motion (kbd (car binding)) (cdr binding))
      (evil-local-set-key 'normal (kbd (car binding)) (cdr binding)))))

(after! org-agenda
  (mm/org-agenda-define-view-keys org-agenda-mode-map)
  (add-hook 'org-agenda-finalize-hook #'mm/org-agenda-color-calendar-events)
  (add-hook 'org-agenda-finalize-hook #'mm/org-agenda-align-projects)
  (add-hook 'org-agenda-finalize-hook #'mm/org-agenda-space-between-days)
  (add-hook 'org-agenda-mode-hook #'mm/org-agenda-setup-view-keys))

(after! evil-org-agenda
  (mm/org-agenda-define-view-keys evil-org-agenda-mode-map))

(after! org-super-agenda
  (mm/org-agenda-define-view-keys org-super-agenda-header-map))

(after! persp-mode
  ;; Keep Doom's default: save workspace sessions, but do not reopen every saved
  ;; buffer during startup. Stale restored buffers can trip file mode detection.
  (setq persp-auto-resume-time -1)

(defun +workspace--message-body (message &optional type)
    "Show workspace messages without Doom's echo-area workspace tabline."
    (propertize (format "%s" message)
                'face (pcase type
                        ('error 'error)
                        ('warn 'warning)
                        ('success 'success)
                        ('info 'font-lock-comment-face))))

(defun +workspace/display ()
    "Do not show Doom's echo-area workspace tabline."
    (interactive)
    (message nil)))

(defun mm/next-error-cyclic ()
  "Jump to the next error, wrapping to the first if at the end."
  (interactive)
  (if (and (bound-and-true-p flycheck-mode) flycheck-current-errors)
      (condition-case nil
          (flycheck-next-error)
        (error (flycheck-next-error 1 t)))
    (if (bound-and-true-p flymake-mode)
        (let ((flymake-wrap-around t))
          (call-interactively #'flymake-goto-next-error))
      (condition-case nil
          (next-error)
        (error (next-error 1 t))))))

(defun mm/previous-error-cyclic ()
  "Jump to the previous error, wrapping to the last if at the beginning."
  (interactive)
  (if (and (bound-and-true-p flycheck-mode) flycheck-current-errors)
      (condition-case nil
          (flycheck-previous-error)
        (error (flycheck-next-error -1 t)))
    (if (bound-and-true-p flymake-mode)
        (let ((flymake-wrap-around t))
          (call-interactively #'flymake-goto-prev-error))
      (condition-case nil
          (previous-error)
        (error nil)))))

(after! evil
  ;; Keep these prefixes out of `global-map'; otherwise `[' and `]' stop being
  ;; self-inserting characters in Evil's insert state.
  (define-key evil-normal-state-map (kbd "]d") #'mm/next-error-cyclic)
  (define-key evil-normal-state-map (kbd "[d") #'mm/previous-error-cyclic))

(defun mm/workspace-new-from-project ()
  "Refresh projects, then create a workspace for the selected project."
  (interactive)
  (when (fboundp 'projectile-discover-projects-in-search-path)
    (projectile-discover-projects-in-search-path)
    (projectile-save-known-projects))
  (let* ((projects projectile-known-projects)
         (project-dir (completing-read "Project to open in new workspace: " projects nil t))
         (workspace-name (file-name-nondirectory (directory-file-name project-dir)))
         (kill-empty-main-p (mm/workspace-only-empty-main-p)))
    (when (and project-dir workspace-name)
      (+workspace-switch workspace-name t)
      (projectile-switch-project-by-name project-dir)
      (+workspace-save workspace-name)
      (mm/workspace-kill-empty-main-maybe kill-empty-main-p))))

(defun mm/workspace-switch-to ()
  "Switch workspace with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+workspace/switch-to))


(defun mm/saved-workspace-entry (name)
  "Return NAME's saved workspace form from Doom's workspace file."
  (let ((file (expand-file-name +workspaces-data-file persp-save-dir)))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (condition-case nil
            (cl-find name (read (current-buffer)) :key #'cadr :test #'equal)
          (error nil))))))

(defun mm/saved-workspace-project-root (name)
  "Return the saved project root for workspace NAME."
  (let* ((entry (mm/saved-workspace-entry name))
         (params (cadr (nth 4 entry))))
    (or (cdr (assq '+workspace-project params))
        (cdr (assq 'last-project-root params)))))

(defun mm/workspace-file-buffer-p (buffer)
  "Return non-nil when BUFFER is a live file buffer."
  (and (buffer-live-p buffer)
       (buffer-file-name buffer)))

(defun mm/workspace-only-empty-main-p ()
  "Return non-nil when the only workspace is empty `main'."
  (and (bound-and-true-p persp-mode)
       (equal (+workspace-list-names) '("main"))
       (equal (+workspace-current-name) "main")
       (not (cl-some #'mm/workspace-file-buffer-p
                     (+workspace-buffer-list (+workspace-current))))))

(defun mm/workspace-kill-empty-main-maybe (should-kill)
  "Kill the empty `main' workspace when SHOULD-KILL is non-nil."
  (when (and should-kill
             (+workspace-exists-p "main")
             (not (equal (+workspace-current-name) "main")))
    (+workspace/kill "main")))


(defun mm/workspace-revive-saved-buffers (name)
  "Put NAME back on its saved project and first real saved buffer."
  (when-let* ((persp (+workspace-get name t)))
    (let* ((project-root (mm/saved-workspace-project-root name))
           (existing-buffers (cl-remove-if-not
                              #'mm/workspace-file-buffer-p
                              (+workspace-buffer-list persp)))
           (saved-buffers
            (cl-loop for file in (mm/saved-workspace-buffer-files name)
                     collect (find-file-noselect file)))
           (buffers (or existing-buffers saved-buffers)))
      (when project-root
        (set-persp-parameter '+workspace-project project-root persp)
        (set-persp-parameter 'last-project-root project-root persp))
      (dolist (buffer saved-buffers)
        (persp-add-buffer buffer persp nil nil))
      (when-let* ((buffer (car buffers)))
        (switch-to-buffer buffer)))))

(defun mm/workspace-load (name)
  "Load closed workspace NAME and revive its saved file buffers."
  (interactive
   (let* ((saved-workspaces
           (persp-list-persp-names-in-file
            (expand-file-name +workspaces-data-file persp-save-dir)))
          (open-workspaces (+workspace-list-names))
          (closed-workspaces
           (cl-remove-if (lambda (workspace)
                           (member workspace open-workspaces))
                         saved-workspaces)))
     (unless closed-workspaces
       (user-error "No closed saved workspaces"))
     (list
      (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
        (completing-read "Load workspace: " closed-workspaces nil t)))))
  (let ((kill-empty-main-p (mm/workspace-only-empty-main-p)))
    (when (+workspace-load name)
      (+workspace/switch-to name)
      (mm/workspace-revive-saved-buffers name)
      (mm/workspace-kill-empty-main-maybe kill-empty-main-p)
      (+workspace/display))))

(defun mm/workspace-save-all-on-exit-h ()
  "Persist every open workspace before Emacs exits."
  (when (bound-and-true-p persp-mode)
    (dolist (name (+workspace-list-names))
      (condition-case err
          (+workspace-save name)
        (error
         (message "Could not auto-save workspace %s: %s"
                  name (error-message-string err)))))))

(add-hook 'kill-emacs-hook #'mm/workspace-save-all-on-exit-h -90)

(defun mm/workspace-kill (name)
  "Auto-save and close workspace NAME."
  (interactive
   (let ((current-name (+workspace-current-name)))
     (list
      (if current-prefix-arg
          (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
            (completing-read (format "Close workspace (default: %s): " current-name)
                             (+workspace-list-names)
                             nil nil nil nil current-name))
        current-name))))
  (+workspace-save name)
  (+workspace/kill name))

(defun mm/workspace-delete ()
  "Delete saved workspace with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+workspace/delete))

(defun mm/minibuffer-escape-to-normal ()
  "Use ESC in minibuffer to enter Evil normal state, never abort."
  (interactive)
  (when (and (fboundp 'evil-local-mode)
             (not (bound-and-true-p evil-local-mode)))
    (evil-local-mode 1))
  (when (fboundp 'evil-normal-state)
    (evil-normal-state)))

(defun mm/minibuffer-evil-nav-setup-h ()
  "Enable ESC->normal plus j/k navigation and q quit for minibuffer."
  (when (fboundp 'evil-local-mode)
    (evil-local-mode 1))
  ;; Override Doom's default physical Escape abort in minibuffers for this session.
  ;; Do not bind textual "ESC"/"C-[" here; Emacs uses that prefix to read Meta keys
  ;; such as M-RET, and making it non-prefix breaks Vertico's keymap setup.
  (local-set-key [escape] #'mm/minibuffer-escape-to-normal)
  (when (and (bound-and-true-p evil-local-mode)
             (fboundp 'evil-local-set-key))
    (evil-local-set-key 'insert [escape] #'mm/minibuffer-escape-to-normal)
    (if (and (fboundp 'vertico-next)
             (fboundp 'vertico-previous)
             (fboundp 'vertico-exit))
        (progn
          (evil-local-set-key 'normal (kbd "j") #'vertico-next)
          (evil-local-set-key 'normal (kbd "k") #'vertico-previous)
          (evil-local-set-key 'normal (kbd "RET") #'vertico-exit)
          (evil-local-set-key 'normal (kbd "<return>") #'vertico-exit))
      (progn
        (evil-local-set-key 'normal (kbd "j") #'next-line)
        (evil-local-set-key 'normal (kbd "k") #'previous-line)
        (evil-local-set-key 'normal (kbd "RET") #'exit-minibuffer)
        (evil-local-set-key 'normal (kbd "<return>") #'exit-minibuffer)))
    (evil-local-set-key 'normal (kbd "q") #'abort-recursive-edit)))

(defun mm/with-evil-minibuffer-nav (command)
  "Run COMMAND with minibuffer ESC->normal and j/k/q navigation enabled."
  (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
    (call-interactively command)))

(defvar mm/last-search-command nil
  "The most recently invoked command from the leader Search menu.")

(defvar mm/last-search-input nil
  "The final minibuffer input from the most recent leader Search command.")

(defun mm/record-search-command (command)
  "Record COMMAND so `mm/repeat-last-search' can invoke it again."
  (setq mm/last-search-command command))

(defun mm/save-search-input-h ()
  "Save the final contents of the search minibuffer before it closes."
  (setq mm/last-search-input (minibuffer-contents-no-properties)))

(defun mm/capture-search-input-h ()
  "Install a buffer-local hook to remember this search's input."
  (add-hook 'minibuffer-exit-hook #'mm/save-search-input-h nil t))

(defun mm/restore-search-input-h (input)
  "Replace the new search minibuffer contents with INPUT."
  (delete-minibuffer-contents)
  (insert input))

(defmacro mm/with-recorded-search (command &rest body)
  "Run BODY as COMMAND and remember its final minibuffer input."
  `(progn
     (mm/record-search-command ,command)
     (minibuffer-with-setup-hook #'mm/capture-search-input-h
       ,@body)))

(defun mm/repeat-last-search ()
  "Resume the most recently used leader Search command and its query."
  (interactive)
  (if mm/last-search-command
      (minibuffer-with-setup-hook
          (apply-partially #'mm/restore-search-input-h mm/last-search-input)
        (call-interactively mm/last-search-command))
    (user-error "No leader search has been run yet")))

(defun mm/search-buffer ()
  "Search current buffer with Evil minibuffer navigation."
  (interactive)
  (mm/with-recorded-search #'mm/search-buffer
    (mm/with-evil-minibuffer-nav #'+default/search-buffer)))

(defun mm/search-project-symbol-at-point ()
  "Search the project for the symbol at point."
  (interactive)
  (mm/with-recorded-search #'mm/search-project-symbol-at-point
    (mm/with-evil-minibuffer-nav #'+default/search-project-for-symbol-at-point)))

(defun mm/search-diagnostics ()
  "Search Flycheck diagnostics."
  (interactive)
  (mm/with-recorded-search #'mm/search-diagnostics
    (call-interactively #'consult-flycheck)))

(defun mm/search-all-open-buffers ()
  "Search all open buffers with Evil minibuffer navigation."
  (interactive)
  (if (fboundp 'consult-line-multi)
      (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
        (consult-line-multi 'all-buffers))
    (user-error "consult-line-multi is unavailable")))

(defun mm/search-cwd ()
  "Search current directory with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-cwd))

(defun mm/search-other-cwd ()
  "Search another directory with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-other-cwd))

(defun mm/search-emacsd ()
  "Search Doom Emacs config with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-emacsd))

(defconst mm/zig-search-excluded-globs
  '("--glob=!**/zig-pkg/**"
    "--glob=!**/.zig-cache/**")
  "Ripgrep globs excluded from every project search.")

(defun mm/vertico-add-zig-search-exclusions-a (arguments)
  "Add Zig dependency/cache exclusions to `+vertico-file-search' ARGUMENTS."
  (let ((extra-args (plist-get arguments :args)))
    (dolist (glob mm/zig-search-excluded-globs)
      (cl-pushnew glob extra-args :test #'equal))
    (plist-put arguments :args extra-args)))

(after! consult
  ;; Apply these at the ripgrep backend so every Consult-based search ignores
  ;; Zig dependency/cache trees, including project, symbol, TODO, and cwd search.
  (dolist (glob mm/zig-search-excluded-globs)
    (unless (string-match-p (regexp-quote glob) consult-ripgrep-args)
      (setq consult-ripgrep-args
            (concat consult-ripgrep-args " " glob))))
  ;; Doom's search wrapper dynamically replaces `consult-ripgrep-args', so
  ;; inject the same globs through its supported :args keyword as well.
  (advice-remove #'+vertico-file-search
                 #'mm/vertico-add-zig-search-exclusions-a)
  (advice-add #'+vertico-file-search :filter-args
              #'mm/vertico-add-zig-search-exclusions-a))

(defun mm/search-project ()
  "Search project, including hidden files, with Evil minibuffer navigation."
  (interactive)
  (mm/with-recorded-search #'mm/search-project
    (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
      (+default/search-project t))))

(defconst mm/todo-comments-ripgrep-pattern
  "\\b\\(?:FIX\\|FIXME\\|BUG\\|FIXIT\\|ISSUE\\|TODO\\|UNIMPLEMENTED\\|HACK\\|WARN\\|WARNING\\|XXX\\|PERF\\|OPTIM\\|PERFORMANCE\\|OPTIMIZE\\|NOTE\\|INFO\\|TEST\\|TESTING\\|PASSED\\|FAILED\\)[:!]"
  "Consult regexp matching Neovim todo-comments keywords and aliases.")

(defun mm/search-project-todos ()
  "Search the project for case-sensitive Neovim-style TODO markers."
  (interactive)
  (mm/with-recorded-search #'mm/search-project-todos
    (let ((project-root (or (doom-project-root)
                            (user-error "Not in a project")))
          (consult-ripgrep-args
           (concat consult-ripgrep-args " --case-sensitive")))
      (minibuffer-with-setup-hook #'mm/minibuffer-evil-nav-setup-h
        (consult-ripgrep project-root mm/todo-comments-ripgrep-pattern)))))

(defun mm/search-other-project ()
  "Search another project with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-other-project))

;; Save the current file with Command-s.


(defun mm/saved-workspace-buffer-files (name)
  "Return file paths saved in workspace NAME."
  (cl-loop for buffer in (nth 2 (mm/saved-workspace-entry name))
           for file = (nth 2 buffer)
           when (and (stringp file) (file-readable-p file))
           collect file))

;; Configure the macOS traffic-light titlebar to match the current theme.
(when (eq system-type 'darwin)
  (setq ns-use-proxy-icon nil
        frame-title-format nil))

(defun mm/tab-left ()
  "Move to the tab visually left of the current tab."
  (interactive)
  (if (fboundp 'centaur-tabs-backward-tab)
      (centaur-tabs-backward-tab)
    (previous-buffer)))


(defun mm/tab-right ()
  "Move to the tab visually right of the current tab."
  (interactive)
  (if (fboundp 'centaur-tabs-forward-tab)
      (centaur-tabs-forward-tab)
    (next-buffer)))

;; Open the project file explorer with `SPC e`, similar to LazyVim.


(map! :n "H" #'mm/tab-left)
(map! :n "L" #'mm/tab-right)

(require 'cl-lib)

(defface mm/comment-todo-keyword
  '((t (:foreground "#000000"
        :background "#5aa9ff"
        :weight bold
        :box (:line-width (1 . -1) :color "#5aa9ff"))))
  "Face for TODO keywords in code comments.")

(defface mm/comment-note-keyword
  '((t (:foreground "#000000"
        :background "#d787ff"
        :weight bold
        :box (:line-width (1 . -1) :color "#d787ff"))))
  "Face for NOTE keywords in code comments, matching Neovim's hint purple.")

(defface mm/comment-error-keyword
  '((t (:foreground "#000000" :background "#ff5f6d" :weight bold
        :box (:line-width (1 . -1) :color "#ff5f6d"))))
  "Face for fix and error markers in code comments.")

(defface mm/comment-warning-keyword
  '((t (:foreground "#000000" :background "#ffd866" :weight bold
        :box (:line-width (1 . -1) :color "#ffd866"))))
  "Face for warning markers in code comments.")

(defface mm/comment-perf-keyword
  '((t (:foreground "#000000" :background "#ff9f43" :weight bold
        :box (:line-width (1 . -1) :color "#ff9f43"))))
  "Face for performance markers in code comments.")

(defface mm/comment-info-keyword
  '((t (:foreground "#000000" :background "#56d4dd" :weight bold
        :box (:line-width (1 . -1) :color "#56d4dd"))))
  "Face for informational markers in code comments.")

(defface mm/comment-test-keyword
  '((t (:foreground "#000000" :background "#98e06c" :weight bold
        :box (:line-width (1 . -1) :color "#98e06c"))))
  "Face for test markers in code comments.")

(defface mm/comment-error-body '((t (:foreground "#ff5f6d")))
  "Face for text belonging to an error comment marker.")
(defface mm/comment-todo-body '((t (:foreground "#5aa9ff")))
  "Face for text belonging to a TODO comment marker.")
(defface mm/comment-warning-body '((t (:foreground "#ffd866")))
  "Face for text belonging to a warning comment marker.")
(defface mm/comment-perf-body '((t (:foreground "#ff9f43")))
  "Face for text belonging to a performance comment marker.")
(defface mm/comment-note-body '((t (:foreground "#d787ff")))
  "Face for text belonging to a NOTE comment marker.")
(defface mm/comment-info-body '((t (:foreground "#56d4dd")))
  "Face for text belonging to an INFO comment marker.")
(defface mm/comment-test-body '((t (:foreground "#98e06c")))
  "Face for text belonging to a test comment marker.")

(defconst mm/todo-comment-keyword-regexp
  "\\_<\\(FIX\\|FIXME\\|BUG\\|FIXIT\\|ISSUE\\|TODO\\|UNIMPLEMENTED\\|HACK\\|WARN\\|WARNING\\|XXX\\|PERF\\|OPTIM\\|PERFORMANCE\\|OPTIMIZE\\|NOTE\\|INFO\\|TEST\\|TESTING\\|PASSED\\|FAILED\\)\\_>[:!]"
  "Case-sensitive regexp for supported TODO-style comment markers.")

(defconst mm/todo-comment-body-faces
  '(("FIX" . mm/comment-error-body) ("FIXME" . mm/comment-error-body)
    ("BUG" . mm/comment-error-body) ("FIXIT" . mm/comment-error-body)
    ("ISSUE" . mm/comment-error-body)
    ("TODO" . mm/comment-todo-body) ("UNIMPLEMENTED" . mm/comment-todo-body)
    ("HACK" . mm/comment-warning-body) ("WARN" . mm/comment-warning-body)
    ("WARNING" . mm/comment-warning-body) ("XXX" . mm/comment-warning-body)
    ("PERF" . mm/comment-perf-body) ("OPTIM" . mm/comment-perf-body)
    ("PERFORMANCE" . mm/comment-perf-body) ("OPTIMIZE" . mm/comment-perf-body)
    ("NOTE" . mm/comment-note-body) ("INFO" . mm/comment-info-body)
    ("TEST" . mm/comment-test-body) ("TESTING" . mm/comment-test-body)
    ("PASSED" . mm/comment-test-body) ("FAILED" . mm/comment-test-body))
  "Foreground-only face used for each marker's comment body.")

(defconst mm/todo-comment-keyword-faces
  '(("FIX" . mm/comment-error-keyword) ("FIXME" . mm/comment-error-keyword)
    ("BUG" . mm/comment-error-keyword) ("FIXIT" . mm/comment-error-keyword)
    ("ISSUE" . mm/comment-error-keyword)
    ("TODO" . mm/comment-todo-keyword) ("UNIMPLEMENTED" . mm/comment-todo-keyword)
    ("HACK" . mm/comment-warning-keyword) ("WARN" . mm/comment-warning-keyword)
    ("WARNING" . mm/comment-warning-keyword) ("XXX" . mm/comment-warning-keyword)
    ("PERF" . mm/comment-perf-keyword) ("OPTIM" . mm/comment-perf-keyword)
    ("PERFORMANCE" . mm/comment-perf-keyword) ("OPTIMIZE" . mm/comment-perf-keyword)
    ("NOTE" . mm/comment-note-keyword) ("INFO" . mm/comment-info-keyword)
    ("TEST" . mm/comment-test-keyword) ("TESTING" . mm/comment-test-keyword)
    ("PASSED" . mm/comment-test-keyword) ("FAILED" . mm/comment-test-keyword))
  "High-priority badge face used for each comment marker.")

(defconst mm/todo-line-comment-prefix-regexp "^[ \t]*//+!?[ \t]*"
  "Regexp matching the prefix of a slash-style line comment.")

(defvar-local mm/todo-comment-body-face nil
  "Face selected by `mm/font-lock-todo-comment-body-matcher'.")

(defun mm/todo-comment-line-info ()
  "Return (CONTENT-START KEYWORD-END KEYWORD) for this // line.

KEYWORD-END and KEYWORD are nil when the line continues an earlier marker."
  (save-excursion
    (beginning-of-line)
    (when (looking-at mm/todo-line-comment-prefix-regexp)
      (let ((content-start (match-end 0))
            (line-end (line-end-position)))
        (goto-char content-start)
        (if (re-search-forward mm/todo-comment-keyword-regexp line-end t)
            (list content-start (match-end 0)
                  (match-string-no-properties 1))
          (list content-start nil nil))))))

(defun mm/todo-comment-inherited-keyword ()
  "Return the nearest marker above point in this consecutive // block."
  (save-excursion
    (catch 'keyword
      (while (zerop (forward-line -1))
        (if-let ((info (mm/todo-comment-line-info)))
            (when (nth 2 info)
              (throw 'keyword (nth 2 info)))
          (throw 'keyword nil))))))

(defun mm/font-lock-todo-comment-body-matcher (limit)
  "Find the next colored TODO comment body before LIMIT."
  (catch 'match
    (while (re-search-forward mm/todo-line-comment-prefix-regexp limit t)
      (let* ((info (mm/todo-comment-line-info))
             (content-start (nth 0 info))
             (keyword-end (nth 1 info))
             (keyword (or (nth 2 info)
                          (mm/todo-comment-inherited-keyword)))
             (body-start (or keyword-end content-start))
             (body-end (line-end-position)))
        (when keyword
          (save-excursion
            (goto-char body-start)
            (skip-chars-forward " \t" body-end)
            (setq body-start (point)))
          (when (< body-start body-end)
            (setq mm/todo-comment-body-face
                  (alist-get keyword mm/todo-comment-body-faces nil nil #'string=))
            (set-match-data (list body-start body-end))
            (throw 'match t)))))))

(defconst mm/todo-comment-body-font-lock-keywords
  '((mm/font-lock-todo-comment-body-matcher
     (0 mm/todo-comment-body-face prepend)))
  "Font-lock rule for marker descriptions and // continuation lines.")

(defun mm/refresh-todo-comment-badges (&optional beg end)
  "Refresh high-priority TODO badge overlays between BEG and END."
  (let ((beg (save-excursion
               (goto-char (or beg (point-min)))
               (line-beginning-position)))
        (end (save-excursion
               (goto-char (or end (point-max)))
               (line-end-position))))
    (remove-overlays beg end 'mm/todo-comment-badge t)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward mm/todo-line-comment-prefix-regexp end t)
        (let ((line-end (line-end-position)))
          (while (re-search-forward mm/todo-comment-keyword-regexp line-end t)
            (let* ((keyword (match-string-no-properties 1))
                   (face (alist-get keyword mm/todo-comment-keyword-faces
                                    nil nil #'string=))
                   (overlay (make-overlay (match-beginning 1) (match-end 0)
                                          nil nil nil)))
              ;; `hl-line' is an overlay too.  A positive priority keeps this
              ;; badge fill above the current-line background.
              (overlay-put overlay 'face face)
              (overlay-put overlay 'priority 100)
              (overlay-put overlay 'evaporate t)
              (overlay-put overlay 'mm/todo-comment-badge t))))))))

(defun mm/refresh-todo-comment-badges-after-change-h (beg end _old-length)
  "Refresh TODO badge overlays on lines changed between BEG and END."
  (mm/refresh-todo-comment-badges beg end))

(defun mm/setup-todo-comment-body-font-lock-h ()
  "Color TODO descriptions and their consecutive // continuation lines."
  (font-lock-add-keywords nil mm/todo-comment-body-font-lock-keywords 'append)
  (add-hook 'after-change-functions
            #'mm/refresh-todo-comment-badges-after-change-h nil t)
  (mm/refresh-todo-comment-badges))

(add-hook 'prog-mode-hook #'mm/setup-todo-comment-body-font-lock-h)

(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when (derived-mode-p 'prog-mode)
      (mm/setup-todo-comment-body-font-lock-h)
      (font-lock-flush))))

(after! org
  (font-lock-add-keywords
   'org-mode
   '(("\\_<NOTE\\_>[!:]?" 0 'mm/comment-note-keyword prepend)))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'org-mode)
        (font-lock-flush)))))

(when (fboundp 'font-lock-flush)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (bound-and-true-p hl-todo-mode)
        (font-lock-flush)))))

(add-to-list 'completion-styles 'flex)

(require 'subr-x)

;; Generated Org files do not benefit from restoring serialized parser cache.
;; Keep Org's in-memory parser cache, but avoid stale on-disk cache files.
(setq org-element-cache-persistent nil)

(defun mm/open-calendar ()
  "Open Doom's Org-backed calendar view."
  (interactive)
  (require 'calfw-org)
  (calfw-org-open-calendar nil "Org" "Seagreen4" :view 'week))

(defun mm/select-calendar-window ()
  "Move focus to the visible Calendar window."
  (when-let ((window (get-buffer-window "*Calendar*" t)))
    (select-window window)))

(defun mm/current-buffer-directory ()
  "Return the current buffer's directory or `default-directory'."
  (or (when-let ((file-name (buffer-file-name)))
        (file-name-directory file-name))
      default-directory))

(defun mm/run-command-in-popup-terminal (command directory)
  "Run COMMAND in DIRECTORY inside the current workspace's Ghostel popup."
  (let* ((buffer-name (mm/ghostel-popup-buffer-name))
         (buffer (get-buffer buffer-name))
         (window (and buffer (get-buffer-window buffer)))
         (default-directory directory))
    ;; If the window is not currently open/visible, toggle it open.
    (unless window
      (mm/toggle-bottom-terminal)
      (setq buffer (get-buffer buffer-name))
      (setq window (get-buffer-window buffer)))
    ;; Select the terminal window
    (select-window window)
    ;; Switch to the buffer to run commands
    (with-current-buffer buffer
      (let* ((cd-cmd (format "cd %s" (shell-quote-argument (expand-file-name directory))))
             (full-cmd (concat cd-cmd " && " command)))
        (unless (mm/send-command-to-current-terminal full-cmd)
          (compile full-cmd))))))


(defun mm/close-popup-terminal-on-exit (buffer _event)
  "Close the bottom popup terminal window when its program exits.
Intended for `ghostel-exit-functions': only acts on Ghostel popup buffers;
other Ghostel buffers are left untouched."
  (when (and (bufferp buffer)
             (buffer-live-p buffer)
             (string-prefix-p "*doom:ghostel-popup:" (buffer-name buffer)))
    (let ((window (get-buffer-window buffer)))
      (when (window-live-p window)
        (delete-window window)))
    ))


(after! ghostel
  (add-hook 'ghostel-exit-functions #'mm/close-popup-terminal-on-exit))


(defun mm/run-program-in-popup-terminal (command directory)
  "Run COMMAND in DIRECTORY in the bottom popup terminal, closing the popup
when the program quits (normal exit, panic, or C-c).
The program is started with `exec' so the terminal's process *becomes* the
program; when it dies, `mm/close-popup-terminal-on-exit' removes the window."
  (let* ((buffer-name (mm/ghostel-popup-buffer-name))
         (buffer (get-buffer buffer-name))
         (window (and buffer (get-buffer-window buffer)))
         (default-directory directory))
    (unless window
      (mm/toggle-bottom-terminal)
      (setq buffer (get-buffer buffer-name))
      (setq window (get-buffer-window buffer)))
    (select-window window)
    (with-current-buffer buffer
      (let* ((cd-cmd (format "cd %s" (shell-quote-argument (expand-file-name directory))))
             ;; `exec' replaces the shell with the program, so quitting the
             ;; program (including C-c, which kills the now-foreground process)
             ;; ends the terminal's process and triggers the exit hook.
             (full-cmd (concat cd-cmd " && exec " command)))
        (unless (mm/send-command-to-current-terminal full-cmd)
          (compile full-cmd))))))

(defconst mm/matching-pairs
  '((?\{ . ?\}) (?\( . ?\)) (?\[ . ?\]))
  "Opening and closing pairs expanded by `mm/smart-newline-between-pairs'.")

(defun mm/smart-newline-between-pairs ()
  "Continue comments, expand an empty pair, or insert a normal newline.

Inside a comment, use the major mode's comment continuation command.  When
point is directly between {}, (), or [], put the closing delimiter on its own
line and leave point correctly indented on the blank middle line."
  (interactive)
  (cond
   ((nth 4 (syntax-ppss))
    (funcall (or comment-line-break-function #'comment-indent-new-line)))
   ((eq (alist-get (char-before) mm/matching-pairs) (char-after))
    ;; Move the closer down first so indentation sees a genuinely empty
    ;; interior line rather than a line beginning with the closer.
    (newline 2)
    (indent-according-to-mode)
    (forward-line -1)
    (indent-according-to-mode))
   (t
    (newline-and-indent))))

(defun mm/setup-smart-pair-newline-h ()
  "Use smart pair newlines locally in programming buffers."
  (evil-local-set-key 'insert (kbd "RET")
                      #'mm/smart-newline-between-pairs)
  (evil-local-set-key 'insert (kbd "<return>")
                      #'mm/smart-newline-between-pairs))

(add-hook 'prog-mode-hook #'mm/setup-smart-pair-newline-h)

(defvar mm/lsp-inlay-hints-enabled nil
  "Non-nil when Eglot inlay hints are enabled globally.")

(defun mm/apply-global-lsp-inlay-hints-h ()
  "Apply the global inlay-hint preference to the current Eglot buffer."
  (when (bound-and-true-p eglot--managed-mode)
    (eglot-inlay-hints-mode (if mm/lsp-inlay-hints-enabled 1 -1))
    ;; Enabling the minor mode only registers Eglot's JIT renderer.  Regions
    ;; that are already fontified otherwise remain unchanged until edited.
    (when mm/lsp-inlay-hints-enabled
      (font-lock-flush)
      (dolist (window (get-buffer-window-list (current-buffer) nil t))
        (font-lock-ensure (window-start window) (window-end window t))))))

(defun mm/toggle-lsp-inlay-hints ()
  "Toggle Eglot inlay hints globally in current and future LSP buffers."
  (interactive)
  (setq mm/lsp-inlay-hints-enabled (not mm/lsp-inlay-hints-enabled))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (mm/apply-global-lsp-inlay-hints-h)))
  (message "LSP inlay hints globally %s"
           (if mm/lsp-inlay-hints-enabled "enabled" "disabled")))

(defun mm/goto-definition-in-split ()
  "Go to a definition, splitting right when it is in the current buffer."
  (interactive)
  (let ((origin-window (selected-window))
        (origin-buffer (current-buffer))
        (origin-point (point)))
    (call-interactively #'+lookup/definition)
    (when (and (window-live-p origin-window)
               (eq (selected-window) origin-window)
               (eq (current-buffer) origin-buffer)
               (/= (point) origin-point))
      (let ((definition-point (point))
            (definition-window (split-window origin-window nil 'right)))
        (with-selected-window origin-window
          (goto-char origin-point))
        (select-window definition-window)
        (switch-to-buffer origin-buffer)
        (goto-char definition-point)))))

(map! "s-s" #'save-buffer)

;; Redo with Shift-u in normal mode.

(map! :n "U" #'evil-redo)

;; g-direction motion keys.

(map! :n "ge" #'evil-goto-line)
(map! :n "gh" #'evil-first-non-blank)
(map! :n "gl" #'evil-end-of-line)
(map! :n "gd" #'mm/goto-definition-in-split)

(defvar mm/evil-error-navigation-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "e") #'mm/next-error-cyclic)
    (define-key map (kbd "E") #'mm/previous-error-cyclic)
    map)
  "Evil `g t' prefix map for diagnostic navigation.")

(defun mm/setup-evil-error-navigation-h ()
  "Install the `g t' diagnostic prefix after Doom's tab bindings."
  (define-key evil-normal-state-map (kbd "g t")
              mm/evil-error-navigation-map))

;; Evil and the tabs module both bind `g t' directly.  Wait until all Doom
;; modules finish configuring so `g t e'/`g t E' remain the final bindings.
(add-hook 'doom-after-init-hook #'mm/setup-evil-error-navigation-h 100)

;; Match Vim/Neovim's number increment and decrement commands.
(map! :nv "C-a" #'evil-numbers/inc-at-pt
      :nv "C-x" #'evil-numbers/dec-at-pt)

(after! eglot
  (map! :map eglot-mode-map
        :n "gd" #'mm/goto-definition-in-split))

;; Cycle buffers with Shift-h/l in normal mode.

;; Native Codex/Cursor chat via agent-shell ACP adapters.
(use-package! agent-shell
  :commands (agent-shell-openai-start-codex
             agent-shell-cursor-start-agent
             agent-shell-opencode-start-agent
             agent-shell-toggle)
  :init
  (setq agent-shell-display-action
        '((display-buffer-in-side-window)
          (side . right)
          (slot . 0)
          (window-width . 0.38)
          (window-parameters . ((no-delete-other-windows . t)))))
  :config
  (require 'agent-shell-opencode)
  (setq agent-shell-openai-authentication
        (agent-shell-openai-make-authentication :login t)
        agent-shell-openai-default-session-mode-id "agent-full-access"
        agent-shell-session-strategy 'prompt
        agent-shell-session-restore-verbosity 'full
        ;; codex-acp is installed globally by npm, but npm 11 did not create
        ;; its executable shim in Homebrew's bin directory on this machine.
        ;; Invoke the installed ACP adapter directly so GUI Emacs does not
        ;; depend on its shell PATH.
        agent-shell-openai-codex-acp-command
        (list (or (executable-find "node") "/opt/homebrew/bin/node")
              "/opt/homebrew/lib/node_modules/@agentclientprotocol/codex-acp/dist/index.js")
        ;; Official binary is `cursor-agent` (Home Manager installs it that way).
        agent-shell-cursor-acp-command
        (list (or (executable-find "cursor-agent")
                  (executable-find "agent")
                  "cursor-agent")
              "acp")
        agent-shell-cursor-authentication
        (agent-shell-cursor-make-authentication :none t)
        ;; Reuse the OpenCode CLI's existing authenticated providers.  The
        ;; Agent Shell ACP adapter supplies its richer model-picker UI.
        agent-shell-opencode-acp-command
        (list (or (executable-find "opencode") "/opt/homebrew/bin/opencode") "acp")
        agent-shell-opencode-authentication
        (agent-shell-opencode-make-authentication :none t)))

(defun mm/agent-shell-use-full-window-height-h ()
  "Do not reserve editor scroll margins in Agent Shell buffers."
  (setq-local scroll-margin 0
              maximum-scroll-margin 0.25
              scroll-preserve-screen-position nil))

(add-hook 'agent-shell-mode-hook #'mm/agent-shell-use-full-window-height-h)

(defun mm/agent-shell-toggle-or-start (start-fn)
  "Toggle an existing Agent Shell, otherwise call START-FN."
  (require 'agent-shell)
  (if (agent-shell-buffers)
      (agent-shell-toggle)
    (funcall start-fn)))

(defun mm/codex-toggle ()
  "Show or hide Codex beside the editor, starting it when necessary."
  (interactive)
  (mm/agent-shell-toggle-or-start #'agent-shell-openai-start-codex))

(defun mm/cursor-toggle ()
  "Show or hide Cursor Agent beside the editor, starting it when necessary."
  (interactive)
  (mm/agent-shell-toggle-or-start #'agent-shell-cursor-start-agent))

(defun mm/opencode-toggle ()
  "Show or hide OpenCode in Agent Shell, starting it when necessary."
  (interactive)
  (mm/agent-shell-toggle-or-start #'agent-shell-opencode-start-agent))

(defun mm/evil-close-kills-agent-shell-a (original &rest args)
  "Kill Agent Shell when Evil closes its window; otherwise call ORIGINAL."
  (if (derived-mode-p 'agent-shell-mode)
      (let ((buffer (current-buffer))
            (window (selected-window)))
        (when-let ((process (get-buffer-process buffer)))
          (set-process-query-on-exit-flag process nil))
        (set-buffer-modified-p nil)
        (kill-buffer buffer)
        (when (window-live-p window)
          (ignore-errors (delete-window window))))
    (apply original args)))

(after! evil
  (unless (advice-member-p #'mm/evil-close-kills-agent-shell-a
                           #'evil-window-delete)
    (advice-add #'evil-window-delete :around
                #'mm/evil-close-kills-agent-shell-a)))

(use-package! emacs-opencode
  :commands (opencode opencode-ask opencode-ask-contextual
              opencode-open-session opencode-send-to-session
              opencode-send-context-to-session)
  :init
  ;; Resolve the Homebrew-managed executable for GUI Emacs too.
  ;; No node/bun here, so force the curl SSE backend.
  (setq opencode-server-command (or (executable-find "opencode") "opencode")
        opencode-session-default-agent "build"
        opencode-sse-backend 'curl
        opencode-ready-timeout 30)
  :config
  ;; OpenCode currently emits `id' before `type'.  The client parser assumes
  ;; `type' is the first JSON field, so accept either property order.
  (defun mm/opencode-sse-extract-event-type (data)
    "Extract an OpenCode SSE event type from DATA regardless of field order."
    (when (string-match
           "\"type\"[[:space:]]*:[[:space:]]*\"\\([^\"]+\\)\""
           data)
      (match-string 1 data)))
  (advice-add #'opencode-sse--extract-event-type :override
              #'mm/opencode-sse-extract-event-type)
  ;; The client reserves `C-c C-c' for submit and makes RET insert a newline.
  ;; In a chat pane that is easy to mistake for a stalled request, so use the
  ;; conventional chat binding and retain an explicit multiline alternative.
  (after! evil
    ;; Evil's insert-state map otherwise captures RET as `evil-ret'.
    (evil-define-key* 'insert opencode-session-mode-map (kbd "RET")
      #'opencode-session-send-input)
    (evil-define-key* 'insert opencode-session-mode-map (kbd "S-RET")
      #'newline)))

;; Move between Emacs windows with Option/Alt + h/j/k/l.
(map! "M-h" #'windmove-left
      "M-j" #'windmove-down
      "M-k" #'windmove-up
      "M-l" #'windmove-right)

;; Org binds M-h/M-l to outline promotion/demotion; keep window movement
;; consistent there too.
(after! org
  (map! :map org-mode-map
        "M-h" #'windmove-left
        "M-j" #'windmove-down
        "M-k" #'windmove-up
        "M-l" #'windmove-right))

;; `evil-org-mode' is a minor mode and therefore outranks `org-mode-map'.
(after! evil-org
  (evil-define-key '(normal insert visual motion operator) evil-org-mode-map
    (kbd "M-h") #'windmove-left
    (kbd "M-j") #'windmove-down
    (kbd "M-k") #'windmove-up
    (kbd "M-l") #'windmove-right))
