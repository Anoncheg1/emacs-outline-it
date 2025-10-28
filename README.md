![build](https://github.com/Anoncheg1/emacs-outline-it/workflows/melpazoid/badge.svg)

# emacs-outline-it

# Features
- simple fontification
- customizable for any headers
- integration of outline with jumping such as xref and goto

# Configuration

```lisp
(add-to-list 'load-path "/path/to/this/package/emacs-outline-it")
(require 'outline-it)
```

# Usage - by function
To use, defune your outline-it-your function same way like ```outline-it-python``` and ```outline-it-githubactionlog``` at

Then use M-x outline-it-your

```lisp
;; from: [[file:outline-it.el::426::(defun outline-it-python ()]]
(defun outline-it-githubactionlog ()
  "For Github Action Melpazoid log of run.
where is goups with substring ##[group].
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
                    (outline-cycle-buffer 1)
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
                    (outline-cycle-buffer 5) ;; narrow by building levels by 5 first characters
                    ))
     )))
```

Activation of `outline-minor-mode` is not required for simple working.

# Screen

![outline-it](https://raw.githubusercontent.com/Anoncheg1/public-share/main/outline-it.png)

# Other packages for same purpose from other authors:
- 2w https://github.com/jdtsmith/outli (font-lock)
- 7y https://github.com/tj64/outline-magic
- 3y https://github.com/alphapapa/outshine (font-lock)
- 4d https://github.com/jamescherti/outline-indent.el (font-lock)
