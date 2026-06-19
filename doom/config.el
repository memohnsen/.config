;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
(setq doom-font (font-spec :family "JetBrains Mono" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

(defun mm/apply-onedark-faces ()
  "Tune Doom's theme to match the Neovim onedark palette."
  (custom-set-faces!
    '(default :foreground "#abb2bf" :background "#282c34")
    '(font-lock-comment-face :foreground "#5c6370" :slant italic)
    '(font-lock-doc-face :foreground "#5c6370" :slant italic)
    '(font-lock-string-face :foreground "#98c379")
    '(font-lock-function-name-face :foreground "#61afef")
    '(font-lock-keyword-face :foreground "#c678dd")
    '(font-lock-builtin-face :foreground "#c678dd")
    '(font-lock-type-face :foreground "#e5c07b")
    '(font-lock-constant-face :foreground "#56b6c2")
    '(font-lock-number-face :foreground "#d19a66")
    '(font-lock-variable-name-face :foreground "#e86671")
    '(font-lock-operator-face :foreground "#c678dd")
    '(line-number :foreground "#5c6370" :background "#282c34")
    '(line-number-current-line :foreground "#abb2bf" :background "#31353f")
    '(hl-line :background "#31353f")
    '(region :background "#3b3f4c")
    '(mode-line :foreground "#abb2bf" :background "#31353f")
    '(mode-line-buffer-id :foreground "#61afef" :weight bold)
    '(doom-modeline :foreground "#abb2bf" :background "#31353f")
    '(doom-modeline-bar :background "#61afef")
    '(doom-modeline-bar-inactive :background "#282c34")
    '(doom-modeline-emphasis :foreground "#abb2bf" :background "#31353f")
    '(doom-modeline-highlight :foreground "#61afef" :background "#31353f")
    '(mm-modeline-workspace-current :foreground "#282c34" :background "#61afef" :weight normal)
    '(doom-modeline-buffer-file :foreground "#61afef" :weight bold)
    '(doom-modeline-buffer-path :foreground "#61afef" :weight bold)
    '(doom-modeline-buffer-modified :foreground "#56b6c2" :background "#31353f" :weight bold)
    '(doom-modeline-buffer-major-mode :foreground "#abb2bf" :background "#31353f")
    '(doom-modeline-project-dir :foreground "#abb2bf" :background "#31353f")
    '(doom-modeline-project-root-dir :foreground "#61afef" :background "#31353f")
    '(doom-modeline-vcs-default :foreground "#5c6370" :background "#31353f")
    '(solaire-mode-line-face :foreground "#abb2bf" :background "#31353f")
    '(solaire-mode-line-inactive-face :foreground "#5c6370" :background "#282c34")
    '(mode-line-inactive :foreground "#5c6370" :background "#282c34")
    '(centaur-tabs-default :foreground "#abb2bf" :background "#282c34")
    '(centaur-tabs-selected :foreground "#282c34" :background "#61afef" :weight normal)
    '(centaur-tabs-selected-modified :foreground "#282c34" :background "#61afef" :weight normal)
    '(centaur-tabs-unselected :foreground "#5c6370" :background "#282c34" :weight normal)
    '(centaur-tabs-unselected-modified :foreground "#56b6c2" :background "#282c34" :weight normal)
    '(centaur-tabs-close-unselected :foreground "#5c6370" :background "#282c34")
    '(centaur-tabs-close-selected :foreground "#282c34" :background "#61afef")
    '(centaur-tabs-modified-marker-unselected :foreground "#56b6c2" :background "#282c34")
    '(centaur-tabs-modified-marker-selected :foreground "#282c34" :background "#61afef")
    '(centaur-tabs-active-bar-face :background "#61afef")
    '(tab-line :foreground "#abb2bf" :background "#282c34")
    '(tab-line-tab :foreground "#abb2bf" :background "#282c34")
    '(tab-line-tab-current :foreground "#282c34" :background "#61afef")
    '(tab-line-tab-inactive :foreground "#5c6370" :background "#282c34")
    '(header-line :foreground "#abb2bf" :background "#282c34")))

(add-hook 'doom-load-theme-hook #'mm/apply-onedark-faces)

(require 'cl-lib)

(defface mm-modeline-workspace-current
  '((t (:foreground "#282c34" :background "#61afef" :weight normal)))
  "Face for the current workspace in the modeline.")

(after! doom-modeline
  (doom-modeline-def-segment mm-workspaces
    "Show all open Doom workspaces."
    (when (and (bound-and-true-p persp-mode)
               (fboundp '+workspace-list-names)
               (fboundp '+workspace-current-name)
               (ignore-errors (+workspace-current)))
      (ignore-errors
        (let ((names (+workspace-list-names))
              (current-name (+workspace-current-name)))
          (when names
            (let ((index 0))
              (format
               " %s "
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

  (doom-modeline-def-modeline 'main
    '(eldoc bar window-state workspace-name window-number modals matches follow buffer-info remote-host buffer-position word-count parrot selection-info)
    '(compilation objed-state misc-info project-name mm-workspaces battery grip irc mu4e gnus github debug repl lsp minor-modes input-method indent-info buffer-encoding major-mode process vcs check time))

  (doom-modeline-def-modeline 'dashboard
    '(bar window-number modals buffer-default-directory-simple remote-host)
    '(compilation misc-info mm-workspaces battery irc mu4e gnus github debug minor-modes input-method major-mode process time)))

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

(defface mm/comment-todo-keyword
  '((t (:foreground "#000000"
        :background "#61afef"
        :weight bold
        :box (:line-width (1 . -1) :color "#61afef"))))
  "Face for TODO keywords in code comments.")

(after! hl-todo
  (setq hl-todo-keyword-faces
        '(("TODO" mm/comment-todo-keyword bold))))

(after! centaur-tabs
  (setq centaur-tabs-height 18
        centaur-tabs-bar-height 20
        centaur-tabs-set-close-button nil
        centaur-tabs-show-new-tab-button nil
        centaur-tabs-show-navigation-buttons nil
        centaur-tabs-left-edge-margin " "
        centaur-tabs-right-edge-margin " "
        centaur-tabs-icons-prefix "")

  (defun mm/apply-centaur-tabs-onedark ()
    "Keep centaur-tabs' fill/background matched to Neovim onedark."
    (set-face-attribute centaur-tabs-display-line nil
                        :foreground "#abb2bf"
                        :background "#282c34"
                        :box nil
                        :overline nil
                        :underline nil)
    (set-face-attribute 'centaur-tabs-default nil
                        :foreground "#abb2bf"
                        :background "#282c34"
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
  (treemacs-define-RET-action 'file-node-open #'treemacs-visit-node-close-treemacs)
  (treemacs-define-RET-action 'file-node-closed #'treemacs-visit-node-close-treemacs))

(use-package! flyover
  :hook ((flycheck-mode . flyover-mode)
         (flymake-mode . flyover-mode))
  :config
  (setq flyover-checkers '(flycheck flymake)
        flyover-levels '(error warning info)
        flyover-use-theme-colors t
        flyover-background-lightness 35
        flyover-text-tint 'lighter
        flyover-text-tint-percent 35
        flyover-icon-tint 'lighter
        flyover-icon-tint-percent 35
        flyover-icon-background-tint 'darker
        flyover-icon-background-tint-percent 45
        flyover-error-icon "x"
        flyover-warning-icon "!"
        flyover-info-icon "i"
        flyover-border-style 'pill
        flyover-border-match-icon t
        flyover-hide-checker-name t
        flyover-show-virtual-line t
        flyover-virtual-line-type 'curved-dotted-arrow
        flyover-line-position-offset 1
        flyover-wrap-messages t
        flyover-max-line-length 100
        flyover-display-mode 'always
        flyover-hide-during-completion t
        flyover-debounce-interval 0.2
        flyover-cursor-debounce-interval 0.3))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

(global-display-line-numbers-mode 1)

(dolist (hook '(term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

(after! vterm
  (setq vterm-term-environment-variable "xterm-256color"
        vterm-environment '("COLORTERM=truecolor"
                            "NO_COLOR"
                            "CLICOLOR=1"))
  (custom-set-faces!
    '(term-color-black :foreground "#282c34" :background "#282c34")
    '(term-color-red :foreground "#e86671" :background "#e86671")
    '(term-color-green :foreground "#98c379" :background "#98c379")
    '(term-color-yellow :foreground "#e5c07b" :background "#e5c07b")
    '(term-color-blue :foreground "#61afef" :background "#61afef")
    '(term-color-magenta :foreground "#c678dd" :background "#c678dd")
    '(term-color-cyan :foreground "#56b6c2" :background "#56b6c2")
    '(term-color-white :foreground "#abb2bf" :background "#abb2bf")
    '(term-color-bright-black :foreground "#5c6370" :background "#5c6370")
    '(term-color-bright-red :foreground "#e86671" :background "#e86671")
    '(term-color-bright-green :foreground "#98c379" :background "#98c379")
    '(term-color-bright-yellow :foreground "#e5c07b" :background "#e5c07b")
    '(term-color-bright-blue :foreground "#61afef" :background "#61afef")
    '(term-color-bright-magenta :foreground "#c678dd" :background "#c678dd")
    '(term-color-bright-cyan :foreground "#56b6c2" :background "#56b6c2")
    '(term-color-bright-white :foreground "#ffffff" :background "#ffffff")
    '(vterm-color-black :foreground "#282c34" :background "#282c34")
    '(vterm-color-red :foreground "#e86671" :background "#e86671")
    '(vterm-color-green :foreground "#98c379" :background "#98c379")
    '(vterm-color-yellow :foreground "#e5c07b" :background "#e5c07b")
    '(vterm-color-blue :foreground "#61afef" :background "#61afef")
    '(vterm-color-magenta :foreground "#c678dd" :background "#c678dd")
    '(vterm-color-cyan :foreground "#56b6c2" :background "#56b6c2")
    '(vterm-color-white :foreground "#abb2bf" :background "#abb2bf")
    '(vterm-color-bright-black :foreground "#5c6370" :background "#5c6370")
    '(vterm-color-bright-red :foreground "#e86671" :background "#e86671")
    '(vterm-color-bright-green :foreground "#98c379" :background "#98c379")
    '(vterm-color-bright-yellow :foreground "#e5c07b" :background "#e5c07b")
    '(vterm-color-bright-blue :foreground "#61afef" :background "#61afef")
    '(vterm-color-bright-magenta :foreground "#c678dd" :background "#c678dd")
    '(vterm-color-bright-cyan :foreground "#56b6c2" :background "#56b6c2")
    '(vterm-color-bright-white :foreground "#ffffff" :background "#ffffff")))

(defun mm/disable-terminal-process-query ()
  "Do not prompt before closing terminal buffers created from this config."
  (when-let ((process (get-buffer-process (current-buffer))))
    (set-process-query-on-exit-flag process nil)))

(dolist (hook '(term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook hook #'mm/disable-terminal-process-query))

(use-package! indent-bars
  :hook ((prog-mode conf-mode) . indent-bars-mode)
  :config
  (setq indent-bars-color '("#61afef" :face-bg nil :blend 0)
        indent-bars-prefer-character t
        indent-bars-no-stipple-char ?|
        indent-bars-display-on-blank-lines t
        indent-bars-highlight-current-depth t
        indent-bars-current-depth-color '("#e5c07b" :face-bg nil :blend 0)))

(dolist (path '("~/go/bin" "~/.cargo/bin"))
  (let ((expanded-path (expand-file-name path)))
    (when (file-directory-p expanded-path)
      (add-to-list 'exec-path expanded-path)
      (setenv "PATH" (concat expanded-path ":" (getenv "PATH"))))))

(after! project
  (defun mm/project-try-go-or-cargo (dir)
    (when-let ((root (or (locate-dominating-file dir "go.mod")
                         (locate-dominating-file dir "Cargo.toml"))))
      (cons 'mm/go-or-cargo root)))

  (cl-defmethod project-root ((project (head mm/go-or-cargo)))
    (cdr project))

  (add-hook 'project-find-functions #'mm/project-try-go-or-cargo))

;; Keep completion suggestions usable in both GUI and terminal Emacs.
(after! company
  (setq company-idle-delay 0.18
        company-minimum-prefix-length 1
        company-tooltip-limit 14
        company-frontends '(company-pseudo-tooltip-frontend
                            company-echo-metadata-frontend)
        company-backends '(company-capf)
        company-auto-complete nil
        company-auto-commit nil)
  (setq-default company-backends '(company-capf))
  (global-company-mode 1))

(add-to-list 'completion-styles 'flex)

(map! :i "C-SPC" #'company-complete
      :i "C-@" #'company-complete)

(defvar mm/macos-calendar-org-file (expand-file-name "~/dev/org/calendar.org")
  "Org file generated from the local macOS Calendar app.")

(defvar mm/macos-calendar-sync-days 14
  "Number of future days to import from macOS Calendar.")

(defvar mm/macos-calendar-include-regexp
  "^(memohnsen@gmail\\.com|Teamworks H2F|P&G|Home)$"
  "Calendar names included when importing macOS Calendar events.")

(defvar mm/macos-calendar-startup-sync-started nil
  "Whether the macOS Calendar startup sync has already been started.")

(defvar mm/use-macos-calendar-workaround t
  "Whether to keep importing macOS Calendar events into `calendar.org'.")

(defun mm/clear-macos-calendar-org-cache ()
  "Drop Org's persisted parse cache for the generated calendar file."
  (ignore-errors
    (let ((persist-dir (or (bound-and-true-p org-persist-directory)
                           (expand-file-name "org/persist/" doom-cache-dir))))
      (when (file-directory-p persist-dir)
        (delete-directory persist-dir t)))))

(defun mm/sync-macos-calendar ()
  "Pull upcoming events from macOS Calendar into Org Agenda."
  (interactive)
  (let ((script (expand-file-name "scripts/macos-calendar-to-org" doom-user-dir)))
    (unless (file-executable-p script)
      (user-error "Calendar sync script is not executable: %s" script))
    (make-directory (file-name-directory mm/macos-calendar-org-file) t)
    (let ((exit-code (call-process script nil "*macOS Calendar Sync*" t
                                   mm/macos-calendar-org-file
                                   (number-to-string mm/macos-calendar-sync-days)
                                   mm/macos-calendar-include-regexp)))
      (if (zerop exit-code)
        (progn
          (mm/clear-macos-calendar-org-cache)
          (message "Synced macOS Calendar to %s" mm/macos-calendar-org-file))
      (pop-to-buffer "*macOS Calendar Sync*")
      (user-error "macOS Calendar sync failed")))))

(defun mm/sync-macos-calendar-async ()
  "Refresh macOS Calendar events in the background."
  (let ((script (expand-file-name "scripts/macos-calendar-to-org" doom-user-dir)))
    (when (file-executable-p script)
      (make-directory (file-name-directory mm/macos-calendar-org-file) t)
      (make-process
       :name "macOS Calendar Sync"
       :buffer "*macOS Calendar Sync*"
       :command (list script
                      mm/macos-calendar-org-file
                      (number-to-string mm/macos-calendar-sync-days)
                      mm/macos-calendar-include-regexp)
       :noquery t
       :sentinel
       (lambda (process _event)
         (when (eq (process-status process) 'exit)
           (if (zerop (process-exit-status process))
               (progn
                 (mm/clear-macos-calendar-org-cache)
                 (message "Synced macOS Calendar to %s" mm/macos-calendar-org-file))
             (message "macOS Calendar sync failed; see *macOS Calendar Sync*"))))))))

(defun mm/sync-macos-calendar-on-startup ()
  "Run the macOS Calendar sync once per Emacs startup."
  (unless mm/macos-calendar-startup-sync-started
    (setq mm/macos-calendar-startup-sync-started t)
    (mm/sync-macos-calendar-async)))

(when mm/use-macos-calendar-workaround
  (add-hook 'emacs-startup-hook #'mm/sync-macos-calendar-on-startup)
  (run-at-time 3 nil #'mm/sync-macos-calendar-on-startup))

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

(setq rustic-lsp-client 'eglot
      rustic-lsp-server 'rust-analyzer
      rustic-lsp-check-command "clippy")

(after! eglot
  (add-to-list 'eglot-server-programs
               '((go-mode go-ts-mode) . ("gopls")))
  (add-to-list 'eglot-server-programs
               '((rust-mode rustic-mode rust-ts-mode) . ("rust-analyzer")))
  (setq eglot-autoshutdown t)
  (setq-default eglot-workspace-configuration
                '(:gopls (:completeUnimported t)
                  :rust-analyzer (:cargo (:allFeatures t)
                                  :check (:command "clippy")))))

(defun mm/rust-organize-imports ()
  "Organize Rust imports with rust-analyzer before saving."
  (when (and (derived-mode-p 'rust-mode 'rustic-mode 'rust-ts-mode)
             (bound-and-true-p eglot--managed-mode))
    (eglot-code-actions nil nil "source.organizeImports" t)))

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
                company-idle-delay 0.08
                company-backends '(company-capf))
    (add-hook 'before-save-hook #'mm/rust-organize-imports nil t)
    (add-hook 'before-save-hook #'eglot-format-buffer nil t)
    (add-hook 'post-self-insert-hook #'mm/rust-company-complete-after-trigger nil t)))

(defun mm/go-company-complete-after-dot ()
  "Trigger LSP completion immediately after Go selector dots."
  (when (and (derived-mode-p 'go-mode 'go-ts-mode)
             (bound-and-true-p eglot--managed-mode)
             (eq last-command-event ?.))
    (company-manual-begin)))

(add-hook! '(go-mode-hook go-ts-mode-hook)
  (defun mm/go-company-setup-h ()
    (setq-local company-minimum-prefix-length 3
                company-idle-delay 0.18
                company-backends '(company-capf))
    (add-hook 'post-self-insert-hook #'mm/go-company-complete-after-dot nil t)))

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
             (require 'rustic-lsp)
             (condition-case err
                 (unless (bound-and-true-p eglot--managed-mode)
                   (eglot '(rustic-mode rust-mode rust-ts-mode)
                          (project-current t)
                          'eglot-rust-analyzer
                          '("rust-analyzer")
                          '("rust")))
               (error
                (message "Rust Eglot failed: %s" (error-message-string err))))))))
     (current-buffer))))

(defun mm/eglot-start-h ()
  "Start Eglot for non-Rust LSP buffers."
  (when (project-current nil)
    (eglot-ensure)))

(add-hook! '(rust-mode-hook
             rustic-mode-hook
             rust-ts-mode-hook)
  #'mm/rust-eglot-start-h)

(add-hook! '(go-mode-hook go-ts-mode-hook)
  #'mm/eglot-start-h)

(setq org-directory "~/dev/org/")

(require 'subr-x)

;; Generated Org files do not benefit from restoring serialized parser cache.
;; Keep Org's in-memory parser cache, but avoid stale on-disk cache files.
(setq org-element-cache-persistent nil)

(defun mm/org-git-repo-root ()
  "Return the Git repository root for `org-directory', or nil."
  (let ((default-directory (expand-file-name org-directory)))
    (when (file-directory-p default-directory)
      (with-temp-buffer
        (when (zerop (call-process "git" nil t nil "rev-parse" "--show-toplevel"))
          (string-trim (buffer-string)))))))

(defun mm/save-org-directory-buffers ()
  "Save modified file buffers under `org-directory' without prompting."
  (let ((org-root (file-name-as-directory
                   (file-truename (expand-file-name org-directory)))))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and buffer-file-name
                   (buffer-modified-p)
                   (string-prefix-p org-root (file-truename buffer-file-name)))
          (save-buffer))))))

(defun mm/org-git-push (buffer)
  "Push the current Git repository, logging output to BUFFER."
  (if (zerop (call-process "git" nil buffer t "push"))
      (message "Pushed Org directory changes")
    (message "Org directory Git push failed; see %s" buffer)))

(defun mm/git-commit-org-directory ()
  "Stage, commit, and push changes in `org-directory' when its Git repo is dirty."
  (interactive)
  (if-let ((repo-root (mm/org-git-repo-root)))
      (let ((default-directory repo-root)
            (buffer "*Org Git Commit*"))
        (mm/save-org-directory-buffers)
        (with-current-buffer (get-buffer-create buffer)
          (erase-buffer))
        (if (string-empty-p
             (string-trim
              (with-temp-buffer
                (call-process "git" nil t nil "status" "--porcelain")
                (buffer-string))))
            (mm/org-git-push buffer)
          (if (and (zerop (call-process "git" nil buffer t "add" "-A"))
                   (zerop (call-process "git" nil buffer t
                                        "commit" "-m"
                                        (format-time-string "Update org files %Y-%m-%d %H:%M"))))
              (mm/org-git-push buffer)
            (message "Org directory Git commit failed; see %s" buffer))))
    (message "Org directory is not inside a Git repo: %s" org-directory)))

(add-hook 'kill-emacs-hook #'mm/git-commit-org-directory)

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

(after! org
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
        :leader
        :desc "Schedule heading" "o s" #'mm/org-schedule-from-calendar)
  (org-clock-persistence-insinuate))

(defun mm/org-schedule-from-calendar (arg)
  "Schedule the current Org heading, starting date selection in Calendar."
  (interactive "P")
  (let ((org-read-date-display-type 'calendar)
        (minibuffer-setup-hook (cons #'mm/select-calendar-window minibuffer-setup-hook)))
    (org-schedule arg)))

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

(defun mm/open-calendar ()
  "Open Doom's Org-backed calendar view."
  (interactive)
  (require 'calfw-org)
  (calfw-org-open-calendar nil "Org" "Seagreen4" :view 'week))

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

(defun mm/select-calendar-window ()
  "Move focus to the visible Calendar window."
  (when-let ((window (get-buffer-window "*Calendar*" t)))
    (select-window window)))

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

(defun mm/org-super-agenda ()
  "Open a grouped Org task agenda."
  (interactive)
  (org-agenda nil "a"))

(defun mm/editor-window ()
  "Return a normal editor window in the selected frame."
  (let ((selected (selected-window)))
    (if (not (or (window-parameter selected 'window-side)
                 (window-parameter selected 'popup)
                 (window-dedicated-p selected)))
        selected
      (or (let (editor-window)
            (dolist (window (window-list nil 'no-minibuf))
              (unless (or (window-parameter window 'window-side)
                          (window-parameter window 'popup)
                          (window-dedicated-p window))
                (setq editor-window window)))
            editor-window)
          selected))))

(defvar mm/last-regular-buffer nil
  "Last non-terminal buffer visited before jumping to a terminal.")

(defun mm/terminal-buffer-p (&optional buffer)
  "Return non-nil when BUFFER is a terminal-like buffer."
  (with-current-buffer (or buffer (current-buffer))
    (derived-mode-p 'vterm-mode 'term-mode 'shell-mode 'eshell-mode)))

(defun mm/last-terminal-buffer ()
  "Return the most recently used live terminal buffer."
  (seq-find #'mm/terminal-buffer-p (buffer-list)))

(defun mm/last-regular-buffer ()
  "Return the last useful non-terminal buffer."
  (or (and (buffer-live-p mm/last-regular-buffer)
           mm/last-regular-buffer)
      (seq-find
       (lambda (buffer)
         (and (buffer-live-p buffer)
              (not (mm/terminal-buffer-p buffer))
              (not (string-prefix-p " " (buffer-name buffer)))))
       (buffer-list))))

(defun mm/toggle-terminal-buffer ()
  "Jump between the latest terminal buffer and the last regular buffer.
Create a fresh terminal when none exists."
  (interactive)
  (select-window (mm/editor-window))
  (if (mm/terminal-buffer-p)
      (when-let ((buffer (mm/last-regular-buffer)))
        (switch-to-buffer buffer))
    (setq mm/last-regular-buffer (current-buffer))
    (if-let ((buffer (mm/last-terminal-buffer)))
        (progn
          (switch-to-buffer buffer)
          (mm/disable-terminal-process-query))
      (if (fboundp '+vterm/here)
          (progn
            (+vterm/here t)
            (mm/disable-terminal-process-query))
        (shell (generate-new-buffer-name "*shell*"))
        (mm/disable-terminal-process-query)))))

(defun mm/toggle-bottom-terminal ()
  "Toggle a small terminal at the bottom of the frame.
Use vterm when its native module is available; fall back to `shell'."
  (interactive)
  (let* ((buffer-name "*mm-terminal*")
         (buffer (get-buffer buffer-name))
         (window (and buffer (get-buffer-window buffer))))
    (if window
        (delete-window window)
      (when (and buffer
                 (not (or (and (fboundp 'vterm-check-proc)
                               (vterm-check-proc buffer-name))
                          (comint-check-proc buffer-name))))
        (kill-buffer buffer)
        (setq buffer nil))
      (let ((window
             (display-buffer-in-side-window
              (or buffer (get-buffer-create buffer-name))
              '((side . bottom)
                (slot . 0)
                (window-height . 0.25)))))
        (select-window window)
        (mm/disable-terminal-process-query)
        (if (and (locate-library "vterm-module")
                 (require 'vterm nil t))
            (unless (vterm-check-proc buffer-name)
              (let ((vterm-buffer-name buffer-name))
                (vterm))
              (mm/disable-terminal-process-query))
          (unless (comint-check-proc buffer-name)
            (shell buffer-name)
            (mm/disable-terminal-process-query)))))))

(defun mm/confirm-kill-emacs-with-org-clock (_prompt)
  "Block `kill-emacs' when an Org clock is active."
  (if (and (fboundp 'org-clocking-p)
           (org-clocking-p))
      (progn
        (message "Active Org clock for \"%s\". Stop it before quitting."
                 (or (and (boundp 'org-clock-current-task) org-clock-current-task)
                     "current task"))
        nil)
    t))

;; Prevent quitting while an Org clock is running; otherwise do not ask for confirmation.
(setq confirm-kill-emacs #'mm/confirm-kill-emacs-with-org-clock
      confirm-kill-processes nil)

(defun mm/current-buffer-directory ()
  "Return the current buffer's directory or `default-directory'."
  (or (when-let ((file-name (buffer-file-name)))
        (file-name-directory file-name))
      default-directory))

(defun mm/cargo-root ()
  "Return the nearest Cargo project root for the current buffer."
  (or (locate-dominating-file (mm/current-buffer-directory) "Cargo.toml")
      default-directory))

(defun mm/send-command-to-current-terminal (command)
  "Send COMMAND to the current terminal buffer."
  (cond
   ((derived-mode-p 'vterm-mode)
    (vterm-send-string command)
    (vterm-send-return)
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

(defun mm/run-command-in-zellij (command directory)
  "Run COMMAND in a new zellij pane rooted at DIRECTORY."
  (let ((shell (or (getenv "SHELL") "/bin/zsh")))
    (start-process
     "zellij-run" nil
     "zellij" "run"
     "--cwd" (expand-file-name directory)
     "--floating"
     "--name" command
     "--"
     shell "-lc" (format "%s; exec %s" command (shell-quote-argument shell)))))

(defun mm/run-shell-command-in-bottom-window (command directory)
  "Run COMMAND in DIRECTORY in a bottom shell-like window."
  (cond
   ((mm/terminal-buffer-p)
    (mm/send-command-to-current-terminal command))
   ((and (getenv "ZELLIJ")
         (executable-find "zellij"))
    (mm/run-command-in-zellij command directory))
   (t
    (let ((default-directory directory))
      (if (fboundp '+vterm/here)
        (progn
          (+vterm/here nil)
          (mm/disable-terminal-process-query)
          (vterm-send-string command)
          (vterm-send-return))
        (compile command))))))

(defun mm/run-command-in-popup-terminal (command directory)
  "Run COMMAND in DIRECTORY inside the bottom popup terminal (*mm-terminal*)."
  (let* ((buffer-name "*mm-terminal*")
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

(defun mm/cargo (action directory &optional popup)
  "Run cargo ACTION in DIRECTORY.
If POPUP is non-nil, run in the bottom popup terminal (oT)."
  (if popup
      (mm/run-command-in-popup-terminal (concat "cargo " action) directory)
    (mm/run-shell-command-in-bottom-window (concat "cargo " action) directory)))

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

(defun mm/project-find-file ()
  "Project file picker with Evil minibuffer navigation and fresh file cache."
  (interactive)
  (when (fboundp 'projectile-invalidate-cache)
    (projectile-invalidate-cache nil))
  (mm/with-evil-minibuffer-nav #'projectile-find-file))

(defun mm/switch-buffer ()
  "Switch buffers with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'switch-to-buffer))

(defun mm/switch-workspace-buffer ()
  "Switch workspace buffers with Evil minibuffer navigation."
  (interactive)
  (if (fboundp 'persp-switch-to-buffer)
      (mm/with-evil-minibuffer-nav #'persp-switch-to-buffer)
    (mm/switch-buffer)))

(defun mm/search-buffer ()
  "Search current buffer with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-buffer))

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

(defun mm/search-project ()
  "Search project with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-project))

(defun mm/search-other-project ()
  "Search another project with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+default/search-other-project))

(defun mm/workspace-switch-to ()
  "Switch workspace with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+workspace/switch-to))

(defun mm/workspace-load ()
  "Load workspace with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+workspace/load))

(defun mm/workspace-delete ()
  "Delete saved workspace with Evil minibuffer navigation."
  (interactive)
  (mm/with-evil-minibuffer-nav #'+workspace/delete))

(map! :leader
      :desc "Find file in project" "SPC" #'mm/project-find-file
      "," nil
      "." nil
      "<" nil
      "`" nil
      "/" nil
      "o p" nil
      "o P" nil
      "o -" nil
      "b -" nil
      "b [" nil
      "b ]" nil
      "b B" nil
      "b b" nil
      :desc "Search buffer" "s b" #'mm/search-buffer
      :desc "Search all open buffers" "s B" #'mm/search-all-open-buffers
      :desc "Search current directory" "s d" #'mm/search-cwd
      :desc "Search other directory" "s D" #'mm/search-other-cwd
      :desc "Search .emacs.d" "s e" #'mm/search-emacsd
      :desc "Search project" "s p" #'mm/search-project
      :desc "Search other project" "s P" #'mm/search-other-project
      :desc "Daily note" "o d" #'mm/open-daily-org
      :desc "Calendar" "o C" #'mm/open-calendar
      :desc "Find Org note" "o f" #'mm/find-org-note
      :desc "Grep Org notes" "o g" #'mm/grep-org-notes
      :desc "Org agenda" "o a" #'mm/org-super-agenda
      :desc "Org capture" "o c" #'org-capture
      (:prefix-map ("r" . "Rust Commands")
       :desc "Cargo run" "r" (cmd! (mm/cargo "run" (mm/cargo-root)))
       :desc "Cargo build" "b" (cmd! (mm/cargo "build" (mm/cargo-root) t))
       :desc "Cargo test" "t" (cmd! (mm/cargo "test" (mm/cargo-root) t))
       :desc "Cargo clippy" "c" (cmd! (mm/cargo "clippy" (mm/cargo-root) t))))

(after! which-key
  (which-key-add-key-based-replacements
    doom-leader-key "leader"
    (concat doom-leader-key " TAB") "workspace"
    (concat doom-leader-key " b") "buffer"
    (concat doom-leader-key " c") "code"
    (concat doom-leader-key " d") "debugger"
    (concat doom-leader-key " e") "evaluate"
    (concat doom-leader-key " f") "file"
    (concat doom-leader-key " g") "git"
    (concat doom-leader-key " h") "help"
    (concat doom-leader-key " i") "insert"
    (concat doom-leader-key " m") "multiple cursors"
    (concat doom-leader-key " n") "notes"
    (concat doom-leader-key " o") "open"
    (concat doom-leader-key " p") "project"
    (concat doom-leader-key " q") "quit/session"
    (concat doom-leader-key " r") "Rust Commands"
    (concat doom-leader-key " s") "search"
    (concat doom-leader-key " t") "toggle"
    (concat doom-leader-key " u") "universal argument"
    (concat doom-leader-key " w") "workspace/windows")
  (when doom-leader-alt-key
    (which-key-add-key-based-replacements
      doom-leader-alt-key "leader"
      (concat doom-leader-alt-key " TAB") "workspace"
      (concat doom-leader-alt-key " b") "buffer"
      (concat doom-leader-alt-key " c") "code"
      (concat doom-leader-alt-key " d") "debugger"
      (concat doom-leader-alt-key " e") "evaluate"
      (concat doom-leader-alt-key " f") "file"
      (concat doom-leader-alt-key " g") "git"
      (concat doom-leader-alt-key " h") "help"
      (concat doom-leader-alt-key " i") "insert"
      (concat doom-leader-alt-key " m") "multiple cursors"
      (concat doom-leader-alt-key " n") "notes"
      (concat doom-leader-alt-key " o") "open"
      (concat doom-leader-alt-key " p") "project"
      (concat doom-leader-alt-key " q") "quit/session"
      (concat doom-leader-alt-key " r") "Rust Commands"
      (concat doom-leader-alt-key " s") "search"
      (concat doom-leader-alt-key " t") "toggle"
      (concat doom-leader-alt-key " u") "universal argument"
      (concat doom-leader-alt-key " w") "workspace/windows")))

;; Save the current file with Command-s.
(map! "s-s" #'save-buffer)

;; Redo with Shift-u in normal mode.
(map! :n "U" #'evil-redo)

;; g-direction motion keys.
(map! :n "ge" #'evil-goto-line)
(map! :n "gh" #'evil-beginning-of-line)
(map! :n "gl" #'evil-end-of-line)

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

;; Cycle buffers with Shift-h/l in normal mode.
(map! :n "H" #'mm/tab-left)
(map! :n "L" #'mm/tab-right)

;; Open the project file explorer with `SPC e`, similar to LazyVim.
(map! :leader
      :desc "Project explorer" "e" #'+treemacs/toggle
      (:prefix ("TAB" . "workspace")
       :desc "Search workspace" "." #'mm/workspace-switch-to
       :desc "Load workspace" "l" #'mm/workspace-load
       :desc "Delete workspace" "D" #'mm/workspace-delete
       :desc "Next workspace" "TAB" #'+workspace/switch-right))

;; Jump to/from a regular terminal with `SPC o t`; open a bottom terminal with `SPC o T`.
(map! :leader
      :desc "Toggle terminal buffer" "o t" #'mm/toggle-terminal-buffer
      :desc "Bottom terminal" "o T" #'mm/toggle-bottom-terminal)

;; Let Doom/Projectile discover projects kept in ~/dev subfolders.
;; Use `SPC p p` to switch projects, or `SPC p a` to add one manually.
(after! projectile
  (setq projectile-project-search-path '(("~/dev" . 1)
                                         ("~/dev" . 2)
                                         ("~/dev" . 3)
                                         ("~/dev" . 4))
        projectile-auto-discover t)
  (run-with-idle-timer
   2 nil
   (lambda ()
     (when (file-accessible-directory-p "~/dev")
       (projectile-discover-projects-in-search-path)
       (projectile-save-known-projects)))))


;; Configure the macOS traffic-light titlebar to match the current theme.
(when (eq system-type 'darwin)
  (setq ns-use-proxy-icon nil
        frame-title-format nil))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
