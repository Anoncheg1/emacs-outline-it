;;; outline-it.el --- Outline mode is enhanced and prepared for use with anything -*- lexical-binding: t; -*-

;; Copyright (c) 2025 github.com/Anoncheg1,codeberg.org/Anoncheg
;;
;; Author: <github.com/Anoncheg1,codeberg.org/Anoncheg>
;; Keywords: outlines, hypermedia, text, faces
;; URL: https://orgmode.org
;; Package-Requires: ((emacs "30.1"))
;; Version: 0.1
;
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

;; Theare are tree types of usage that may be mixed.
;; 1) by M-x outline-it, or with prepared (outline-it "regex") elisp
;;   call, that activate `outline-minor-mode' for current buffer.
;; 2) to enhance `outline-minor-mode', we add hook to it
;; 3) enhance outline related functionality globally
;;
;; Configuration for 1,2,3)
;; 1) for manual activation by `outline-it'
;; (add-to-list 'load-path "/path/to/this/package/emacs-outline-it")
;; (require 'outline-it)

;; 2) for all outline-minor modes or per some major mode:
;; (add-hook 'outline-minor-mode-hook 'outline-it-outline-minor-mode-hook-function)
;; (outline-it-advices-activation)

;; 3) for enhancing outline functionality that works without any activation
;; (add-hook 'isearch-mode-hook #'outline-it--header-search)
;; (outline-it-advices-activation)
;;
;; Usage:
;; M-x outline-it-githubactionlog
;; M-x outline-it-python
;; M-x outline-it

;; To deactivate:
;; ...
;;
;; for outline-it-any-mode-hook-function:
;; M-x outline-it-advices-deactivation

;; ;; in Elisp shadows `elisp-eval-region-or-buffer'
;; Recommend to bind: (keymap-local-set "C-c C-e" #'outline-it-hide-others)

;;; TODO: implement full deactivation for `outline-it' function

;; Other packages:
;; - Navigation in major modes https://github.com/Anoncheg1/firstly-search
;; - Search with Chinese	https://github.com/Anoncheg1/pinyin-isearch
;; - Ediff no 3-th window	https://github.com/Anoncheg1/ediffnw
;; - Dired history		https://github.com/Anoncheg1/dired-hist
;; - Selected window contrast	https://github.com/Anoncheg1/selected-window-contrast
;; - Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
;; - Solution for "callback hell" https://github.com/Anoncheg1/emacs-async1
;; - Restore buffer state	 https://github.com/Anoncheg1/emacs-unmodified-buffer1
;; - Call LLMs & AI from Org-mode blocks.  https://github.com/Anoncheg1/emacs-oai

;; Donate:
;; - BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
;; - USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
;; - TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D

;;; Code:
;; Touch: And God saw that it was good.
;; -= Includes
(require 'outline)
(require 'org)

;; -= TAB key - indent.el configuration
(defvar outline-it--indent-line-function-original nil)

;;;###autoload
(defun outline-it-toggle ()
  "If current position is at outline line, show or hide it.
Wrap original `indent-line-function' explicitly.
Used for TAB key.
Compare full line with `outline-regexp' variable.
Return noindent symbol if success.
Also called from `indent-according-to-mode'"
  (interactive)
  ;; check if at header
  (if (save-excursion (beginning-of-line)
                      (let ((p (point)))
                        (condition-case nil
                            (progn
                              (outline-back-to-heading)
                              (eq p (point)))
                          (error nil))))
      (progn
        ;; (print "outline-it-toggle1")
        (outline-toggle-children)
        'noindent ; stop TAB sequence
        )
    ;; else - not header, call original
    ;; (print (list "outline-it-toggle2" outline-it--indent-line-function-original))
    (indent--funcall-widened outline-it--indent-line-function-original)))

;; -= minor-mode-hook - for isearch and TAB key

(defun outline-it--header-search ()
  "We use part of `outline-regexp' string to isearch in headers.
`outline-regexp' should not start with ^ character."
  (when (and isearch-regexp (not (derived-mode-p 'dired-mode)))
        ;; (setq isearch-case-fold-search 1)   ; make searches case insensitive
        ;; (setq case-fold-search 1)   ; make searches case insensitive
        ;; (isearch-push-state)
        (let* ((string
               (concat "^" (car (string-split outline-regexp "\\\\|")) ".*")))
          (isearch-push-state)
          (isearch-process-search-string
           string (mapconcat #'isearch-text-char-description string "")))))

(defun outline-it-outline-minor-mode-hook-function ()
  "Used for show/hide outline by `indent-for-tab-command'.
When `outline-minor-mode' activated set:
1) `indent-line-function'
2) `isearch-string' for isearch searching by headers with C-M-s
 `isearch-forward-regexp'.
Uses `outline-regexp' variable"
  (if outline-minor-mode
    (progn
      ;; (print "outline-it-outline-minor-mode-hook1")
      (unless (member #'outline-it--header-search isearch-mode-hook) ; Check global hook
        (add-hook 'isearch-mode-hook #'outline-it--header-search nil t)) ; Add hook locally

      (unless outline-it--indent-line-function-original
        (setq-local outline-it--indent-line-function-original indent-line-function) ; save
        (setq-local indent-line-function #'outline-it-toggle)))

    ;; else - restore
    (remove-hook 'isearch-mode-hook #'outline-it--header-search t)
    (when outline-it--indent-line-function-original
      ;; (print "outline-it-outline-minor-mode-hook2")
        (setq-local indent-line-function outline-it--indent-line-function-original)
        (setq-local outline-it--indent-line-function-original nil))))

(defun outline-it-any-mode-hook-function ()
  "Isearch and TAB key configuration without usage of minor mode."
  (let ((outline-minor-mode t)) (outline-it-outline-minor-mode-hook-function)))

;; -= add C-u C-w behavior to copy only headers
(defun outline-it-copy-outline-headers (beg end &optional delete)
  "Copy outline headers between BEG and END that match `outline-regexp`.
Also copies lines before the first top-level outline.
If universal argument is set, only copy headers and pre-outline content.
Otherwise, copy all content using `buffer-substring--filter`.
Activated in `outline-mode' init hook.
If DELETE is non-nil, it should delete the text between BEG and END from
the buffer, as stated in `filter-buffer-substring-function', it is TODO."
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
;; -= outline-level - function, fix, that match full line from outline-heading-alist by default
(defun outline-it--outline-level ()
  "Rewrite of function `outline-level'.
We add `string-match' for assoc as TESTFN to find level.
Depends on `outline-regexp'."
  (let ((ma (substring-no-properties (match-string 0))))
    (or (cdr (assoc ma outline-heading-alist 'string-match))
        (- (match-end 0) (match-beginning 0)))))

;; - test:
;; (defvar outline-heading-alist2
;;   '((";;; " . 1) (";; -= " . 2)))
;; (print outline-heading-alist)
;; (cadr outline-heading-alist)
;; (assoc "^;;; " (eval outline-heading-alist) (lambda (a b) "outline-it--outline-level" (string-match (regexp-quote (car a)) b)))
;; (assoc ";; -= " outline-heading-alist 'string-match)
;; (assoc ";; -= " '((";;; " . 1) (";; -= " . 2)) 'string-match)
;; -= hide-other
;; 1) fix for Org mode
;; (progn (outline-back-to-heading)

;;         ;; (match-string 0)) ";; -= "
;;        (funcall #'outline-level))
;; (outline-map-region (lambda ()
;;                       ;; (outline-back-to-heading)
;;                       (print (list (funcall outline-level) (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))
;;                                       (point-min) (point-max) )

;; FIX FOR (funcall outline-level) - that breaks match data and not working properly
(defun outline-it-hide-sublevels (levels)
  "Hide everything but the top LEVELS levels of headers, in whole buffer.
This also unhides the top heading-less body, if any.

Interactively, the prefix argument supplies the value of LEVELS.
When invoked without a prefix argument, LEVELS defaults to the level
of the current heading, or to 1 if the current line is not a heading."
  (interactive (list
		(cond
		 (current-prefix-arg (prefix-numeric-value current-prefix-arg))
		 ((save-excursion
                    (forward-line 0)
		    (if outline-search-function
                        (funcall outline-search-function nil nil nil t)
                      (looking-at outline-regexp)))
		  (funcall #'outline-level))
		 (t 1))))
  (if (< levels 1)
      (error "Must keep at least one level of headers"))
  (save-excursion
    (let* ( ; outline-view-change-hook1
           (beg (progn
                  (goto-char (point-min))
                  ;; Skip the prelude, if any.
                  (unless (outline-on-heading-p t) (outline-next-heading))
                  (point)))
           (end (progn
                  (goto-char (point-max))
                  ;; Keep empty last line, if available.
                  (if (bolp) (1- (point)) (point)))))
      (if (< end beg)
	  (setq beg (prog1 end (setq end beg))))
      ;; First hide everything.
      (outline-flag-region beg end t)
      ;; Then unhide the top level headers.
      (outline-map-region
       (lambda ()
	 (if (<= (funcall #'outline-level) levels)
	     (outline-show-heading)))
       beg end)
      ;; Finally unhide any trailing newline.
      (goto-char (point-max))
      (if (and (bolp) (not (bobp)) (outline-invisible-p (1- (point))))
          (outline-flag-region (1- (point)) (point) nil))))
  ;; (run-hooks 'outline-view-change-hook1)
  )

;;;###autoload
(defun outline-it-hide-other ()
  "Hide everything except current body and parent and top-level headings.
This also unhides the top heading-less body, if any.
`outline-hide-other' with one line changed."
  (interactive)
  (if (derived-mode-p 'org-mode) ;; changed: Fix folding other sublevels and text at upper header
      (save-excursion
        (org-overview)
        (org-reveal '(4))
        (org-fold-show-subtree))
    ;; else
    (outline-it-hide-sublevels (if (derived-mode-p 'org-mode)
                                   1
                                 ;; else
                                 9999)) ; changed
    ;; (let (outline-view-change-hook)
    (save-excursion
      (outline-back-to-heading t)
      (outline-show-entry)
      (while (condition-case nil (progn (outline-up-heading 1 t) (not (bobp)))
	       (error nil))
	(outline-flag-region (1- (point))
			     (save-excursion (forward-line 1) (point))
			     nil))))
  ;; (run-hooks 'outline-view-change-hook)
  )
;; (defun outline-it-hide-others ()
;;   "Hide other headers and don't hide headers and text in opened."
;;   (interactive)
;;   ;; (print "outline-it-hide-others")
;;   (save-excursion
;;     (outline-hide-sublevels 7) ;; hide all
;;     (outline-show-children) ;; show headers, not shure how and wehere,
;;     (outline-back-to-heading t) ;; to header in depths
;;     (outline-show-entry) ;; show local text
;;     ;; (print "outline-it-hide-others1")
;;     (condition-case nil
;;         (progn
;;           (outline-up-heading 1 t) ;; go upper - signal warning
;;           ;; (print "my/outline-hide-other2")
;;           ;; (outline-show-entry)
;;           (while (> (progn ;; (outline-back-to-heading t)
;;                       (funcall outline-level))
;;                     1) ;; while not at first header
;;             ;; (print (list "outline-it-hide-others3" (progn (outline-back-to-heading t)
;;             ;;                                               (funcall outline-level))
;;             ;;              (point)))
;;             (outline-show-entry)
;;             (outline-show-children) ;; show subheaders

;;             (condition-case nil
;;                 (outline-up-heading 1 t) ;; go upper  - signal warning
;;               (error nil))))
;;       (error nil))))


;; -= fix advice function


(defvar outline-it--additional-fix-to-auto-recenter t)

(defun outline-it--jumping-to-invisible-fix (&rest args)
  "Fix bug when we jump C-, to place hidden header.
Optional argument ARGS not used.
Cases:
1) `line-end-position' have invisible property in two cases:
- at header with hidden next line
- at hiddent line
2) At empty line before header never give invisible."
  (ignore args)
  (when (or
         (and (save-match-data
                   (string-match outline-regexp
                                 (buffer-substring (line-beginning-position)
                                                   (line-end-position))))
              (eq (get-char-property (line-beginning-position) 'invisible) 'outline))
         (and (not (save-match-data
                   (string-match outline-regexp
                                 (buffer-substring (line-beginning-position)
                                                   (line-end-position)))))
              (eq (get-char-property (line-end-position) 'invisible) 'outline))
         ;; at empty line before header, that never give invisible
         (and (string-empty-p (string-trim (buffer-substring-no-properties (line-beginning-position)
                                                                       (line-end-position))))
              (string-match outline-regexp
                                 (buffer-substring (line-beginning-position)
                                                   (line-end-position 2)))
              (save-excursion (forward-line -1)
                              (eq (get-char-property (point) 'invisible) 'outline))))
    (outline-show-entry)))
  ;; ;; additional fix to auto recenter
  ;; (when (and (pos-visible-in-window-p (save-excursion
  ;;                                       (forward-line 8)
  ;;                                       (point)))
  ;;            (eq (window-buffer) (current-buffer))) ; if showed
  ;;   (print "recenter")
  ;;   (recenter 2))
  ;; )
(defun outline-it--backtrace-jump-at-bottom-fix (&rest args)
  "Check if at least 8 lines visible after jumping, if not recenter.
ARG not used.
Optional argument ARGS not used."
  (ignore args)
  ;; (print (list "outline-it--backtrace-jump-at-bottom-fix" (point) (current-buffer)))
  (when (and (not (pos-visible-in-window-p (save-excursion
                                        (forward-line 8)
                                        (point))))
             (eq (window-buffer) (current-buffer))) ; if showed
    (print "recenter my/backtrace-jump-at-bottom-fix")
    (recenter)))

;; (add-hook 'xref-after-jump-hook #'my/fastfix)

;; -= -- advices activation

(defun outline-it--forward-sexp-fix (&rest args)
  "Open outline if we move by sexp or some function.
Optional argument ARGS we use to check that call was interactive,
because `forward-sexp' call itself several times recursively."
  (when (and (eq (length args) 2)  (cadr args))
    ;; (print (list "outline-it--forward-sexp-fix" args))
    (outline-it--jumping-to-invisible-fix)))

;;;###autoload
(defun outline-it-advices-activation ()
  "Dont depend on `outline-minor-mode'."
  (interactive)
  (advice-add 'xref-find-definitions :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'xref-go-back :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'xref-go-back :after #'outline-it--backtrace-jump-at-bottom-fix)
  ;; C-u C-SPC
  (advice-add 'pop-to-mark-command :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'goto-line :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'compile-goto-error :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'help-function-def--button-function :after #'outline-it--jumping-to-invisible-fix)
  (advice-add 'help-function-def--button-function :after #'outline-it--backtrace-jump-at-bottom-fix)
  ;; checkdoc
  ;; checkdoc-create-error
  (advice-add 'checkdoc-create-error :before #'outline-it--jumping-to-invisible-fix)
  (advice-add 'undo :after #'outline-it--jumping-to-invisible-fix)
  ;; dangerous
  (advice-add 'forward-sexp :after #'outline-it--forward-sexp-fix)
  (advice-add 'backward-sexp :after #'outline-it--forward-sexp-fix)

  ;; (advice-remove 'forward-sexp-default-function #'outline-it--jumping-to-invisible-fix-advanced)
  ;; (advice-remove 'backward-sexp #'outline-it--jumping-to-invisible-fix)

  ;; (advice-remove 'set-mark-command  #'outline-it--jumping-to-invisible-fix)
  ;; - for Backtrace buffer buttons.
  (add-hook 'find-function-after-hook #'outline-it--jumping-to-invisible-fix)
  ;; (advice-add 'set-mark-command :after #'outline-it--set-mark-command)
  )

(defun outline-it-advices-deactivation ()
  "Undo `outline-it-any-mode-hook-function' change also."
  (interactive)
  (advice-remove 'xref-find-definitions #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'xref-go-back #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'pop-to-mark-command #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'goto-line #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'compile-goto-error #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'help-function-def--button-function #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'checkdoc-create-error #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'undo #'outline-it--jumping-to-invisible-fix)
  (advice-remove 'forward-sexp #'outline-it--forward-sexp-fix)
  (advice-remove 'backward-sexp #'outline-it--forward-sexp-fix)
  (remove-hook 'find-function-after-hook #'outline-it--jumping-to-invisible-fix)
  ;; restore indent function and remove hooks
  (let ((outline-minor-mode nil)) (outline-it-outline-minor-mode-hook-function)))
;; -= unqoute
(defun outline-it--unquote-all (x)
  "Recursively remove any leading \='quote from a Lisp value.
Argument X some elisp value quoted or not."
  (while (and (listp x) (eq (car x) 'quote))
    (setq x (cadr x)))
  x)
;; -= Main
;;;###autoload
(defun outline-it (&optional outline-r outline-it-heading-alist force-fontify)
  "Activate outline-minor mode with custom regex for header.
Executed for current buffer.
Provide:
- fonts for headers
- wrap `indent-line-function' to call `outline-toggle-children' if
  cursor is at header

Uses two variables:
- OUTLINE-R - define one level, should be regex to match begining of
  heading.

- OUTLINE-IT-HEADING-ALIST (optional) - define levels by begining or
substring of header, should consist of quoted regex strings for usage
with `string-math' use `regexp-quote' to escape regex characters.  May
have ^ at the begining or not.
If FORCE-FONTIFY is non-nil - outline fontification for modes with own
font-lock overrided with outline mode fonts for `outline-regexp'."
  (interactive)
  (print (list "outline-it"  outline-r outline-it-heading-alist))
  (cond
   ;; trivial
   ((and outline-r
         outline-it-heading-alist))
   ;; else - Case 1) multilevel: outline-it-heading-alist (no outline-regexp)
   ((and outline-it-heading-alist (not outline-r))
    (setq outline-r (string-join (mapcar (lambda (el) (car el)) outline-heading-alist) "\\|"))
    ;; (setq-local outline-heading-alist outline-it-heading-alist)
    (print (list "case2" outline-heading-alist outline-r)))
   ;; Case 2) one level: outline-regexp  (no outline-it-heading-alist)
   ((and outline-r (not outline-it-heading-alist))
    (print "case2")
    ;; (setq-local outline-heading-alist nil)
    ;; (setq-local outline-regexp outline-r)
    (setq outline-it-heading-alist
                (list (cons outline-regexp 1))))

   ((and (buffer-file-name) (or (string-equal (file-name-nondirectory (buffer-file-name)) ".emacs")
                                (string-equal (file-name-nondirectory (buffer-file-name)) "init.el")))
    (print "case3")
    (setq outline-r "^;; -- ")
    (setq outline-it-heading-alist
                '((";; -- " . 1)
                  (";; -- -- " . 2)
                  (";; -- -- -- " . 3)
                  (";; -- -- -- -- " . 4)
                  (";; -- -- -- -- -- " . 5)
                  (";; -- -- -- -- -- -- " . 6))))

   ;; ((and outline-r outline-it-heading-alist)
   ;;  (print "case4")
   ;;  (setq-local outline-regexp outline-r)
   ;;  (setq-local outline-heading-alist outline-it-heading-alist))

   ((and (not outline-r)
         (not outline-it-heading-alist)
         (string-suffix-p ".el" (buffer-file-name))
         (not (file-remote-p (or (buffer-file-name)
                                 default-directory)))
         (not (dir-locals--all-files default-directory)))
    (print "case5")
    (setq outline-r "^;;; \\|\n+[^;][^;][^;]")
    (setq outline-it-heading-alist
          '((";;; " . 1)
            ("" . 2))))
   ;; configured from .dir-locals.el
   ((and (not outline-r)
         (not outline-it-heading-alist)
         (dir-locals--all-files default-directory)
         outline-heading-alist) ; was set in .dir-locals.el
    (setq outline-r outline-regexp)
    (setq outline-it-heading-alist outline-heading-alist))

   (t
    (user-error "Arguments for outline-it function should be provided")
    ;; (setq-local outline-heading-alist
    ;;             (list (cons outline-regexp 1))))
    ))
  ;; - Set main variables, deactivation outline for that
  (outline-minor-mode -1)
  (when outline-r
        (setq-local outline-regexp outline-r))
  (when outline-it-heading-alist
        (setq-local outline-heading-alist outline-it-heading-alist))
  ;; - fix if outline-heading-alist is quoted. for string-match in `outline-it--outline-level'
  (setq outline-heading-alist (outline-it--unquote-all outline-heading-alist))
  ;; - set outline variables
  ;; (cond

  ;;       ;; else - Case 1) multilevel: outline-it-heading-alist (no outline-regexp)
  ;;       ((and outline-it-heading-alist (not outline-r))
  ;;        ;; (setq-local outline-regexp "")
  ;;        (setq-local outline-regexp (string-join (mapcar (lambda (el) (car el)) outline-heading-alist) "\\|"))
  ;;        (setq-local outline-heading-alist outline-it-heading-alist)
  ;;        (print (list "case2" outline-heading-alist outline-r)))
  ;;       ;; Case 2) one level: outline-regexp  (no outline-it-heading-alist)
  ;;       ((and outline-r (not outline-it-heading-alist))
  ;;        (print "case2")
  ;;        ;; (setq-local outline-heading-alist nil)
  ;;        (setq-local outline-regexp outline-r)
  ;;        (setq-local outline-heading-alist
  ;;                    (list (cons outline-regexp 1))))

  ;;       ((and (buffer-file-name) (or (string-equal (file-name-nondirectory (buffer-file-name)) ".emacs")
  ;;                                    (string-equal (file-name-nondirectory (buffer-file-name)) "init.el")))
  ;;        (print "case3")
  ;;        (setq-local outline-regexp "^;; -- ")
  ;;        (setq-local outline-heading-alist
  ;;                    '((";; -- " . 1)
  ;;                      (";; -- -- " . 2)
  ;;                      (";; -- -- -- " . 3)
  ;;                      (";; -- -- -- -- " . 4)
  ;;                      (";; -- -- -- -- -- " . 5)
  ;;                      (";; -- -- -- -- -- -- " . 6))))

  ;;       ((and outline-r outline-it-heading-alist)
  ;;        (print "case4")
  ;;        (setq-local outline-regexp outline-r)
  ;;        (setq-local outline-heading-alist outline-it-heading-alist))

  ;;       ((and (buffer-file-name)
  ;;             (string-suffix-p ".el" (buffer-file-name))
  ;;             (not (file-remote-p (or (buffer-file-name)
  ;;                                       default-directory)))
  ;;             (not (dir-locals--all-files default-directory)))
  ;;        (print "case5")
  ;;        (setq-local outline-regexp "^;;; "))

  ;;       (t
  ;;        (user-error "Arguments for outline-it function should be provided")
  ;;          ;; (setq-local outline-heading-alist
  ;;          ;;             (list (cons outline-regexp 1))))
  ;;       ))
  (setq outline-default-state 'outline-show-only-headings)
  ;; - Keys
  (keymap-set outline-minor-mode-map "<backtab>" 'outline-cycle-buffer) ;; S-tab
  (keymap-set outline-minor-mode-map "C-c C-e" 'outline-it-hide-other) ;; hides `elisp-eval-region-or-buffer'
  ;; (keymap-local-set "C-c TAB" 'outline-hide-body)
  ;; (define-key outline-minor-mode-map [S-tab] 'outline-show-all)
  ;; (outline-hide-body)


  ;; - activate outline-heading-alistheader leavels
  ;; (setq outline-level #'outline-level)
  ;; - TAB key

  ;; (keymap-local-set "TAB" 'outline-it-toggle) ;; rooted - wrong
  ;;
  ;; - Add behavior of C-u C-w to copy only headers
  (setq-local filter-buffer-substring-function #'outline-it-copy-outline-headers)
  ;; fix match that search in outline-heading-alist by matching whole
  (setq-local outline-level #'outline-it--outline-level)

  ;; - activate outline

  ;; (setq-local outline-regexp outline-r)
  ;; (setq-local outline-it-heading-alist outline-r)

  ;; - font lock configuration - uses outline-it-heading-alist or outline-regexp.
  ;; (font-lock-refresh-defaults)
  ;; ;; test: (progn (outline-back-to-heading) (outline-font-lock-face) )
  ;; (setq-local outline-font-lock-faces (vconcat org-level-faces))
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
  (unless outline-it--indent-line-function-original ; if nil - first time
    (setq-local outline-it--indent-line-function-original indent-line-function) ; save
    (setq-local indent-line-function #'outline-it-toggle))
   ; used by indent-for-tab-step-5-indent-line called by TAB key indent-for-tab-command

  ;; (when (boundp (intern "indent-for-tab-steps"))
  ;;   (unless (memq (intern "indent-for-tab-steps")
  ;;   (append indent-for-tab-steps (outline-toggle-children)
  )


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
          ;; ;; >>> Set priority high so it overrides font-lock <<<
          ;; (overlay-put overlay 'priority 100)
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

;; -= implementations
;;;###autoload
(defun outline-it-python ()
  "Python."
  (interactive)
  (outline-it "^class\\|.* def "
              '(("^class" . 1) (".*def " . 2))))


;;;###autoload
(defun outline-it-githubactionlog ()
  "For Github Action Melpazoid log.
where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (lisp-mode)
  (outline-it "^# -- \\|.*##\\[group]\\|.*⸺ "
              '(("^# -- " . 1) ("##\\[group]" . 2) ("⸺ " . 3))
              t ; force-fintify
              ))

;;;###autoload
(defun outline-it-bash ()
  "For Github Action Melpazoid log.
where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (outline-it "^# -- "
              '(("^# -- " . 1))))


;; -= ? org bug ?
;; (advice-remove 'outline-back-to-heading 'fix-for-org-fold)

;; -= provide
(provide 'outline-it)

;;; outline-it.el ends here
