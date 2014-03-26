
(defun init-hook ()
  "If the current buffer is 'init.org' the code-blocks are
tangled, and the tangled file is compiled."
  (when (equal (buffer-file-name)
               (expand-file-name (concat user-emacs-directory "init.org")))
    (org-babel-tangle)
    (byte-compile-file (concat user-emacs-directory "init.el"))))

(add-hook 'after-save-hook 'init-hook)

(require 'package)
(package-initialize)

(add-to-list 'package-archives
             '("MELPA" . "http://melpa.milkbox.net/packages/") t)

(defun newest-package-installed-p (package)
  "Return true if the newest available PACKAGE is installed."
  (when (package-installed-p package)
    (let* ((local-pkg-desc (or (assq package package-alist)
                               (assq package package--builtins)))
           (newest-pkg-desc (assq package package-archive-contents)))
      (and local-pkg-desc newest-pkg-desc
           (version-list-= (package-desc-vers (cdr local-pkg-desc))
                           (package-desc-vers (cdr newest-pkg-desc)))))))

(defun upgrade-or-install-package (package)
  "Unless the newest available version of PACKAGE is installed
PACKAGE is installed and the current version is deleted."
  (unless (newest-package-installed-p package)
    (let ((pkg-desc (assq package package-alist)))
      (when pkg-desc
        (package-delete (symbol-name package)
                        (package-version-join
                         (package-desc-vers (cdr pkg-desc)))))
      (package-install package))))

(defvar days-between-updates 1)
(defvar do-package-update-on-init t)
(defvar package-last-update-file
  (expand-file-name (concat user-emacs-directory ".package-last-update")))

(require 'time-stamp)
;; Open the package-last-update-file
(with-temp-file package-last-update-file
  (if (file-exists-p package-last-update-file)
      (progn
        ;; Insert it's original content's.
        (insert-file-contents package-last-update-file)
        (let ((start (re-search-forward time-stamp-start nil t))
              (end (re-search-forward time-stamp-end nil t)))
          (when (and start end)
            ;; Assuming we have found a time-stamp, we check determine if it's
            ;; time to update.
            (setq do-package-update-on-init
                  (<= days-between-updates
                      (days-between
                       (current-time-string)
                       (buffer-substring-no-properties start end))))
            ;; Remember to update the time-stamp.
            (when do-package-update-on-init
              (time-stamp)))))
    ;; If no such file exists it is created with a time-stamp.
    (insert "Time-stamp: <>")
    (time-stamp)))

(when (and do-package-update-on-init
           (y-or-n-p "Update all packages?"))
  (package-refresh-contents)

  (dolist (package
           '(ac-geiser         ; Auto-complete backend for geiser
             ac-slime          ; An auto-complete source using slime completions
             ace-jump-mode     ; quick cursor location minor mode
             auto-compile      ; automatically compile Emacs Lisp libraries
             auto-complete     ; auto completion
             elscreen          ; window session manager
             expand-region     ; Increase selected region by semantic units
             flx-ido           ; flx integration for ido
             ido-vertical-mode ; Makes ido-mode display vertically.
             geiser            ; GNU Emacs and Scheme talk to each other
             haskell-mode      ; A Haskell editing mode
             jedi              ; Python auto-completion for Emacs
             magit             ; control Git from Emacs
             markdown-mode     ; Emacs Major mode for Markdown-formatted files.
             matlab-mode       ; MATLAB integration with Emacs.
             monokai-theme     ; A fruity color theme for Emacs.
             move-text         ; Move current line or region with M-up or M-down
             multiple-cursors  ; Multiple cursors for Emacs.
             org               ; Outline-based notes management and organizer
             paredit           ; minor mode for editing parentheses
             powerline         ; Rewrite of Powerline
             pretty-lambdada   ; the word `lambda' as the Greek letter.
             smex              ; M-x interface with Ido-style fuzzy matching.
             undo-tree))       ; Treat undo history as a tree
    (upgrade-or-install-package package))
  ;; This package is only relevant for Mac OS X.
  (when (memq window-system '(mac ns))
    (upgrade-or-install-package 'exec-path-from-shell)))

(when (memq window-system '(mac ns))
  (setq mac-option-modifier nil
        mac-command-modifier 'meta
        x-select-enable-clipboard t)
  (exec-path-from-shell-initialize))

(dolist (feature
         '(auto-compile             ; auto-compile .el files
           auto-complete-config     ; a configuration for auto-complete-mode
           jedi                     ; auto-completion for python
           matlab                   ; matlab-mode
           ob-matlab                ; org-babel matlab
           ox-latex                 ; the latex-exporter (from org)
           ox-md                    ; Markdown exporter (from org)
           pretty-lambdada          ; show 'lambda' as the greek letter.
           recentf                  ; recently opened files
           tex-mode))               ; TeX, LaTeX, and SliTeX mode commands
  (require feature))

(setq initial-scratch-message nil     ; Clean scratch buffer.
      inhibit-startup-message t       ; No splash screen please.
      default-input-method "TeX"      ; Use TeX when toggeling input method.
      ring-bell-function 'ignore      ; Quite as a mouse.
      doc-view-continuous t           ; At page edge goto next/previous.
      echo-keystrokes 0.1)            ; Show keystrokes asap.

;; Some mac-bindings interfere with Emacs bindings.
(when (boundp 'mac-pass-command-to-system)
  (setq mac-pass-command-to-system nil))

(setq-default fill-column 76                    ; Maximum line width.
              indent-tabs-mode nil              ; Use spaces instead of tabs.
              split-width-threshold 100         ; Split verticly by default.
              auto-fill-function 'do-auto-fill) ; Auto-fill-mode everywhere.

(let ((default-directory (concat user-emacs-directory "site-lisp/")))
  (when (file-exists-p default-directory)
    (normal-top-level-add-to-load-path '("."))
    (normal-top-level-add-subdirs-to-load-path)))

(fset 'yes-or-no-p 'y-or-n-p)

(defvar emacs-autosave-directory
  (concat user-emacs-directory "autosaves/")
  "This variable dictates where to put auto saves. It is set to a
  directory called autosaves located wherever your .emacs.d/ is
  located.")

;; Sets all files to be backed up and auto saved in a single directory.
(setq backup-directory-alist
      `((".*" . ,emacs-autosave-directory))
      auto-save-file-name-transforms
      `((".*" ,emacs-autosave-directory t)))

(set-language-environment "UTF-8")

(put 'narrow-to-region 'disabled nil)

(ac-config-default)

(add-hook 'doc-view-mode-hook 'auto-revert-mode)

(dolist (mode
         '(tool-bar-mode                ; No toolbars, more room for text.
           scroll-bar-mode              ; No scroll bars either.
           blink-cursor-mode))          ; The blinking cursor gets old.
  (funcall mode 0))

(dolist (mode
         '(abbrev-mode                ; E.g. sopl -> System.out.println.
           auto-compile-on-load-mode  ; Compile .el files on load ...
           auto-compile-on-save-mode  ; ... and save.
           column-number-mode         ; Show column number in mode line.
           delete-selection-mode      ; Replace selected text.
           recentf-mode               ; Recently opened files.
           show-paren-mode            ; Highlight matching parentheses.
           global-undo-tree-mode      ; Undo as a tree.
           desktop-save-mode          ; Saves emacs session
           global-visual-line-mode))  ; Break lines for viewing pleasure
  (funcall mode 1))

(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

(load-theme 'monokai t)

(when (member "Inconsolata-g" (font-family-list))
  (set-face-attribute 'default nil :font "Inconsolata-g-11"))

(setq-default
 mode-line-format
 '("%e"
   (:eval
    (let* ((active (powerline-selected-window-active))
           ;; left hand side displays Read only or Modified.
           (lhs (list (powerline-raw
                       (cond (buffer-read-only "Read only")
                             ((buffer-modified-p) "Modified")
                             (t "")) nil 'l)))
           ;; right side hand displays (line,column).
           (rhs (list
                 (powerline-raw
                  (concat
                   "(" (number-to-string (line-number-at-pos))
                   "," (number-to-string (current-column)) ")") nil 'r)))
           ;; center displays buffer name.
           (center (list (powerline-raw "%b" nil))))
      (concat (powerline-render lhs)
              (powerline-fill-center nil (/ (powerline-width center) 2.0))
              (powerline-render center)
              (powerline-fill nil (powerline-width rhs))
              (powerline-render rhs))))))

(require 'smooth-scroll)
(smooth-scroll-mode t)

(dolist (mode
         '(ido-mode                   ; Interactivly do.
           ido-everywhere             ; Use Ido for all buffer/file reading.
           ido-vertical-mode          ; Makes ido-mode display vertically.
           flx-ido-mode))             ; Toggle flx ido mode.
  (funcall mode 1))

(setq ido-file-extensions-order
      '(".el" ".scm" ".lisp" ".java" ".c" ".h" ".org" ".tex"))

(add-to-list 'ido-ignore-buffers "*Messages*")

(smex-initialize)
(global-set-key (kbd "M-x") 'smex)

(defun calendar-show-week (arg)
  "Displaying week number in calendar-mode."
  (interactive "P")
  (copy-face font-lock-constant-face 'calendar-iso-week-face)
  (set-face-attribute
   'calendar-iso-week-face nil :height 0.7)
  (setq calendar-intermonth-text
        (and arg
             '(propertize
               (format
                "%2d"
                (car (calendar-iso-from-absolute
                      (calendar-absolute-from-gregorian
                       (list month day year)))))
               'font-lock-face 'calendar-iso-week-face))))

(calendar-show-week t)

(setq calendar-week-start-day 1
      calendar-latitude 60.0
      calendar-longitude 10.7
      calendar-location-name "Oslo, Norway")

(defvar load-mail-setup nil)

(when load-mail-setup
  ;; We need mu4e
  (require 'mu4e)

  ;; Some basic mu4e settings.
  (setq mu4e-maildir           "~/.ifimail"     ; top-level Maildir
        mu4e-sent-folder       "/INBOX.Sent"    ; folder for sent messages
        mu4e-drafts-folder     "/INBOX.Drafts"  ; unfinished messages
        mu4e-trash-folder      "/INBOX.Trash"   ; trashed messages
        mu4e-refile-folder     "/INBOX.Archive" ; saved messages
        mu4e-get-mail-command  "offlineimap"    ; offlineimap to fetch mail
        mu4e-compose-signature "- Lars"         ; Sign my name
        mu4e-update-interval   (* 5 60)         ; update every 5 min
        mu4e-confirm-quit      nil              ; just quit
        mu4e-view-show-images  t                ; view images
        mu4e-html2text-command
        "html2text -utf8")                      ; use utf-8

  ;; Setup for sending mail.
  (setq user-full-name
        "Lars Tveito"                        ; Your full name
        user-mail-address
        "larstvei@ifi.uio.no"                ; And email-address
        smtpmail-smtp-server
        "smtp.uio.no"                        ; Host to mail-server
        smtpmail-smtp-service 465            ; Port to mail-server
        smtpmail-stream-type 'ssl            ; Protocol used for sending
        send-mail-function 'smtpmail-send-it ; Use smpt to send
        mail-user-agent 'mu4e-user-agent)    ; Use mu4e!

  ;; Register file types that can be handled by ImageMagick.
  (when (fboundp 'imagemagick-register-types)
    (imagemagick-register-types))

  (defadvice mu4e (before show-mu4e (arg) activate)
    "Always show mu4e in fullscreen and remember window
configuration."
    (unless arg
      (window-configuration-to-register :mu4e-fullscreen)
      (mu4e-update-mail-and-index t)
      (delete-other-windows)))

  (defadvice mu4e-quit (after restore-windows nil activate)
    "Restore window configuration."
    (jump-to-register :mu4e-fullscreen))

  ;; Overwrite the native 'compose-mail' binding to 'show-mu4e'.
  (global-set-key (kbd "C-x m") 'mu4e))

(add-hook 'text-mode-hook 'turn-on-flyspell)

(add-hook 'prog-mode-hook 'flyspell-prog-mode)
(ac-flyspell-workaround)

(defvar ispell-languages '#1=("english" "norsk" . #1#))

(defun cycle-languages ()
  "Changes the ispell-dictionary to whatever is the next (or cdr) in the
LANGUAGES (cyclic) list."
  (interactive)
  (ispell-change-dictionary
   (car (setq ispell-languages (cdr ispell-languages)))))

(setq org-agenda-start-on-weekday nil              ; Show agenda from today.
      org-agenda-files '("~/Dropbox/life.org")     ; A list of agenda files.
      org-agenda-default-appointment-duration 120) ; 2 hours appointments.

(setq org-src-fontify-natively t)

(defun recentf-ido-find-file ()
  "Find a recent file using Ido."
  (interactive)
  (let ((f (ido-completing-read "Choose recent file: " recentf-list nil t)))
    (when f
      (find-file f))))

(defun remove-whitespace-inbetween ()
  "Removes whitespace before and after the point."
  (interactive)
  (just-one-space -1))

(defun switch-to-shell ()
  "Jumps to eshell or back."
  (interactive)
  (if (string= (buffer-name) "*shell*")
      (switch-to-prev-buffer)
    (shell)))

(defun duplicate-thing ()
  "Ethier duplicates the line or the region"
  (interactive)
  (save-excursion
    (let ((start (if (region-active-p) (region-beginning) (point-at-bol)))
          (end   (if (region-active-p) (region-end) (point-at-eol))))
      (goto-char end)
      (unless (region-active-p)
        (newline))
      (insert (buffer-substring start end)))))

(defun tidy ()
  "Ident, untabify and unwhitespacify current buffer, or region if active."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
    (indent-region beg end)
    (whitespace-cleanup)
    (untabify beg (if (< end (point-max)) end (point-max)))))

(global-set-key (kbd "C-'")  'er/expand-region)
(global-set-key (kbd "C-;")  'er/contract-region)

(global-set-key (kbd "C-c e")  'mc/edit-lines)
(global-set-key (kbd "C-c a")  'mc/mark-all-like-this)
(global-set-key (kbd "C-c n")  'mc/mark-next-like-this)

(global-set-key (kbd "C-c m") 'magit-status)

(global-set-key (kbd "C-c SPC") 'ace-jump-mode)

(global-set-key (kbd "<M-S-up>")    'move-text-up)
(global-set-key (kbd "<M-S-down>")  'move-text-down)

(global-set-key (kbd "C-c s")    'ispell-word)
(global-set-key (kbd "C-c t")    'org-agenda-list)
(global-set-key (kbd "C-x k")    'kill-this-buffer)
(global-set-key (kbd "C-x C-r")  'recentf-ido-find-file)

(global-set-key (kbd "C-c l")    'cycle-languages)
(global-set-key (kbd "C-c j")    'remove-whitespace-inbetween)
(global-set-key (kbd "C-x t")    'switch-to-shell)
(global-set-key (kbd "C-c d")    'duplicate-thing)
(global-set-key (kbd "<C-tab>")  'tidy)

(defadvice eval-last-sexp (around replace-sexp (arg) activate)
  "Replace sexp when called with a prefix argument."
  (if arg
      (let ((pos (point)))
        ad-do-it
        (goto-char pos)
        (backward-kill-sexp)
        (forward-sexp))
    ad-do-it))

(defadvice turn-on-flyspell (around check nil activate)
  "Turns on flyspell only if a spell-checking tool is installed."
  (when (executable-find ispell-program-name)
    ad-do-it))

(defadvice flyspell-prog-mode (around check nil activate)
  "Turns on flyspell only if a spell-checking tool is installed."
  (when (executable-find ispell-program-name)
    ad-do-it))

(dolist (mode '(slime-repl-mode geiser-repl-mode))
  (add-to-list 'pretty-lambda-auto-modes mode))

(pretty-lambda-for-modes)

(dolist (mode pretty-lambda-auto-modes)
  ;; add paredit-mode to all mode-hooks
  (add-hook (intern (concat (symbol-name mode) "-hook")) 'paredit-mode))

(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)

(when (file-exists-p "~/quicklisp/slime-helper.elc")
  (load (expand-file-name "~/quicklisp/slime-helper.elc")))

(setq inferior-lisp-program "sbcl")

(add-hook 'slime-mode-hook 'set-up-slime-ac)
(add-hook 'slime-repl-mode-hook 'set-up-slime-ac)

(eval-after-load "auto-complete"
  '(add-to-list 'ac-modes 'slime-repl-mode))

(add-hook 'geiser-mode-hook 'ac-geiser-setup)
(add-hook 'geiser-repl-mode-hook 'ac-geiser-setup)
(eval-after-load "auto-complete"
  '(add-to-list 'ac-modes 'geiser-repl-mode))
(setq geiser-active-implementations '(racket))

(defun c-setup ()
  (local-set-key (kbd "C-c C-c") 'compile))

;;(require 'auto-complete-c-headers)
;(add-to-list 'ac-sources 'ac-source-c-headers)

(add-hook 'c-mode-common-hook 'c-setup)

(define-abbrev-table 'java-mode-abbrev-table
  '(("psv" "public static void main(String[] args) {" nil 0)
    ("sopl" "System.out.println" nil 0)
    ("sop" "System.out.printf" nil 0)))

(defun java-setup ()
  (abbrev-mode t)
  (setq-local compile-command (concat "javac " (buffer-name))))

(add-hook 'java-mode-hook 'java-setup)

(defun asm-setup ()
  (setq comment-start "#")
  (local-set-key (kbd "C-c C-c") 'compile))

(add-hook 'asm-mode-hook 'asm-setup)

(add-to-list 'auto-mode-alist '("\\.tex\\'" . latex-mode))

(add-to-list 'org-latex-packages-alist '("" "minted"))
(setq org-latex-listings 'minted)

(setq org-latex-pdf-process
      (mapcar
       (lambda (str)
         (concat "pdflatex -shell-escape "
                 (substring str (string-match "-" str))))
       org-latex-pdf-process))

(setcar (cdr (cddaar tex-compile-commands)) " -shell-escape ")

;; (setq jedi:server-command
;;       (cons "python3" (cdr jedi:server-command))
;;       python-shell-interpreter "python3")
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)
(add-hook 'python-mode-hook 'jedi:ac-setup)

(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)

(add-to-list 'matlab-shell-command-switches "-nosplash")
