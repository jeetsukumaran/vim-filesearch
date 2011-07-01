""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  Filesearch
""
""  Vim filesystem search (grep and find) utility
""
""  Copyright 2011 Jeet Sukumaran.
""
""  This program is free software; you can redistribute it and/or modify
""  it under the terms of the GNU General Public License as published by
""  the Free Software Foundation; either version 3 of the License, or
""  (at your option) any later version.
""
""  This program is distributed in the hope that it will be useful,
""  but WITHOUT ANY WARRANTY; without even the implied warranty of
""  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
""  GNU General Public License <http://www.gnu.org/licenses/>
""  for more details.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reload and Compatibility Guard {{{1
" ============================================================================
" Reload protection.
if (exists('g:did_filesearch') && g:did_filesearch) || &cp || version < 700
    finish
endif
let g:did_filesearch = 1

" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim

" 1}}}

" Public Command and Key Maps {{{1
" ==============================================================================

command! -complete=file -bang -nargs=* Fsfind   :call filesearch#OpenFilesearchFindRx(<q-args>)
command! -complete=file -bang -nargs=* Fsglob   :call filesearch#OpenFilesearchFindGlob(<q-args>)
command! -complete=file -bang -nargs=* Fsgrep   :call filesearch#OpenFilesearchGrep(<q-args>)

if !exists('g:filesearch_suppress_keymaps') || !g:filesearch_suppress_keymaps
endif

" 1}}}

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" 1}}}

" vim:foldlevel=4: