" vim-circuit: lifecycle hook utilities
" Maintainer: inknos
" License: MIT

" Fire a User autocommand with CT prefix.
" All hooks are silent -- if no autocmd is registered, nothing happens.
function! circuit#hooks#fire(event) abort
  let l:name = 'CT' . a:event
  if exists('#User#' . l:name)
    execute 'doautocmd User ' . l:name
  endif
endfunction
