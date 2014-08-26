
(require 'package)
(setq package-enable-at-startup nil)
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
      (and (assq package package-archive-contents)
           (package-install package)))))

(defvar days-between-updates 7)
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
           '(ac-geiser                       ; Auto-complete backend for geiser
             ac-slime                        ; An auto-complete source using slime completions
             ace-jump-mode                   ; quick cursor location minor mode
             auto-compile                    ; automatically compile Emacs Lisp libraries
             auto-complete                   ; auto completion
             auto-complete-c-headers         ; autocomplete c-header files.
             elscreen                        ; window session manager
             expand-region                   ; Increase selected region by semantic units
             flx-ido                         ; flx integration for ido
             ido-vertical-mode               ; Makes ido-mode display vertically.
             geiser                          ; GNU Emacs and Scheme talk to each other
             haskell-mode                    ; A Haskell editing mode
             jedi                            ; Python auto-completion for Emacs
             magit                           ; control Git from Emacs
             markdown-mode                   ; Emacs Major mode for Markdown-formatted files.
             matlab-mode                     ; MATLAB integration with Emacs.
             monokai-theme                   ; A fruity color theme for Emacs.
             move-text                       ; Move current line or region with M-up or M-down
             multiple-cursors                ; Multiple cursors for Emacs.
             org                             ; Outline-based notes management and organizer
             paredit                         ; minor mode for editing parentheses
             powerline                       ; Rewrite of Powerline
             pretty-lambdada                 ; the word `lambda' as the Greek letter.
             smex                            ; M-x interface with Ido-style fuzzy matching.
             undo-tree                       ; Treat undo history as a tree
             smooth-scroll                   ; Smoth scrolling
             flycheck                        ; On the fly compilation
             flymake-google-cpplint          ; flymake with google
             flymake-cursor                  ; Show syntax warnings at cursor.
             google-c-style                  ; C-style settings for flymake. 
             ))
    (upgrade-or-install-package package))

  ;; This package is only relevant for Mac OS X.
  (when (memq window-system '(mac ns))
    (upgrade-or-install-package 'exec-path-from-shell))
  (package-initialize))

(cond ((member "Droid Sans Mono" (font-family-list))
       (set-face-attribute 'default nil :font "Droid Sans Mono-10"))
      ((member "Inconsolata" (font-family-list))
       (set-face-attribute 'default nil :font "Inconsolata-10")))

(require 'smooth-scroll)
(smooth-scroll-mode t)

(global-set-key (kbd "C-c s")    'ispell-word)
(global-set-key (kbd "C-c t")    'org-agenda-list)
(global-set-key (kbd "C-x k")    'kill-this-buffer)
(global-set-key (kbd "C-x C-r")  'recentf-ido-find-file)
(global-set-key (kbd "C-S-k")  '(lambda () (interactive) (kill-line 0)))
