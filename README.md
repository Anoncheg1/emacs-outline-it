![build](https://github.com/Anoncheg1/emacs-outline-it/workflows/melpazoid/badge.svg)

# emacs-outline-it

# Features
- simple fontification
- customizable for any headers
- integration of outline with jumping such as xref and goto

# Configuration
To use, defune your outline-it-your function same way like ```outline-it-python``` and ```outline-it-githubactionlog``` defined.

Then use M-x outline-it-your

```lisp
(add-to-list 'load-path "/path/to/this/package/emacs-outline-it")
(require 'outline-it)

(defun outline-it-githubactionlog ()
  "For Github Action Melpazoid log of run.
where is goups with substring ##[group].
To check use: (search-forward-regexp (regexp-quote \"##[group]\"))"
  (interactive)
  (setq-local outline-it-heading-alist '(("##\\[group]" . 1) ("⸺ " . 2)))
  (outline-it ".*##\\[group]\\|.*⸺ "))

```


Recommend to bind ```(keymap-local-set "C-c C-e" #'my/outline-hide-others)```

# Other packages for same purpose from other authors:
- 2w https://github.com/jdtsmith/outli (font-lock)
- 7y https://github.com/tj64/outline-magic
- 3y https://github.com/alphapapa/outshine (font-lock)
- 4d https://github.com/jamescherti/outline-indent.el (font-lock)
