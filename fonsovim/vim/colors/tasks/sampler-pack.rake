postinstall_vim_plugin 'colors', 'sampler-pack' do |module_loaded|
  if module_loaded
    FileUtils.rm_rf 'fonsovim/vim/colors/sampler-pack/colors/solarized.vim'
  end
end
