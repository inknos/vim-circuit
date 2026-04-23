" vim-claudeterm: commands, keymaps, and configuration
" Maintainer: inknos
" License: MIT

if exists('g:loaded_claudeterm')
  finish
endif
let g:loaded_claudeterm = 1

if !has('terminal')
  echoerr 'vim-claudeterm requires Vim compiled with +terminal'
  finish
endif

" ---------------------------------------------------------------------------
" Configuration defaults
" ---------------------------------------------------------------------------

let g:claudeterm_command          = get(g:, 'claudeterm_command', 'claude')
let g:claudeterm_position         = get(g:, 'claudeterm_position', 'right')
let g:claudeterm_split_ratio      = get(g:, 'claudeterm_split_ratio', 0.4)
let g:claudeterm_enter_insert     = get(g:, 'claudeterm_enter_insert', 1)
let g:claudeterm_use_git_root     = get(g:, 'claudeterm_use_git_root', 1)
let g:claudeterm_permission_mode  = get(g:, 'claudeterm_permission_mode', '')
let g:claudeterm_model            = get(g:, 'claudeterm_model', '')
let g:claudeterm_extra_args       = get(g:, 'claudeterm_extra_args', '')
let g:claudeterm_session_strategy = get(g:, 'claudeterm_session_strategy', 'branch')
let g:claudeterm_open_strategy    = get(g:, 'claudeterm_open_strategy', 'resume')

let g:claudeterm_auto_reload      = get(g:, 'claudeterm_auto_reload', 1)
let g:claudeterm_reload_interval  = get(g:, 'claudeterm_reload_interval', 1000)
let g:claudeterm_notify_reload    = get(g:, 'claudeterm_notify_reload', 1)

let g:claudeterm_hide_numbers     = get(g:, 'claudeterm_hide_numbers', 1)
let g:claudeterm_hide_signcolumn  = get(g:, 'claudeterm_hide_signcolumn', 1)

let g:claudeterm_map_keys         = get(g:, 'claudeterm_map_keys', 1)

" Keymap variables (all overridable)
let g:claudeterm_map_toggle       = get(g:, 'claudeterm_map_toggle', '<leader>c')
let g:claudeterm_map_resume       = get(g:, 'claudeterm_map_resume', '<leader>cr')
let g:claudeterm_map_continue     = get(g:, 'claudeterm_map_continue', '<leader>cc')
let g:claudeterm_map_new          = get(g:, 'claudeterm_map_new', '<leader>cn')
let g:claudeterm_map_kill         = get(g:, 'claudeterm_map_kill', '<leader>ck')
let g:claudeterm_map_pr           = get(g:, 'claudeterm_map_pr', '<leader>cp')
let g:claudeterm_map_zoom         = get(g:, 'claudeterm_map_zoom', '<leader>cz')
let g:claudeterm_map_zoom_term    = get(g:, 'claudeterm_map_zoom_term', '<C-w>z')
let g:claudeterm_map_send         = get(g:, 'claudeterm_map_send', '<leader>cs')
let g:claudeterm_map_chat         = get(g:, 'claudeterm_map_chat', '<leader>ch')
let g:claudeterm_map_verbose      = get(g:, 'claudeterm_map_verbose', '<leader>cv')
let g:claudeterm_map_mode_plan    = get(g:, 'claudeterm_map_mode_plan', '<leader>cmp')
let g:claudeterm_map_mode_fast    = get(g:, 'claudeterm_map_mode_fast', '<leader>cmf')
let g:claudeterm_map_model_sonnet = get(g:, 'claudeterm_map_model_sonnet', '<leader>cms')
let g:claudeterm_map_model_opus   = get(g:, 'claudeterm_map_model_opus', '<leader>cmo')
let g:claudeterm_map_model_haiku  = get(g:, 'claudeterm_map_model_haiku', '<leader>cmh')

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------

" Main dispatcher
command! -nargs=* -complete=customlist,claudeterm#complete CTerm call s:dispatch(<f-args>)

" Short aliases
command! -nargs=0 CT         call claudeterm#toggle()
command! -nargs=0 CTresume   call claudeterm#resume()
command! -nargs=0 CTcontinue call claudeterm#continue()
command! -nargs=0 CTnew      call claudeterm#new()
command! -nargs=0 CTkill     call claudeterm#kill()
command! -nargs=0 CTpr       call claudeterm#from_pr()
command! -nargs=0 CTzoom     call claudeterm#zoom()
command! -nargs=0 CTplan     call claudeterm#set_mode('plan')
command! -nargs=0 CTfast     call claudeterm#set_mode('fast')
command! -nargs=0 CTnormal   call claudeterm#set_mode('plan')
command! -nargs=1 CTmodel    call claudeterm#set_model(<f-args>)
command! -nargs=0 CTverbose  call claudeterm#toggle_verbose()
command! -nargs=0 CTdoctor   call claudeterm#doctor()
command! -nargs=0 CTversion  call claudeterm#version()
command! -nargs=0 CTsend     call claudeterm#send_selection()
command! -nargs=0 CTchat     call claudeterm#chat()

function! s:dispatch(...) abort
  if a:0 == 0
    call claudeterm#toggle()
    return
  endif

  let l:cmd = a:1

  if l:cmd ==# 'resume'
    call claudeterm#resume()
  elseif l:cmd ==# 'continue'
    call claudeterm#continue()
  elseif l:cmd ==# 'new'
    call claudeterm#new()
  elseif l:cmd ==# 'kill'
    call claudeterm#kill()
  elseif l:cmd ==# 'pr'
    call claudeterm#from_pr()
  elseif l:cmd ==# 'zoom'
    call claudeterm#zoom()
  elseif l:cmd ==# 'send'
    call claudeterm#send_selection()
  elseif l:cmd ==# 'chat'
    call claudeterm#chat()
  elseif l:cmd ==# 'verbose'
    call claudeterm#toggle_verbose()
  elseif l:cmd ==# 'doctor'
    call claudeterm#doctor()
  elseif l:cmd ==# 'version'
    call claudeterm#version()
  elseif l:cmd ==# 'plan'
    call claudeterm#set_mode('plan')
  elseif l:cmd ==# 'fast'
    call claudeterm#set_mode('fast')
  elseif l:cmd ==# 'mode'
    if a:0 >= 2
      call claudeterm#set_mode(a:2)
    else
      echoerr 'claudeterm: mode requires an argument (plan/fast/normal)'
    endif
  elseif l:cmd ==# 'model'
    if a:0 >= 2
      call claudeterm#set_model(a:2)
    else
      echoerr 'claudeterm: model requires an argument (sonnet/opus/haiku or full model name)'
    endif
  elseif l:cmd ==# 'position'
    if a:0 >= 2
      call claudeterm#set_position(a:2)
    else
      echoerr 'claudeterm: position requires an argument (right/left/top/bottom)'
    endif
  else
    echoerr 'claudeterm: unknown subcommand "' . l:cmd . '"'
  endif
endfunction

" ---------------------------------------------------------------------------
" Keymaps
" ---------------------------------------------------------------------------

if g:claudeterm_map_keys
  " Session management
  execute 'nnoremap <silent> ' . g:claudeterm_map_toggle   . ' :call claudeterm#toggle()<CR>'
  execute 'nnoremap <silent> ' . g:claudeterm_map_resume   . ' :call claudeterm#resume()<CR>'
  execute 'nnoremap <silent> ' . g:claudeterm_map_continue . ' :call claudeterm#continue()<CR>'
  execute 'nnoremap <silent> ' . g:claudeterm_map_new      . ' :call claudeterm#new()<CR>'
  execute 'nnoremap <silent> ' . g:claudeterm_map_kill     . ' :call claudeterm#kill()<CR>'
  execute 'nnoremap <silent> ' . g:claudeterm_map_pr       . ' :call claudeterm#from_pr()<CR>'

  " Window
  execute 'nnoremap <silent> ' . g:claudeterm_map_zoom     . ' :call claudeterm#zoom()<CR>'
  execute 'tnoremap <silent> ' . g:claudeterm_map_zoom_term . ' <C-\><C-n>:call claudeterm#zoom()<CR>'

  " Code context
  execute 'vnoremap <silent> ' . g:claudeterm_map_send     . " :<C-u>call claudeterm#send_selection()<CR>"
  execute 'nnoremap <silent> ' . g:claudeterm_map_chat     . ' :call claudeterm#chat()<CR>'

  " Verbose
  execute 'nnoremap <silent> ' . g:claudeterm_map_verbose  . ' :call claudeterm#toggle_verbose()<CR>'

  " Mode control (sends /plan or /fast slash commands to the session)
  execute 'nnoremap <silent> ' . g:claudeterm_map_mode_plan . " :call claudeterm#set_mode('plan')<CR>"
  execute 'nnoremap <silent> ' . g:claudeterm_map_mode_fast . " :call claudeterm#set_mode('fast')<CR>"

  " Model switching
  execute 'nnoremap <silent> ' . g:claudeterm_map_model_sonnet . " :call claudeterm#set_model('sonnet')<CR>"
  execute 'nnoremap <silent> ' . g:claudeterm_map_model_opus   . " :call claudeterm#set_model('opus')<CR>"
  execute 'nnoremap <silent> ' . g:claudeterm_map_model_haiku  . " :call claudeterm#set_model('haiku')<CR>"

  " Terminal-mode window navigation
  tnoremap <silent> <C-h> <C-\><C-n><C-w>h
  tnoremap <silent> <C-j> <C-\><C-n><C-w>j
  tnoremap <silent> <C-k> <C-\><C-n><C-w>k
  tnoremap <silent> <C-l> <C-\><C-n><C-w>l
  tnoremap <silent> <C-v> <C-\><C-n>"+pi
endif

" ---------------------------------------------------------------------------
" Autocommands
" ---------------------------------------------------------------------------

augroup claudeterm_autoread
  autocmd!
  autocmd FocusGained,BufEnter * if get(g:, 'claudeterm_auto_reload', 1) | checktime | endif
augroup END
