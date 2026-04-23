" vim-claudeterm: core functions
" Maintainer: inknos
" License: MIT

" ---------------------------------------------------------------------------
" Internal state
" ---------------------------------------------------------------------------
let s:term_bufnr = -1
let s:term_winid = -1
let s:is_zoomed = 0
let s:pre_zoom_winrestcmd = ''
let s:reload_timer = -1
let s:current_mode = ''
let s:current_model = ''
let s:verbose = 0

" ---------------------------------------------------------------------------
" Helpers
" ---------------------------------------------------------------------------

function! s:get(name, default) abort
  let l:bvar = 'b:claudeterm_' . a:name
  let l:gvar = 'g:claudeterm_' . a:name
  if exists(l:bvar)
    return eval(l:bvar)
  endif
  if exists(l:gvar)
    return eval(l:gvar)
  endif
  return a:default
endfunction

function! s:git_root() abort
  let l:root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if v:shell_error || empty(l:root)
    return getcwd()
  endif
  return l:root
endfunction

function! s:build_cmd(...) abort
  let l:cmd = s:get('command', 'claude')
  let l:extra = s:get('extra_args', '')

  let l:mode = s:current_mode
  if empty(l:mode)
    let l:mode = s:get('permission_mode', '')
  endif
  if !empty(l:mode)
    let l:cmd .= ' --permission-mode ' . l:mode
  endif

  let l:model = s:current_model
  if empty(l:model)
    let l:model = s:get('model', '')
  endif
  if !empty(l:model)
    let l:cmd .= ' --model ' . l:model
  endif

  if s:verbose
    let l:cmd .= ' --verbose'
  endif

  if !empty(l:extra)
    let l:cmd .= ' ' . l:extra
  endif

  if a:0 > 0 && !empty(a:1)
    let l:cmd .= ' ' . a:1
  endif

  return l:cmd
endfunction

function! s:open_split() abort
  let l:pos = s:get('position', 'right')
  let l:ratio = s:get('split_ratio', 0.4)

  if l:pos ==# 'right'
    let l:size = float2nr(&columns * l:ratio)
    execute 'vertical botright ' . l:size . 'new'
  elseif l:pos ==# 'left'
    let l:size = float2nr(&columns * l:ratio)
    execute 'vertical topleft ' . l:size . 'new'
  elseif l:pos ==# 'bottom'
    let l:size = float2nr(&lines * l:ratio)
    execute 'botright ' . l:size . 'new'
  elseif l:pos ==# 'top'
    let l:size = float2nr(&lines * l:ratio)
    execute 'topleft ' . l:size . 'new'
  else
    let l:size = float2nr(&columns * l:ratio)
    execute 'vertical botright ' . l:size . 'new'
  endif
endfunction

function! s:configure_term_window() abort
  if s:get('hide_numbers', 1)
    setlocal nonumber norelativenumber
  endif
  if s:get('hide_signcolumn', 1)
    setlocal signcolumn=no
  endif
  setlocal nobuflisted
endfunction

function! s:focus_term() abort
  if s:get('enter_insert', 1)
    if mode() !=# 't'
      normal! i
    endif
  endif
endfunction

function! s:term_alive() abort
  return s:term_bufnr != -1 && bufexists(s:term_bufnr)
        \ && getbufvar(s:term_bufnr, '&buftype') ==# 'terminal'
        \ && term_getstatus(s:term_bufnr) =~# 'running'
endfunction

" ---------------------------------------------------------------------------
" Toggle
" ---------------------------------------------------------------------------

function! claudeterm#toggle() abort
  if s:term_alive()
    let l:winid = bufwinid(s:term_bufnr)
    if l:winid != -1
      call s:hide()
    else
      call s:show()
    endif
  else
    let l:cmd = s:build_cmd('--continue')
    call s:open_with_cmd(l:cmd)
  endif
endfunction

function! s:show() abort
  call s:open_split()
  execute 'buffer ' . s:term_bufnr
  let s:term_winid = win_getid()

  call s:configure_term_window()
  call claudeterm#hooks#fire('ToggleShow')
  call s:focus_term()
endfunction

function! s:hide() abort
  let l:winid = bufwinid(s:term_bufnr)
  if l:winid != -1
    let l:winnr = win_id2win(l:winid)
    execute l:winnr . 'wincmd w'
    hide
  endif
  call claudeterm#hooks#fire('ToggleHide')
endfunction

" ---------------------------------------------------------------------------
" Session management
" ---------------------------------------------------------------------------

function! claudeterm#resume() abort
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('--resume')
  call s:open_with_cmd(l:cmd)
  call claudeterm#hooks#fire('SessionChange')
endfunction

function! claudeterm#continue() abort
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('--continue')
  call s:open_with_cmd(l:cmd)
  call claudeterm#hooks#fire('SessionChange')
endfunction

function! claudeterm#new() abort
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('')
  call s:open_with_cmd(l:cmd)
  call claudeterm#hooks#fire('SessionChange')
endfunction

function! claudeterm#from_pr() abort
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('--from-pr')
  call s:open_with_cmd(l:cmd)
  call claudeterm#hooks#fire('SessionChange')
endfunction

function! claudeterm#kill() abort
  call s:kill_term_if_alive()
  call claudeterm#hooks#fire('Kill')
endfunction

function! s:kill_term_if_alive() abort
  call s:stop_reload_timer()
  if s:term_alive()
    let l:winid = bufwinid(s:term_bufnr)
    if l:winid != -1
      let l:winnr = win_id2win(l:winid)
      execute l:winnr . 'wincmd w'
      quit!
    endif
    if bufexists(s:term_bufnr)
      execute 'bwipeout! ' . s:term_bufnr
    endif
  endif
  let s:term_bufnr = -1
  let s:term_winid = -1
  let s:is_zoomed = 0
endfunction

function! s:open_with_cmd(cmd) abort
  let l:cwd = s:get('use_git_root', 1) ? s:git_root() : getcwd()

  let l:saved_dir = getcwd()
  execute 'lcd ' . fnameescape(l:cwd)
  call s:open_split()
  execute 'terminal ++curwin ++close ' . a:cmd
  execute 'lcd ' . fnameescape(l:saved_dir)
  let s:term_bufnr = bufnr('%')
  let s:term_winid = win_getid()

  call s:configure_term_window()
  call s:start_reload_timer()
  call claudeterm#hooks#fire('Open')
  call s:focus_term()
endfunction

" ---------------------------------------------------------------------------
" Mode control (sends slash commands to the running session)
" ---------------------------------------------------------------------------

function! claudeterm#set_mode(mode) abort
  if !s:term_alive()
    call claudeterm#toggle()
  else
    let l:winid = bufwinid(s:term_bufnr)
    if l:winid == -1
      call s:show()
    endif
  endif

  call term_sendkeys(s:term_bufnr, '/' . a:mode . "\n")
  let s:current_mode = a:mode
  call claudeterm#hooks#fire('ModeChange')
endfunction

" ---------------------------------------------------------------------------
" Model switching
" ---------------------------------------------------------------------------

function! claudeterm#set_model(model) abort
  let s:current_model = a:model
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('--continue')
  call s:open_with_cmd(l:cmd)
endfunction

" ---------------------------------------------------------------------------
" Worktree
" ---------------------------------------------------------------------------

function! claudeterm#worktree(name, bang) abort
  call s:kill_term_if_alive()

  let l:cmd = s:get('command', 'claude') . ' --worktree'
  if !empty(a:name)
    let l:cmd .= ' ' . a:name
  endif
  let l:use_tmux = a:bang || s:get('worktree_tmux', 0)
  if l:use_tmux
    let l:cmd .= ' --tmux'
  endif

  let l:cwd = s:get('use_git_root', 1) ? s:git_root() : getcwd()
  let l:saved_dir = getcwd()
  execute 'lcd ' . fnameescape(l:cwd)
  call s:open_split()
  execute 'terminal ++curwin ++close ' . l:cmd
  execute 'lcd ' . fnameescape(l:saved_dir)

  let s:term_bufnr = bufnr('%')
  let s:term_winid = win_getid()

  call s:configure_term_window()
  call s:start_reload_timer()
  call claudeterm#hooks#fire('Worktree')
  call s:focus_term()
endfunction

" ---------------------------------------------------------------------------
" Verbose toggle
" ---------------------------------------------------------------------------

function! claudeterm#toggle_verbose() abort
  let s:verbose = !s:verbose
  call s:kill_term_if_alive()
  let l:cmd = s:build_cmd('--continue')
  call s:open_with_cmd(l:cmd)
  echo 'claudeterm: verbose ' . (s:verbose ? 'ON' : 'OFF')
endfunction

" ---------------------------------------------------------------------------
" Zoom
" ---------------------------------------------------------------------------

function! claudeterm#zoom() abort
  if !s:term_alive()
    echo 'claudeterm: no active terminal'
    return
  endif

  let l:winid = bufwinid(s:term_bufnr)
  if l:winid == -1
    call s:show()
    return
  endif

  if s:is_zoomed
    let s:is_zoomed = 0
    execute s:pre_zoom_winrestcmd
    call claudeterm#hooks#fire('ZoomOut')
  else
    let s:pre_zoom_winrestcmd = winrestcmd()
    let l:winnr = win_id2win(l:winid)
    execute l:winnr . 'wincmd w'
    wincmd |
    wincmd _
    let s:is_zoomed = 1
    call claudeterm#hooks#fire('ZoomIn')
  endif
endfunction

" ---------------------------------------------------------------------------
" Send selection
" ---------------------------------------------------------------------------

function! claudeterm#send_selection() abort
  if !s:term_alive()
    echo 'claudeterm: no active terminal'
    return
  endif

  let l:lines = getline("'<", "'>")
  if empty(l:lines)
    return
  endif

  let l:fname = expand('%:t')
  let l:header = '# From ' . l:fname
  let l:text = l:header . "\n" . join(l:lines, "\n") . "\n"

  call term_sendkeys(s:term_bufnr, l:text)
endfunction

" ---------------------------------------------------------------------------
" Chat (free-form prompt)
" ---------------------------------------------------------------------------

function! claudeterm#chat() abort
  let l:msg = input('claudeterm> ')
  if empty(l:msg)
    return
  endif

  if !s:term_alive()
    call claudeterm#toggle()
  else
    let l:winid = bufwinid(s:term_bufnr)
    if l:winid == -1
      call s:show()
    endif
  endif

  let l:fname = expand('#:t')
  let l:context = ''
  if !empty(l:fname)
    let l:context = '(context: ' . l:fname . ') '
  endif

  call term_sendkeys(s:term_bufnr, l:context . l:msg . "\n")
endfunction

" ---------------------------------------------------------------------------
" Position change
" ---------------------------------------------------------------------------

function! claudeterm#set_position(pos) abort
  if index(['right', 'left', 'top', 'bottom'], a:pos) == -1
    echoerr 'claudeterm: invalid position "' . a:pos . '". Use right/left/top/bottom.'
    return
  endif
  let g:claudeterm_position = a:pos
  if s:term_alive() && bufwinid(s:term_bufnr) != -1
    call s:hide()
    call s:show()
  endif
endfunction

" ---------------------------------------------------------------------------
" Doctor / Version
" ---------------------------------------------------------------------------

function! claudeterm#doctor() abort
  let l:cmd = s:get('command', 'claude')
  echo trim(system(l:cmd . ' doctor 2>&1'))
endfunction

function! claudeterm#version() abort
  let l:cmd = s:get('command', 'claude')
  let l:cli_ver = trim(system(l:cmd . ' --version 2>&1'))
  echo 'vim-claudeterm: 0.1.0'
  echo 'claude cli:     ' . l:cli_ver
  echo 'vim:            ' . v:version
  echo 'terminal:       ' . (has('terminal') ? '+terminal' : '-terminal')
endfunction

" ---------------------------------------------------------------------------
" Auto-reload
" ---------------------------------------------------------------------------

function! s:start_reload_timer() abort
  if !s:get('auto_reload', 1)
    return
  endif
  call s:stop_reload_timer()
  let l:interval = s:get('reload_interval', 1000)
  let s:reload_timer = timer_start(l:interval, function('s:reload_check'), {'repeat': -1})
endfunction

function! s:stop_reload_timer() abort
  if s:reload_timer != -1
    call timer_stop(s:reload_timer)
    let s:reload_timer = -1
  endif
endfunction

function! s:reload_check(timer_id) abort
  if !s:term_alive()
    call s:stop_reload_timer()
    return
  endif
  let l:reloaded = 0
  for l:bufnr in range(1, bufnr('$'))
    if buflisted(l:bufnr) && l:bufnr != s:term_bufnr
          \ && getbufvar(l:bufnr, '&buftype') ==# ''
          \ && !empty(bufname(l:bufnr))
      let l:fname = fnamemodify(bufname(l:bufnr), ':p')
      if getftime(l:fname) > getbufvar(l:bufnr, 'claudeterm_mtime', 0)
        call setbufvar(l:bufnr, 'claudeterm_mtime', getftime(l:fname))
        if bufloaded(l:bufnr)
          execute 'checktime ' . l:bufnr
          let l:reloaded = 1
        endif
      endif
    endif
  endfor
  if l:reloaded
    if s:get('notify_reload', 1)
      echohl WarningMsg | echo 'claudeterm: buffers reloaded' | echohl None
    endif
    call claudeterm#hooks#fire('Reload')
  endif
endfunction

" ---------------------------------------------------------------------------
" Tab-completion helper
" ---------------------------------------------------------------------------

function! claudeterm#complete(arglead, cmdline, cursorpos) abort
  let l:parts = split(a:cmdline, '\s\+')
  let l:nparts = len(l:parts)

  " Second word: subcommand
  if l:nparts <= 2
    let l:subs = ['resume', 'continue', 'new', 'kill', 'pr', 'worktree',
          \ 'plan', 'fast', 'mode', 'zoom', 'position', 'send', 'chat',
          \ 'model', 'verbose', 'doctor', 'version']
    return filter(copy(l:subs), 'v:val =~# "^" . a:arglead')
  endif

  " Third word: sub-subcommand
  let l:sub = l:parts[1]
  if l:sub ==# 'mode'
    let l:modes = ['plan', 'fast', 'normal']
    return filter(copy(l:modes), 'v:val =~# "^" . a:arglead')
  elseif l:sub ==# 'model'
    let l:models = ['sonnet', 'opus', 'haiku']
    return filter(copy(l:models), 'v:val =~# "^" . a:arglead')
  elseif l:sub ==# 'position'
    let l:positions = ['right', 'left', 'top', 'bottom']
    return filter(copy(l:positions), 'v:val =~# "^" . a:arglead')
  endif

  return []
endfunction
