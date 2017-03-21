if fonsovim#is_plugin_enabled("ctrlp")
  let g:ctrlp_map = ''
  let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn)$|bower_components|node_modules',
    \ 'file': '\.pyc$\|\.pyo$\|\.rbc$|\.rbo$\|\.class$\|\.o$\|\~$\',
    \ }
endif

if has("gui_macvim") && has("gui_running")
  call fonsovim#add_mapping('ctrlp', 'map', '<D-t>', ':CtrlP<CR>')
  call fonsovim#add_mapping('ctrlp', 'imap', '<D-t>', '<ESC>:CtrlP<CR>')
endif
