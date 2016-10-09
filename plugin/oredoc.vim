if exists('g:loaded_oredoc_vim')
  finish
endif
let g:loaded_oredoc_vim = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 OredocSearch call oredoc#search(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

