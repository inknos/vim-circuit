" vim-claudeterm: lifecycle hook utilities
" Maintainer: inknos
" License: MIT

" Fire a User autocommand with ClaudeTerm prefix.
" All hooks are silent -- if no autocmd is registered, nothing happens.
function! claudeterm#hooks#fire(event) abort
  let l:name = 'ClaudeTerm' . a:event
  if exists('#User#' . l:name)
    execute 'doautocmd User ' . l:name
  endif
endfunction
