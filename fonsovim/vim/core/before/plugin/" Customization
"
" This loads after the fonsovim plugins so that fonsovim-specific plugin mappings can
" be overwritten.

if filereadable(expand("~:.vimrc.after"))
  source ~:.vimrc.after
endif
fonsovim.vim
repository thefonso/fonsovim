""
"" Fonsovim main functions
""

" Return a path separator on the current OS
" Taken from pathogen
"
" @return [String] The separator / or \
function! fonsovim#separator()
  return !exists("+shellslash") || &shellslash ? '/' : '\'
endfunction

" Return the expanded path
"
" @param [String] path
" @return [String] Absolute path
function! fonsovim#expand_path(path)
  return expand(a:path)
endfunction

" Return a resolved path
"
" @param [String] path
" @return resolved path
function! fonsovim#resolve_path(path)
  return resolve(fonsovim#expand_path(a:path))
endfunction

" Return the dirname of a path
"
" @param [String] path
" @return [String] The dirname of the path given in the param
function! fonsovim#dirname(path)
  return fnamemodify(fonsovim#resolve_path(a:path), ":h")
endfunction

" Return the basename of a path
"
" @param [String] path
" @return [String] The basename of the path given in the param
function! fonsovim#basename(path)
  return fnamemodify(fonsovim#resolve_path(a:path), ":t")
endfunction

" Return the group name
"
" @param [String] The group path
" @return [String] The group name
function! fonsovim#group_name(path)
  return fonsovim#basename(a:path)
endfunction

" Return the group path
"
" @param [String] The group name
" @return [String] The group path
function! fonsovim#group_path(name)
  for group in g:fonsovim_loaded_groups
    if fonsovim#group_name(group) == a:name
      return group
    endif
  endfor
endfunction

" Find vim files inside a folder
"
" @param [String] The path to a folder
" @return [List] List of files.
function! fonsovim#vim_files(folder)
  let files = []
  let pattern = fonsovim#resolve_path(a:folder) . fonsovim#separator() . "*"
  " Add all found vim files
  for file in split(glob(pattern), "\n")
    if isdirectory(file)
      call extend(files, fonsovim#vim_files(file))
    elseif (file =~ "\.vim$")
      call add(files, file)
    endif
  endfor

  return files
endfunction

" Add a group of plug-ins to Pathogen
"
" @param [String] The plugin name
" @param [String] (Optional) the base path of the group
function! fonsovim#add_group(name, ...)
  if !exists("g:fonsovim_loaded_groups")
    let g:fonsovim_loaded_groups = []
  endif

  " Loaded group array will contain full path to group
  let base_path = exists("a:1") ? a:1 : g:fonsovim_vim_path
  call add(g:fonsovim_loaded_groups, base_path . fonsovim#separator() . a:name)
endfunction

" Prepends custom plugins first so they will end up last after pathogen loads
" other fonsovim groups
function! fonsovim#load_custom_before(path)
  if isdirectory(g:fonsovim_custom_path)
    let rtp = pathogen#split(&rtp)
    let custom = filter(pathogen#glob_directories(a:path), '!pathogen#is_disabled(v:val)')
    let &rtp = pathogen#join(pathogen#uniq(custom + rtp))
  endif
endfunction

" Append custom plugins 'after' directories to rtp
function! fonsovim#load_custom_after()
  if isdirectory(g:fonsovim_custom_path)
    let rtp = pathogen#split(&rtp)
    let custom_path = g:fonsovim_custom_path . fonsovim#separator() . "*" . fonsovim#separator() . "after"
    let custom_after  = filter(pathogen#glob_directories(custom_path), '!pathogen#is_disabled(v:val[0:-7])')
    let &rtp = pathogen#join(pathogen#uniq(rtp + custom_after))

    " Add the custom group to the list of loaded groups
    call fonsovim#add_group(".fonsovim", expand("~"))
  endif
endfunction

" Load/wrap core around the rtp
function! fonsovim#load_core()
  " pathogen#infect will prepend core's 'before' and append 'fonsovim/after' to
  " the rtp
  call fonsovim#add_group("core")
  let core = g:fonsovim_vim_path . fonsovim#separator() . "core"
  call pathogen#infect(core . fonsovim#separator() . '{}')
endfunction

" Load pathogen groups
function! fonsovim#load_pathogen()
  if !exists("g:loaded_pathogen")
    " Source Pathogen
    exe 'source ' . g:fonsovim_vim_path . '/core/pathogen/autoload/pathogen.vim'
  endif

  " Add custom plugins before bundled groups
  call fonsovim#load_custom_before(g:fonsovim_custom_path . fonsovim#separator() . "*")

  for group in g:fonsovim_loaded_groups
    call pathogen#infect(group . fonsovim#separator() . '{}')
  endfor

  " Add custom plugins to override bundled groups
  call fonsovim#load_custom_before(g:fonsovim_custom_path . ".before" . fonsovim#separator() . "*")

  " Add custom 'after' directories to rtp and then load the core
  call fonsovim#load_custom_after()
  call fonsovim#load_core()
  call pathogen#helptags()
endfunction

" Which group contains a plugin ?
"
" @param [String] The plugin name
" @return [String] The group name (not an absolute path)
function! fonsovim#which_group(name)
  if !exists("g:fonsovim_loaded_groups")
    return ""
  endif

  for group in g:fonsovim_loaded_groups
    if isdirectory(fonsovim#plugin_path(group, a:name))
      return fonsovim#group_name(group)
    endif
  endfor
endfunction

" Disable a plugin
"
" @param [String] The group the plugin belongs to, will be determined if
"                 no group were given.
" @param [String] The plugin name
" @param [String] The reason why it is disabled
" @return [Bool]
function! fonsovim#disable_plugin(...)
  if a:0 < 1 || a:0 > 3
    throw "The arguments to fonsovim#disable_plugin() should be [group], <name>, [reason]"
  elseif a:0 == 1
    let group = -1
    let name = a:1
    let reason = -1
  elseif a:0 == 2
    let group = -1
    let name = a:1
    let reason = a:2
  elseif a:0 == 3
    let group = a:1
    let name = a:2
    let reason = a:3
  endif

  " Verify the existance of the global variables
  if !exists("g:pathogen_disabled")
    let g:pathogen_disabled = []
  endif
  if !exists("g:fonsovim_disabled_plugins")
    let g:fonsovim_disabled_plugins = {}
  endif

  " Fetch the group if necessary
  if group == -1
    let group = fonsovim#which_group(name)
  endif

  " Check if we need to add it
  if has_key(g:fonsovim_disabled_plugins, name) && g:fonsovim_disabled_plugins[name]['group'] == group
    " Just update the reason if necessary.
    if reason != "No reason given." && g:fonsovim_disabled_plugins[name]['reason'] == -1
      let g:fonsovim_disabled_plugins[name]['reason'] = reason
    endif

    return 0
  endif

  " Find the plugin path
  let plugin_path = fonsovim#plugin_path(group, name)

  " Add it to fonsovim_disabled_plugins
  let g:fonsovim_disabled_plugins[name] = {'group': group, 'path': plugin_path, 'reason': reason}

  " Add it to pathogen_disabled
  call add(g:pathogen_disabled, name)
endfunction

" Return the plugin path
"
" @param [String] The group the plugin belongs to, will be determined if
"                 no group were given.
" @param [String] The plugin name
" @return [String] The plugin path relative to g:fonsovim_vim_path
function! fonsovim#plugin_path(...)
  if a:0 < 1 || a:0 > 2
    throw "The arguments to fonsovim#plugin_path() should be [group], <name>"
  elseif a:0 == 1
    let name  = a:1
    let group = fonsovim#which_group(name)
  else
    let group = a:1
    let name  = a:2
  endif

  return fonsovim#group_path(group) . fonsovim#separator() . name
endfunction

" Is modules loaded?
"
" @param [String] The plugin name
" @return [Boolean]
function! fonsovim#is_module_loaded(name)
  return len(fonsovim#vim_files(fonsovim#plugin_path(a:name))) > 0
endfunction

" Is plugin disabled?
"
" @param [String] The plugin name
function! fonsovim#is_plugin_disabled(name)
  if !exists("g:fonsovim_disabled_plugins")
    return 0
  endif

  return has_key(g:fonsovim_disabled_plugins, a:name)
endfunction

" Is plugin enabled?
"
" @param [String] The plugin name
" @return [Boolean]
function! fonsovim#is_plugin_enabled(name)
  return fonsovim#is_module_loaded(a:name) && !fonsovim#is_plugin_disabled(a:name)
endfunction

" Mapping function
"
" @param [String] The plugin name
" @param [String] The mapping command (map, vmap, nmap or imap)
" @param [String] The mapping keys
" @param [String]* The mapping action
function! fonsovim#add_mapping(name, mapping_command, mapping_keys, ...)
  if len(a:000) < 1
    throw "The arguments to fonsovim#add_mapping() should be <name> <mapping_command> <mapping_keys> <mapping_action> [mapping_action]*"
  endif

  if fonsovim#is_plugin_enabled(a:name)
    let mapping_command = join(a:000)
  else
    if !fonsovim#is_module_loaded(a:name)
      let reason = "Module is not loaded"
    elseif g:fonsovim_disabled_plugins[a:name]['reason'] == -1
      return 0
    else
      let reason = g:fonsovim_disabled_plugins[a:name]['reason']
    endif

    let mapping_command = "<ESC>:echo 'The plugin " . a:name . " is disabled for the following reason: " . reason . ".'<CR>"
  endif

  let mapping_list = [a:mapping_command, a:mapping_keys, mapping_command]
  exe join(mapping_list)
endfunction
