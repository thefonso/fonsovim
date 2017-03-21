" Customization
"
" This loads after the fonsovim plugins so that fonsovim-specific plugin mappings can
" be overwritten.

if filereadable(expand("~/.vimrc.after"))
  source ~/.vimrc.after
endif
