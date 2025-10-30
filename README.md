![build](https://github.com/Anoncheg1/emacs-outline-it/workflows/melpazoid/badge.svg)

# emacs-outline-it

# Features
- fontification like in Org
- more simplier usage by specifying regex for headers
- fixed for Outline mode when jumping such as xref and goto (advices activates at loading

# Configuration

```lisp
(add-to-list 'load-path "/path/to/this/package/emacs-outline-it")
(require 'outline-it)
(add-hook 'outline-minor-mode-hook 'my/outline-minor-mode-hook) ; optional, for .emacs
```

# Usage - by function
To use, defune your outline-it-your function same way like ```outline-it-python``` and ```outline-it-githubactionlog``` at

Then use M-x outline-it-your

```lisp
;; from: [[file:outline-it.el::426::(defun outline-it-python ()]]
(defun outline-it-githubactionlog ()
  "For Github Action Melpazoid log of run.
Where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (setq-local outline-it-heading-alist '(("##\\[group]" . 1) ("⸺ " . 2)))
  (outline-it ".*##\\[group]\\|.*⸺ "))

```

# Usage - by ~/.dir-locals.el file
Create file in the same directory.

For Elisp files:
```lisp
((emacs-lisp-mode
  . (
     (outline-regexp . "^;;; ")
     (eval . (progn (keymap-local-set "C-c k" #'outline-previous-heading)
                    (keymap-local-set "C-c n" #'outline-next-heading)
                    (keymap-local-set "C-c C-e" #'my/outline-hide-others)
                    (keymap-local-set "<backtab>" #'outline-cycle-buffer)
                    (keymap-local-set "C-<tab>" #'outline-toggle-children)
                    (outline-hide-body)
                    )) ; noqa
     )))
```

For Bash files:
```lisp
((sh-mode
  . (
     (outline-regexp . "^# -- ")
     (eval . (progn (keymap-local-set "C-c k" #'outline-previous-heading)
                    (keymap-local-set "C-c n" #'outline-next-heading)
                    (keymap-local-set "C-c C-e" #'my/outline-hide-others)
                    (keymap-local-set "<backtab>" #'outline-cycle-buffer)
                    (keymap-local-set "C-<tab>" #'outline-toggle-children)
                    (outline-hide-body) ;; or (outline-cycle-buffer 5) ;; narrow by building levels by 5 first characters
                    ))
     )))
```

Activation of `outline-minor-mode` is not required for simple working.
# How

By calling `outline-it` we configure outline.el by setting its variables and bind keys.

To toggle header by TAB key we wrap `indent-line-function` function.

We replace `outline-level` function because it match outline-heading-alist incorrectly by full string match instead of searching substring.

For searching in headers we add hook to `isearch-mode-hook' that add template to `C-M-s` `isearch-forward-regexp` command by `outline-regexp' variable. We do this globally without calling `outline-it' function.

# Screen

![outline-it](https://raw.githubusercontent.com/Anoncheg1/public-share/main/outline-it.png)

# How Outline works
It uses two variables:
1) outline-regexp - to search for header
2) outline-heading-alist - is optional, to determinate level.

alist used in by `outline-level` function used by many others.

Function outline-back-to-heading -> outline-level ( used by outline-hide-sublevels and outline-hide-entry) uses functions:
- outline-back-to-heading use var outline-regexp
- outline-level uses var alist

# Other packages for same purpose from other authors:
- 2w https://github.com/jdtsmith/outli (font-lock)
- 7y https://github.com/tj64/outline-magic
- 3y https://github.com/alphapapa/outshine (font-lock)
- 4d https://github.com/jamescherti/outline-indent.el (font-lock)
