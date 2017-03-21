" Normal Mode: Bubble single lines
call fonsovim#add_mapping('unimpaired', 'nmap', '<C-Up>', '[e')
call fonsovim#add_mapping('unimpaired', 'nmap', '<C-Down>', ']e')

" Visual Mode: Bubble multiple lines
call fonsovim#add_mapping('unimpaired', 'vmap', '<C-Up>', '[egv')
call fonsovim#add_mapping('unimpaired', 'vmap', '<C-Down>', ']egv')
