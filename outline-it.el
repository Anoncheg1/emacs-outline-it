;;; outline-it.el --- Outline-based management for new types of documents -*- lexical-binding: t; -*-

;; Copyright (c) 2025 github.com/Anoncheg1,codeberg.org/Anoncheg
;;
;; Author: <github.com/Anoncheg1,codeberg.org/Anoncheg>
;; Keywords: outlines, hypermedia, text, faces
;; URL: https://orgmode.org
;; Package-Requires: ((emacs "26.1"))

;;; License

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Licensed under the GNU Affero General Public License, version 3 (AGPLv3)
;; <https://www.gnu.org/licenses/agpl-3.0.en.html>

;;; Commentary:
;; Add advices at loading!

;; Configuration:
;; (add-to-list 'load-path "/path/to/this/package/emacs-outline-it")
;; (require 'outline-it)
;; (add-hook 'outline-minor-mode-hook 'my/outline-minor-mode-hook) ; optional, for .emacs

;;
;; M-x outline-it-githubactionlog
;; M-x outline-it-python
;;
;; Recommend to bind: (keymap-local-set "C-c C-e" #'my/outline-hide-others)
;;
;;; Code:
;;; -- Code
(require 'outline)
(require 'org)

;; (setq outline-font-lock-faces (vconcat org-level-faces)) ; test: (progn (outline-back-to-heading) (outline-font-lock-face) )
;; (setq-local font-lock-defaults
;;               '(outline-font-lock-keywords t nil nil backward-paragraph))
;; (setq outline-minor-mode-highlight t)
;;; -- TAB key - indent.el configuration
(defvar outline-it--indent-line-function-original nil)

(defun my/outline-tab ()
  "Compare full line at cursor position with outline template for
header. [rooted]
Return 'noindent if success.
Uses `outline-regexp' variable."
  (interactive)
  (if (string-match outline-regexp
                (buffer-substring (line-beginning-position)
                                  (line-end-position)))
      (progn
        (outline-toggle-children)
      'noindent ; stop TAB sequence
      )
    ;; else - not header
    (indent--funcall-widened outline-it--indent-line-function-original)

    ;; (indent--funcall-widened (default-value 'indent-line-function)) ; outline-it--indent-line-function-original
    ;; (let ((old-indent (current-indentation)))
    ;;   (lisp-indent-line)
    ;;   ;; - align
    ;;   (let ((syn (syntax-class (syntax-after (point)))))
    ;;     (if (and (zerop (- (current-indentation) old-indent))
    ;;              (memql syn '(2 4 5)))
    ;;         (or (indent--default-inside-comment)
    ;;             (indent--funcall-widened 'indent-relative))
    ;;       ))
    ;; )
    )
  )

(defun my/outline-minor-mode-hook ()
  "Used for show/hide outline by indent-for-tab-command.
`outline-regexp' variable used.
Also configure isearch for C-M-s."
  (if outline-minor-mode
    (progn
      ;; - set
      (print "my/outline-minor-mode-hook1")
      (add-hook 'isearch-mode-hook 'my/outline-header-search nil t)

      ;; (when (and (buffer-file-name) (or (string-equal (file-name-nondirectory  (buffer-file-name)) ".emacs")
      ;;                                 (string-equal (file-name-nondirectory (buffer-file-name)) "init.el")))

      (unless outline-it--indent-line-function-original
        (setq-local outline-it--indent-line-function-original indent-line-function) ; save
        (setq-local indent-line-function #'my/outline-tab)))

    ;; else - restore
    (when outline-it--indent-line-function-original
      (print "my/outline-minor-mode-hook2")
        (setq-local indent-line-function outline-it--indent-line-function-original)
        (setq-local outline-it--indent-line-function-original nil))))

;; (add-hook 'outline-minor-mode-hook 'my/outline-minor-mode-hook)
;; (remove-hook 'outline-minor-mode-hook 'my/outline-mode-hook1)

;;; -- add C-u C-w behavior to copy only headers
(defun my/outline-copy-outline-headers (beg end &optional delete)
  "Copy outline headers between BEG and END that match `outline-regexp`.
Also copies lines before the first top-level outline.
If universal argument is set, only copy headers and pre-outline content.
Otherwise, copy all content using `buffer-substring--filter`.
Activated in outline-mode init hook."
  (if current-prefix-arg
      (let* ((content (buffer-substring-no-properties beg end))
             (lines (split-string content "\n" nil))
             (first-outline-index (catch 'found
                                    (let ((index 0))
                                      (dolist (line lines)
                                        (when (string-match-p outline-regexp line)
                                          (throw 'found index))
                                        (setq index (1+ index)))
                                      nil)))
             (pre-outline (if first-outline-index
                              (butlast lines (- (length lines) first-outline-index))
                            lines))
             (headers (delq nil (mapcar (lambda (line)
                                          (when (string-match-p outline-regexp line)
                                            (concat line " ...")))
                                        lines))))
        (string-join (append pre-outline headers) "\n"))
    ;; else - no prefix
    (buffer-substring--filter beg end delete)))
;;; -- outline-level - function, fix, that match full line from outline-heading-alist by default
;; (defun my/outline-string-prefix-p ()
;; (string-match REGEXP STRING
(defun my/outline-level ()
  "We add `string-match' for assoc as TESTFN to find level.
  Depends on `outline-regexp'."
  (let ((ma (substring-no-properties (match-string 0))))
  ;; (print outline-heading-alist)
  ;; (print ma)
  ;; (print (assoc ma outline-heading-alist 'string-match))
  ;; (outline-back-to-heading)
  (or (cdr (assoc ma outline-heading-alist 'string-match))
      (- (match-end 0) (match-beginning 0)))))

(defun my/outline-level2 ()
  "Return the depth to which a statement is nested in the outline.
Point must be at the beginning of a header line.
This is actually either the level specified in `outline-heading-alist'
or else the number of characters matched by `outline-regexp'."
  (or (cdr (assoc (match-string 0) outline-heading-alist))
      (- (match-end 0) (match-beginning 0))))

;; - set in buffer by
   ;; (setq-local outline-level #'my/outline-level)
;; - To test:
   ;; (progn (outline-back-to-heading t)
   ;;        (funcall outline-level))

;;; -- keys
;; same as my/org-fold-hide-other, but "sublevels 20"

;; (defun outline-back-to-heading (&optional invisible-ok)
;;   "Move to previous heading line, or beg of this line if it's a heading.
;; Only visible heading lines are considered, unless INVISIBLE-OK is non-nil."
;;   (forward-line 0)
;;   (or (outline-on-heading-p invisible-ok)
;;       (let (found
;;             (invisible-ok t))
;; 	(save-excursion
;; 	  (while (not found)
;; 	    (or (if outline-search-function
;;                     (funcall outline-search-function nil nil t)
;;                   (re-search-backward (concat "^\\(?:" outline-regexp "\\)")
;; 				      nil t))
;;                 (signal 'outline-before-first-heading nil))
;; 	    (setq found (and (or invisible-ok (not (outline-invisible-p)))
;; 			     (point)))))
;; 	(goto-char found)
;; 	found)))

(defun my/outline-hide-others ()
  "Hide other headers and don't hide headers and text in opened."
  (interactive)
  (print "start my/outline-hide-other")
  (save-excursion
    (outline-hide-sublevels 7) ;; hide all
    (outline-show-children) ;; show headers, not shure how and wehere,
    (outline-back-to-heading t) ;; to header in depths
    (outline-show-entry) ;; show local text
    (print "my/outline-hide-other1")
    (condition-case nil
        (progn
          (outline-up-heading 1 t) ;; go upper - signal warning
          ;; (print "my/outline-hide-other2")
          ;; (outline-show-entry)
          (while (> (progn ;; (outline-back-to-heading t)
                      (funcall outline-level))
                    1) ;; while not at first header
            (print (list "my/outline-hide-other3" (progn (outline-back-to-heading t)
                                                         (funcall outline-level))
                         (point)))
            (outline-show-entry)
            (outline-show-children) ;; show subheaders

            (condition-case nil
                (outline-up-heading 1 t) ;; go upper  - signal warning
              (error nil)
              )

            ))
            (error nil))))

;; (defun my/outline-tab-old ()
;;   "compare full line at cursor position with outline template for
;; header. [rooted]"
;;   (interactive)
;;   (if (and (and (boundp 'outline-minor-mode)
;;                 outline-minor-mode) ; if outline is active
;;            ;; and regex match line
;;            (string-match outline-regexp (buffer-substring (line-beginning-position) (line-end-position))))
;;       (outline-toggle-children)
;;     ;; else
;;     ;; (call-interactively #'indent-for-tab-command)
;;     ;; else
;;     (if (fboundp 'my/indent-or-complete)
;;         (progn
;;           (print "here my")
;;           (call-interactively 'my/indent-or-complete))
;;       ; else
;;       (print "outline default")
;;       (call-interactively 'indent-for-tab-command))
;;     ))

(defun my/outline-header-search ()
  "We use part of outline-regexp string to isearch in headers."
  (if isearch-regexp
      (progn
        (setq isearch-case-fold-search 1)   ; make searches case insensitive
        (setq case-fold-search 1)   ; make searches case insensitive
        (isearch-push-state)
        (let ((string
               (concat (car (string-split outline-regexp "\\\\|")) ".*")))
          (isearch-process-search-string
           string (mapconcat 'isearch-text-char-description string ""))))))

;;; - Old hook
(defun my/outline-mode-hook ()
  "for (add-hook 'outline-minor-mode-hook 'my/outline-mode-hook)
For `outline-minor-mode we set variables:
- `outline-regexp'
- `outline-heading-alist'
."
  ;; (print outline-regexp)
  ;; - Problem here: outline-minor mode do not respect 'outline-regexp' and somehow reinitialize it.

  ;; Case 1) .emacs - default
  (if (and (buffer-file-name) (or (string-equal (file-name-nondirectory  (buffer-file-name)) ".emacs")
                                  (string-equal (file-name-nondirectory (buffer-file-name)) "init.el")))
      (progn
       (setq-local outline-regexp ";; -- ")
       (setq-local outline-heading-alist
                   '((";; -- " . 1)
                     (";; -- -- " . 2)
                     (";; -- -- -- " . 3)
                     (";; -- -- -- -- " . 4)
                     (";; -- -- -- -- -- " . 5)
                     (";; -- -- -- -- -- -- " . 6))))
    ;; else - Case 2) multilevel: outline-it-heading-alist + outline-regexp
    (if (bound-and-true-p  outline-it-heading-alist)
        ;; for `outline-it-python'
        (setq-local outline-heading-alist outline-it-heading-alist)

        ;; else - Case 2) one level: outline-regexp - for programming modes where only one level required
        (setq-local outline-heading-alist
                    (list (cons outline-regexp 1)))))

  ;; (setq outline-heading-end-regexp "\n")
  ;; (define-key outline-minor-mode-map (kbd "C-x i") 'outline-toggle-children) ;;
  ;; (define-key outline-minor-mode-map (kbd "C-c TAB") 'outline-toggle-children) ;;
  (keymap-local-set "<backtab>" 'outline-cycle-buffer) ;; S-tab
  (keymap-local-set "C-c C-e" 'my/outline-hide-others) ;; hides `elisp-eval-region-or-buffer'
  ;; (keymap-local-set "C-c TAB" 'outline-hide-body)
  ;; (define-key outline-minor-mode-map [S-tab] 'outline-show-all)
  ;; (outline-hide-body)
  (setq outline-default-state 'outline-show-only-headings)
  (outline-apply-default-state)
  (add-hook 'isearch-mode-hook 'my/outline-header-search nil t) ;; LOCAL = t
  ;; - activate outline-heading-alistheader leavels
  ;; (setq outline-level #'outline-level)
  ;; - TAB key

  ;; (keymap-local-set "TAB" 'my/outline-tab) ;; rooted - wrong
  ;;
  ;; - Add behavior of C-u C-w to copy only headers
  (setq-local filter-buffer-substring-function #'my/outline-copy-outline-headers)
  )

;; (add-hook 'outline-minor-mode-hook 'my/outline-mode-hook)
;; (remove-hook 'outline-minor-mode-hook 'my/outline-mode-hook)
;;; -- fixes for other modes
;;; -- -- C-, xref jump
(defun outline-it--fix-xref-outline (orig-fun &rest args)
  "Fix bug when we jump C-, to place hidden header."
  (apply orig-fun args)
  (when (eq (get-char-property (point) 'invisible) 'outline)
      ;; (bound-and-true-p outline-minor-mode)
    ;; (outline-show-all)
    ;; (outline-hide-other)
    (outline-hide-body)
    ;; (outline-hide-sublevels 7)
    (outline-show-entry)
    ))

;; ;;; -- -- Backtrace clicks (old)
;; (defun my/outline-help-function-def(&rest r)
;;   "Fix clicking buttons in Backtrace.
;; Executed for buffer with
;; - outline-minor-mode activated.
;; - .emacs files
;; - elisp files with .dir-locals.el file in current directory."
;;   (when (or (bound-and-true-p outline-minor-mode)
;;             (and (derived-mode-p 'emacs-lisp-mode)
;;                  (buffer-file-name)
;;                  (or
;;                      (file-exists-p (expand-file-name ".dir-locals.el" default-directory))
;;                      (and (buffer-file-name) (or (string-equal (file-name-nondirectory  (buffer-file-name)) ".emacs")
;;                                                  (string-equal (file-name-nondirectory (buffer-file-name)) "init.el"))))))
;;     (outline-show-all)
;;     (my/outline-hide-others)))

;;; -- -- advices activation
;; dont depend on outline-minor-mode
(advice-add 'xref-find-definitions :around #'outline-it--fix-xref-outline)
(advice-add 'xref-go-back :around #'outline-it--fix-xref-outline)
(advice-add 'goto-line :around #'outline-it--fix-xref-outline)
(advice-add 'compile-goto-error :around #'outline-it--fix-xref-outline)
(advice-add 'help-function-def--button-function :around #'outline-it--fix-xref-outline)
(advice-add 'set-mark-command :after #'my/outline-set-mark-command)
;; depend on outline-minor-mode
;; (advice-add 'help-function-def--button-function :after #'my/outline-help-function-def)
;;; -- -- C-u C-SPC set-mark-command
(defun my/outline-set-mark-command(arg)
  "Fix clicking buttons in Backtrace."
  (when (and (bound-and-true-p outline-minor-mode)
             arg)
    (outline-show-all)
    (my/outline-hide-others)))


;; (advice-remove 'set-mark-command #'my/outline-set-mark-command)

;;; -- variant of fix for `outline-hide-other' (not used)
;; (defun my/outline-hide-other-after (&rest r)
;;   "Show subheaders and headers at current tree after hidding.
;; After outline-show-entry that hide all and bottom."
;;   ;; show all at bottom, undo
;;   (save-excursion
;;     (outline-flag-region (point)
;;                          (point-max)
;;                          nil))

;;   ;; hide subtrees
;;   (save-excursion
;;     (outline-back-to-heading t)
;;     (let ((level (funcall outline-level))
;;           (level-current)
;;           (run t))
;;       ;; check first subheader manually, it may have deeper level.
;;       (when (outline-next-heading)
;;         (outline-hide-subtree)
;;         (setq level (funcall outline-level)))

;;       (while (and run (outline-next-heading))
;;             (setq level-current (funcall outline-level))
;;             (when (>= level level-current) ; go to up
;;               (outline-hide-subtree)
;;               (when (> level level-current)
;;                 (setq level level-current))))
;;         )))
;; (advice-add 'outline-hide-other :after #'my/outline-hide-other-after)


;;; -- fix for goto-line (old)
;; (defun my/goto-line-advice (orig-fun &rest args)
;;   "Fix to unwrap outline.
;; Double call, first call set cursor at wrapped line, second at
;; unwrapped."
;;   (when (bound-and-true-p outline-minor-mode)
;;     (apply orig-fun args)
;;     (outline-show-entry))
;;   (apply orig-fun args))

;; (advice-add 'goto-line :around #'my/goto-line-advice)
;; (advice-remove 'goto-line #'my/goto-line-advice)
;;; -- Main
(defun outline-it (&optional outline-r outline-it-heading-alist force-fontify)
  "Activate outline-minor mode with custom regex for header.
Executed for current buffer.
Provide:
- fonts for headers
- wrap `indent-line-function' to call `outline-toggle-children' if cursor is at header

Uses two variables:
- OUTLINE-R - define one level, should be regex to match begining of heading.

- OUTLINE-IT-HEADING-ALIST (optional) - define levels by begining or
substring of  header, should consist  of quoted regex strings  for usage
with `string-math'  use `regexp-quote' to escape  regex characters.  May
have ^ at the begining or not.
if FORCE-FINTIFY is non-nil - outline fontification for modes with own
font-lock overrided with outline mode fonts for `outline-regexp'."
  (interactive)
  (print (list "outline-it"  outline-r outline-it-heading-alist))
  ;; - clear outline-regexp if only outline-heading-alist used
  ;; (setq-local outline-regexp "")

  ;; - deactivation outline
  (outline-minor-mode -1)

  ;; - set outline variables
  (cond

        ;; else - Case 1) multilevel: outline-it-heading-alist (no outline-regexp)
        ((and outline-it-heading-alist (not outline-r))
         ;; (setq-local outline-regexp "")
         (setq-local outline-regexp (string-join (mapcar (lambda (el) (car el)) outline-heading-alist) "\\|"))
         (setq-local outline-heading-alist outline-it-heading-alist)
         (print (list "case2" outline-heading-alist outline-r)))
        ;; Case 2) one level: outline-regexp  (no outline-it-heading-alist)
        ((and outline-r (not outline-it-heading-alist))
         (print "case2")
         ;; (setq-local outline-heading-alist nil)
         (setq-local outline-regexp outline-r)
         (setq-local outline-heading-alist
                     (list (cons outline-regexp 1))))

        ((and (buffer-file-name) (or (string-equal (file-name-nondirectory (buffer-file-name)) ".emacs")
                                     (string-equal (file-name-nondirectory (buffer-file-name)) "init.el")))
         (print "case3")
         (setq-local outline-regexp ";; -- ")
         (setq-local outline-heading-alist
                     '((";; -- " . 1)
                       (";; -- -- " . 2)
                       (";; -- -- -- " . 3)
                       (";; -- -- -- -- " . 4)
                       (";; -- -- -- -- -- " . 5)
                       (";; -- -- -- -- -- -- " . 6))))
        ((and outline-r outline-it-heading-alist)
         (setq-local outline-regexp outline-r)
         (setq-local outline-heading-alist outline-it-heading-alist))

        (t
         (user-error "outline-it was called without argumens, it don't know what to do.")
           ;; (setq-local outline-heading-alist
           ;;             (list (cons outline-regexp 1))))
        ))
  (setq outline-default-state 'outline-show-only-headings)
  ;; - Keys
  (keymap-set outline-minor-mode-map "<backtab>" 'outline-cycle-buffer) ;; S-tab
  (keymap-set outline-minor-mode-map "C-c C-e" 'my/outline-hide-others) ;; hides `elisp-eval-region-or-buffer'
  ;; (keymap-local-set "C-c TAB" 'outline-hide-body)
  ;; (define-key outline-minor-mode-map [S-tab] 'outline-show-all)
  ;; (outline-hide-body)


  ;; - activate outline-heading-alistheader leavels
  ;; (setq outline-level #'outline-level)
  ;; - TAB key

  ;; (keymap-local-set "TAB" 'my/outline-tab) ;; rooted - wrong
  ;;
  ;; - Add behavior of C-u C-w to copy only headers
  (setq-local filter-buffer-substring-function #'my/outline-copy-outline-headers)
  ;; fix match that search in outline-heading-alist by matching whole
  (setq-local outline-level #'my/outline-level)

  ;; - activate outline

  ;; (setq-local outline-regexp outline-r)
  ;; (setq-local outline-it-heading-alist outline-r)

  ;; - font lock configuration - uses outline-it-heading-alist or outline-regexp.
  ;; (font-lock-refresh-defaults)
  ;; (setq-local outline-font-lock-faces (vconcat org-level-faces)) ; test: (progn (outline-back-to-heading) (outline-font-lock-face) )
  ;; (font-lock-add-keywords nil outline-font-lock-keywords)
  ;; (setq-local font-lock-defaults
  ;;             '(outline-font-lock-keywords t nil nil backward-paragraph))
  (setq-local outline-minor-mode-highlight t) ; fontify in fundamental and text mode only

  (outline-minor-mode 1)
  (when force-fontify
    (outline-it-minor-mode-highlight-buffer)
    (add-hook 'revert-buffer-restore-functions
              #'outline-revert-buffer-rehighlight nil t))

  ;; hide headers according to `outline-default-state' variable
  (outline-apply-default-state)

  ;; - TAB key configuration to show entry
  (unless outline-it--indent-line-function-original
    (setq-local outline-it--indent-line-function-original indent-line-function) ; save
    (setq-local indent-line-function #'my/outline-tab))
   ; used by indent-for-tab-step-5-indent-line called by TAB key indent-for-tab-command

  ;; (when (boundp (intern "indent-for-tab-steps"))
  ;;   (unless (memq (intern "indent-for-tab-steps")
  ;;   (append indent-for-tab-steps (outline-toggle-children)


  ;; (let (reg fac
  ;;           (org-l 1)
  ;;       )
    ;; 1) outline-it-heading-alist
  ;; (if (bound-and-true-p  outline-it-heading-alist)
  ;;     ;; outline-it-heading-alist
  ;;     (progn
  ;;       ;; (setq reg (string-split outline-regexp "\\\\|"))
  ;;       (setq reg (mapcar (lambda (x)
  ;;                           (concat
  ;;                            (if (string-prefix-p "^" (car x)) "" ".*")
  ;;                            ".*" (car x) ".*")) outline-it-heading-alist))
  ;;       (print (list "reg0" reg))
  ;;       (dolist (reg_one reg)
  ;;         (setq fac (nth (% (1- org-l) org-n-level-faces) org-level-faces))
  ;;         (setq org-l (+ org-l 1))
  ;;         (print (list "reg1" reg_one fac))
  ;;         (font-lock-add-keywords
  ;;          nil
  ;;          ;; (list (cons reg_one (quote fac)))
  ;;          (list (list reg_one #'quote fac))
  ;;          ))
  ;;       ;; (setq reg (string-join reg "\\|"))
  ;;       )
  ;;     ;; 2) else use - outline-regexp
  ;;     (setq reg (string-split outline-regexp "\\\\|"))
  ;;     (setq reg (mapcar (lambda (x) (concat x ".*")) reg))
  ;;     (setq reg (string-join reg "\\|"))
  ;;     (print (list "reg2" reg))
  ;;     (font-lock-add-keywords
  ;;      nil
  ;;      (list (cons reg (quote 'org-level-1)))))
  ;; (progn (font-lock-mode -1)
  ;;        (font-lock-mode 1))
  )

;; (defun outline-minor-mode-highlight-buffer ()
;;   ;; Fallback to overlays when font-lock is unsupported.
;;   (save-excursion
;;     (goto-char (point-min))
;;     (let ((regexp (unless outline-search-function
;;                     (concat "^\\(?:" outline-regexp "\\).*$"))))
;;       (while (if outline-search-function
;;                  (funcall outline-search-function)
;;                (re-search-forward regexp nil t))

;;         (let ((overlay (make-overlay (match-beginning 0) (match-end 0))))

;;           (overlay-put overlay 'outline-highlight t)
;;           ;; >>> Set priority high so it overrides font-lock <<<
;;           ;; (overlay-put overlay 'priority 1)
;;           ;; (overlay-put overlay 'face (outline-font-lock-face))
;;           ;; >>> Optionally, nuke underlying text properties <<<

;;           ;; FIXME: Is it possible to override all underlying face attributes?
;;           ;; (when (or (memq outline-minor-mode-highlight '(append override))
;;           ;;           (and (eq outline-minor-mode-highlight t)
;;           ;;                (not (get-text-property (match-beginning 0) 'face))))
;;           ;;   (overlay-put overlay 'face (outline-font-lock-face)))
;;           (remove-text-properties (match-beginning 0) (match-end 0) '(face nil))
;;           )
;;         (goto-char (match-end 0))))))

(defun outline-it-minor-mode-highlight-buffer ()
  "Highlight outline headers using overlays, with priority and explicit face."
  (save-excursion
    (goto-char (point-min))
    (let ((regexp (unless outline-search-function
                    (concat "^\\(?:" outline-regexp "\\).*$"))))
      (while (if outline-search-function
                 (funcall outline-search-function)
               (re-search-forward regexp nil t))
        (let ((overlay (make-overlay (match-beginning 0) (match-end 0))))
          (overlay-put overlay 'outline-highlight t)
          ;; >>> Set priority high so it overrides font-lock <<<
          (overlay-put overlay 'priority 100)
          ;; >>> Optionally, force a non-inherited face <<
          ;; (overlay-put overlay 'face
          ;;              (list :inherit nil
          ;;                    :background "yellow"
          ;;                    :foreground "black"
          ;;                    :weight 'bold))
          ;; If you want to use a face defined elsewhere:
          (overlay-put overlay 'face (outline-font-lock-face))
          ;; (when (or (memq outline-minor-mode-highlight '(append override))
          ;;           (and (eq outline-minor-mode-highlight t)
          ;;                (not (get-text-property (match-beginning 0) 'face))))
          ;;   (overlay-put overlay 'face (outline-font-lock-face)))
          ;; >>> Optionally, nuke underlying text properties <<<
          ;; (remove-text-properties (match-beginning 0) (match-end 0) '(face nil))
          )
        ;; (goto-char (match-end 0))
        )
      ;; No need for (goto-char ...) after (re-search-forward)
      )))

;; (advice-remove 'outline-minor-mode-highlight-buffer #'outline-it-minor-mode-highlight-buffer)

;;; -- implementations
(defun outline-it-python ()
  (interactive)
  ;; (setq-local outline-it-heading-alist '(("class" . 1) ("def" . 2)))
  (outline-it "^class\\|.* def "
              '(("^class" . 1) (".*def " . 2))
              ))


(defun outline-it-githubactionlog ()
  "For Github Action Melpazoid log.
where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (conf-mode)
  (outline-it "^# -- \\|.*##\\[group]\\|.*⸺ "
              '(("^# -- " . 1) ("##\\[group]" . 2) ("⸺ " . 3)))
              t ; force-fintify
              )

(defun outline-it-bash ()
  "For Github Action Melpazoid log.
where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (outline-it "^# -- "
              '(("^# -- " . 1))))


;;; ? org bug ?
;; (advice-remove 'outline-back-to-heading 'fix-for-org-fold)

;;; provide
(provide 'outline-it)

;;; outline-it.el ends here
