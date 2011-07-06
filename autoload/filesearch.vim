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

" Compatibility Guard {{{1
" ============================================================================
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" 1}}}

" Global Plugin Options {{{1
" =============================================================================
if !exists("g:filesearch_viewport_split_policy")
    let g:filesearch_viewport_split_policy = "B"
endif
if !exists("g:filesearch_move_wrap")
    let g:filesearch_move_wrap = 1
endif
if !exists("g:filesearch_autodismiss_on_select")
    let g:filesearch_autodismiss_on_select = 1
endif
if !exists("g:filesearch_autoexpand_on_split")
    let g:filesearch_autoexpand_on_split = 1
endif
if !exists("g:filesearch_split_size")
    let g:filesearch_split_size = 40
endif
if !exists("g:filesearch_sort_regime")
    let g:filesearch_sort_regime = "fullfilepath"
endif
if !exists("g:filesearch_display_regime")
    let g:filesearch_display_regime = "fullfilepath"
endif
if !exists("g:filesearch_ignore_hidden")
    let g:filesearch_ignore_hidden = 1
endif
" 1}}}

" Script Data and Variables {{{1
" =============================================================================

" Split Modes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Split modes are indicated by a single letter. Upper-case letters indicate
" that the SCREEN (i.e., the entire application "window" from the operating
" system's perspective) should be split, while lower-case letters indicate
" that the VIEWPORT (i.e., the "window" in Vim's terminology, referring to the
" various subpanels or splits within Vim) should be split.
" Split policy indicators and their corresponding modes are:
"   ``/`d`/`D'  : use default splitting mode
"   `n`/`N`     : NO split, use existing window.
"   `L`         : split SCREEN vertically, with new split on the left
"   `l`         : split VIEWPORT vertically, with new split on the left
"   `R`         : split SCREEN vertically, with new split on the right
"   `r`         : split VIEWPORT vertically, with new split on the right
"   `T`         : split SCREEN horizontally, with new split on the top
"   `t`         : split VIEWPORT horizontally, with new split on the top
"   `B`         : split SCREEN horizontally, with new split on the bottom
"   `b`         : split VIEWPORT horizontally, with new split on the bottom
let s:filesearch_viewport_split_modes = {
            \ "d"   : "sp",
            \ "D"   : "sp",
            \ "N"   : "buffer",
            \ "n"   : "buffer",
            \ "L"   : "topleft vert sbuffer",
            \ "l"   : "leftabove vert sbuffer",
            \ "R"   : "botright vert sbuffer",
            \ "r"   : "rightbelow vert sbuffer",
            \ "T"   : "topleft sbuffer",
            \ "t"   : "leftabove sbuffer",
            \ "B"   : "botright sbuffer",
            \ "b"   : "rightbelow sbuffer",
            \ }
" 2}}}

" Catalog Sort Regimes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:filesearch_catalog_sort_regimes = ['basename', 'fullfilepath', 'relfilepath', 'extension']
let s:filesearch_catalog_sort_regime_desc = {
            \ 'basename' : ["basename", "by basename (followed by directory)"],
            \ 'relfilepath' : ["filepath", "by relative filepath"],
            \ 'fullfilepath' : ["filepath", "by full filepath"],
            \ 'extension'  : ["ext", "by extension (followed by full filepath)"],
            \ }
" 2}}}

" Catalog Display Regimes {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:filesearch_catalog_display_regimes = ['fullfilepath', 'relfilepath', 'basename']
let s:filesearch_catalog_display_regime_desc = {
            \ 'fullfilepath' : ["fullfilepath", "full filepath"],
            \ 'relfilepath' : ["relfilepath", "relative filepath"],
            \ 'basename'  : ["basename", "basename"],
            \ }
" 2}}}

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
let s:filesearch_default_filetype_filters = [
            \ '^\.git',
            \ '^\.svn',
            \]
let s:filesearch_filetype_filters = {
            \ 'as' :           '\.\(as\|mxml\)$',
            \ 'ada' :          '\.\(ada\|adb\|ads\)$',
            \ 'asm' :          '\.\(asm\|s\)$',
            \ 'batch' :        '\.\(bat\|cmd\)$',
            \ 'cc' :           '\.\(c\|h\|xs\)$',
            \ 'cfmx' :         '\.\(cfc\|cfm\|cfml\)$',
            \ 'cpp' :          '\.\(cpp\|cc\|cxx\|m\|hpp\|hh\|h\|hxx\)$',
            \ 'csharp' :       '\.\(cs\)$',
            \ 'css' :          '\.\(css\)$',
            \ 'elisp' :        '\.\(el\)$',
            \ 'erlang' :       '\.\(erl\|hrl\)$',
            \ 'fortran' :      '\.\(f\|f77\|f90\|f95\|f03\|for\|ftn\|fpp\)$',
            \ 'haskell' :      '\.\(hs\|lhs\)$',
            \ 'hh' :           '\.\(h\)$',
            \ 'html' :         '\.\(htm\|html\|shtml\|xhtml\)$',
            \ 'java' :         '\.\(java\|properties\)$',
            \ 'js' :           '\.\(js\)$',
            \ 'jsp' :          '\.\(jsp\|jspx\|jhtm\|jhtml\)$',
            \ 'lisp' :         '\.\(lisp\|lsp\)$',
            \ 'lua' :          '\.\(lua\)$',
            \ 'make' :         'Makefile',
            \ 'mason' :        '\.\(mas\|mhtml\|mpl\|mtxt\)$',
            \ 'objc' :         '\.\(m\|h\)$',
            \ 'objcpp' :       '\.\(mm\|h\)$',
            \ 'ocaml' :        '\.\(ml\|mli\)$',
            \ 'parrot' :       '\.\(pir\|pasm\|pmc\|ops\|pod\|pg\|tg\)$',
            \ 'perl' :         '\.\(pl\|pm\|pod\|t\)$',
            \ 'php' :          '\.\(php\|phpt\|php3\|php4\|php5\|phtml\)$',
            \ 'plone' :        '\.\(pt\|cpt\|metadata\|cpy\|py\)$',
            \ 'py' :           '\.\(py\)$',
            \ 'python' :       '\.\(py\)$',
            \ 'rake' :         'Rakefile',
            \ 'rst' :          '\.\(rst\|txt\|inc\)$',
            \ 'ruby' :         '\.\(rb\|rhtml\|rjs\|rxml\|erb\|rake\)$',
            \ 'scala' :        '\.\(scala\)$',
            \ 'scheme' :       '\.\(scm\|ss\)$',
            \ 'shell' :        '\.\(sh\|bash\|csh\|tcsh\|ksh\|zsh\)$',
            \ 'smalltalk' :    '\.\(st\)$',
            \ 'sql' :          '\.\(sql\|ctl\)$',
            \ 'tcl' :          '\.\(tcl\|itcl\|itk\)$',
            \ 'tex' :          '\.\(tex\|cls\|sty\)$',
            \ 'txt' :          '\.\(txt\)$',
            \ 'tt' :           '\.\(tt\|tt2\|ttml\)$',
            \ 'vb' :           '\.\(bas\|cls\|frm\|ctl\|vb\|resx\)$',
            \ 'vim' :          '\.\(vim\)$',
            \ 'xml' :          '\.\(xml\|dtd\|xslt\|ent\)$',
            \ 'yaml' :         '\.\(yaml\|yml\)$'
            \}
" 2}}}

" 1}}}

" Utilities {{{1
" ==============================================================================

" Text Processing {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function! s:_strip_whitespace(input_str)
    let result_str = substitute(a:input_str, '^\s*', '', 'g')
    let result_str = substitute(result_str, '\s*$', '', 'g')
    return result_str
endfunction

function! s:_format_align_left(text, width, fill_char)
    let l:fill = repeat(a:fill_char, a:width-len(a:text))
    return a:text . l:fill
endfunction

function! s:_format_align_right(text, width, fill_char)
    let l:fill = repeat(a:fill_char, a:width-len(a:text))
    return l:fill . a:text
endfunction

function! s:_format_time(secs)
    if exists("*strftime")
        return strftime("%Y-%m-%d %H:%M:%S", a:secs)
    else
        return (localtime() - a:secs) . " secs ago"
    endif
endfunction

function! s:_format_escaped_filename(file)
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

" trunc: -1 = truncate left, 0 = no truncate, +1 = truncate right
function! s:_format_truncated(str, max_len, trunc)
    if len(a:str) > a:max_len
        if a:trunc > 0
            return strpart(a:str, a:max_len - 4) . " ..."
        elseif a:trunc < 0
            return '... ' . strpart(a:str, len(a:str) - a:max_len + 4)
        endif
    else
        return a:str
    endif
endfunction

" Pads/truncates text to fit a given width.
" align: -1/0 = align left, 0 = no align, 1 = align right
" trunc: -1 = truncate left, 0 = no truncate, +1 = truncate right
function! s:_format_filled(str, width, align, trunc)
    let l:prepped = a:str
    if a:trunc != 0
        let l:prepped = s:Format_Truncate(a:str, a:width, a:trunc)
    endif
    if len(l:prepped) < a:width
        if a:align > 0
            let l:prepped = s:_format_align_right(l:prepped, a:width, " ")
        elseif a:align < 0
            let l:prepped = s:_format_align_left(l:prepped, a:width, " ")
        endif
    endif
    return l:prepped
endfunction

" Input: [<delimiter>]<pattern>[<delimiter>[<opts>]] [args]
" Output: [pattern, opts, args]
function! s:_tokenize_command(input_str)
    let cmdstr = s:_strip_whitespace(a:input_str)

    let start_char = cmdstr[0]
    if start_char !~ '[A-Za-z0-9_.]'
        let end_pos = stridx(cmdstr, start_char, 1)
        if end_pos == -1
            call s:_filesearch_messenger.send_error("Invalid search pattern or delimiter: pattern starts with '" . start_char . "', but no matching termination delimiter found")
            " return ["", [], ""]
            return [-1, -1, -1]
        endif
        let pattern = strpart(cmdstr, 1, end_pos-1)
        let remaining = strpart(cmdstr, end_pos+1, len(cmdstr))
    else
        let pattern = cmdstr
        let remaining = ""
    endif
    let remaining_parts = split(remaining, ' ', 1)
    if len(remaining_parts) > 0
        let opts = s:_strip_whitespace(remaining_parts[0])
        if len(remaining_parts) > 1
            let pos_args = join(remaining_parts[1:], " ")
        else
            let pos_args = ""
        endif
    else
        let opts = ""
        let pos_args = ""
    endif
    return [pattern, opts, pos_args]
endfunction

function! s:_split_and_strip(text, delimiter)
    let parts = split(a:text, a:delimiter)
    let results = []
    for part in parts
        call add(results, s:_strip_whitespace(part))
    endfor
    return results
endfunction

function! s:_wrap_search_pattern(text)
    let l:wrap_chars = "/@#$%^&*'\";.,/()_-+=[]:;<>,.|{}~`!"
    let l:pattern_wrap = ""
    for idx in range(len(wrap_chars)+1)
        let char = wrap_chars[idx]
        if stridx(a:text, char) == -1
            let l:pattern_wrap = char
            break
        endif
    endfor
    if empty(l:pattern_wrap)
        let l:final_text = escape(a:text, '/')
    else
        let l:final_text = a:text
    endif
    return l:pattern_wrap . final_text . l:pattern_wrap
endfunction

" 2}}}

" Messaging {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function! s:NewMessenger(name)

    " allocate a new pseudo-object
    let l:messenger = {}
    let l:messenger["name"] = a:name
    if empty(a:name)
        let l:messenger["title"] = "filesearch"
    else
        let l:messenger["title"] = "filesearch (" . l:messenger["name"] . ")"
    endif

    function! l:messenger.format_message(leader, msg) dict
        return self.title . ": " . a:leader.a:msg
    endfunction

    function! l:messenger.format_exception( msg) dict
        return a:msg
    endfunction

    function! l:messenger.send_error(msg) dict
        redraw
        echohl ErrorMsg
        echomsg self.format_message("[ERROR] ", a:msg)
        echohl None
    endfunction

    function! l:messenger.send_warning(msg) dict
        redraw
        echohl WarningMsg
        echomsg self.format_message("[WARNING] ", a:msg)
        echohl None
    endfunction

    function! l:messenger.send_status(msg) dict
        redraw
        echohl None
        echomsg self.format_message("", a:msg)
    endfunction

    function! l:messenger.send_info(msg) dict
        redraw
        echohl None
        echo self.format_message("", a:msg)
    endfunction

    return l:messenger

endfunction
" 2}}}

" Catalog, Buffer, Windows, Files, etc. Management {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Searches for all buffers that have a buffer-scoped variable `varname`
" with value that matches the expression `expr`. Returns list of buffer
" numbers that meet the criterion.
function! s:_find_buffers_with_var(varname, expr)
    let l:results = []
    for l:bni in range(1, bufnr("$"))
        if !bufexists(l:bni)
            continue
        endif
        let l:bvar = getbufvar(l:bni, "")
        if empty(a:varname)
            call add(l:results, l:bni)
        elseif has_key(l:bvar, a:varname) && l:bvar[a:varname] =~ a:expr
            call add(l:results, l:bni)
        endif
    endfor
    return l:results
endfunction

" Returns split mode to use for a new Filesearch viewport.
function! s:_get_split_mode()
    if has_key(s:filesearch_viewport_split_modes, g:filesearch_viewport_split_policy)
        return s:filesearch_viewport_split_modes[g:filesearch_viewport_split_policy]
    else
        call s:_filesearch_messenger.send_error("Unrecognized split mode specified by 'g:filesearch_viewport_split_policy': " . g:filesearch_viewport_split_policy)
    endif
endfunction

" Detect filetype. From the 'taglist' plugin.
" Copyright (C) 2002-2007 Yegappan Lakshmanan
function! s:_detect_filetype(fname)
    " Ignore the filetype autocommands
    let old_eventignore = &eventignore
    set eventignore=FileType
    " Save the 'filetype', as this will be changed temporarily
    let old_filetype = &filetype
    " Run the filetypedetect group of autocommands to determine
    " the filetype
    exe 'doautocmd filetypedetect BufRead ' . a:fname
    " Save the detected filetype
    let ftype = &filetype
    " Restore the previous state
    let &filetype = old_filetype
    let &eventignore = old_eventignore
    return ftype
endfunction

function! s:_is_full_width_window(win_num)
    if winwidth(a:win_num) == &columns
        return 1
    else
        return 0
    endif
endfunction!

function! s:_is_full_height_window(win_num)
    if winheight(a:win_num) + &cmdheight + 1 == &lines
        return 1
    else
        return 0
    endif
endfunction!

" 2}}}

" Sorting {{{2
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" comparison function used for sorting dictionaries by value
function! s:_compare_dicts_by_value(m1, m2, key)
    if a:m1[a:key] < a:m2[a:key]
        return -1
    elseif a:m1[a:key] > a:m2[a:key]
        return 1
    else
        return 0
    endif
endfunction

" comparison function used for sorting buffers catalog by (relative) filepath
function! s:_compare_dicts_by_relfilepath(m1, m2)
    if a:m1["relfilepath"] < a:m2["relfilepath"]
        return -1
    elseif a:m1["relfilepath"] > a:m2["relfilepath"]
        return 1
    else
        if a:m1["linenum"] < a:m2["linenum"]
            return -1
        elseif a:m1["linenum"] > a:m2["linenum"]
            return 1
        else
            return 0
        endif
    endif
endfunction

" comparison function used for sorting buffers catalog by (full) filepath
function! s:_compare_dicts_by_fullfilepath(m1, m2)
    if a:m1["parentdir"] < a:m2["parentdir"]
        return -1
    elseif a:m1["parentdir"] > a:m2["parentdir"]
        return 1
    else
        if a:m1["basename"] < a:m2["basename"]
            return -1
        elseif a:m1["basename"] > a:m2["basename"]
            return 1
        else
            if a:m1["linenum"] < a:m2["linenum"]
                return -1
            elseif a:m1["linenum"] > a:m2["linenum"]
                return 1
            else
                return 0
            endif
        endif
    endif
endfunction

" comparison function used for sorting buffers catalog by extension
function! s:_compare_dicts_by_extension(m1, m2)
    if a:m1["extension"] < a:m2["extension"]
        return -1
    elseif a:m1["extension"] > a:m2["extension"]
        return 1
    else
        return s:_compare_dicts_by_fullfilepath(a:m1, a:m2)
    endif
endfunction

" comparison function used for sorting buffers catalog by basename
function! s:_compare_dicts_by_basename(m1, m2)
    let rank = s:_compare_dicts_by_value(a:m1, a:m2, "basename")
    if rank == 0
        if a:m1["linenum"] < a:m2["linenum"]
            return -1
        elseif a:m1["linenum"] > a:m2["linenum"]
            return 1
        else
            return 0
        endif
    else
        return rank
    endif
endfunction

" 2}}}

" 1}}}

" CatalogViewer {{{1
" ============================================================================

function! s:NewCatalogViewer(bufname)

    " initialize
    let l:catalog_viewer = {}

    " Initialize object state.
    let l:catalog_viewer["bufnum"] = -1
    let l:catalog_viewer["title"] = "filesearch"
    let l:catalog_viewer["bufname"] = "[[" . a:bufname . "]]"
    let l:catalog_viewer["bufclaim"] = "is_" . a:bufname . "_buffer"
    let l:filesearch_bufs = s:_find_buffers_with_var(l:catalog_viewer["bufclaim"], 1)
    if len(l:filesearch_bufs) > 0
        let l:catalog_viewer["bufnum"] = l:filesearch_bufs[0]
    endif
    let l:catalog_viewer["search_pattern"] = ""
    let l:catalog_viewer["search_opts"] = []
    let l:catalog_viewer["search_path_filters"] = []
    let l:catalog_viewer["search_paths"] = []
    let l:catalog_viewer["filepath_list"] = []
    let l:catalog_viewer["search_results_catalog"] = ""
    let l:catalog_viewer["jump_map"] = {}
    let l:catalog_viewer["split_mode"] = s:_get_split_mode()
    let l:catalog_viewer["sort_regime"] = g:filesearch_sort_regime
    let l:catalog_viewer["display_regime"] = g:filesearch_display_regime
    let l:catalog_viewer["calling_bufnum"] = -1
    let l:catalog_viewer["is_zoomed"] = 0
    let l:catalog_viewer["columns_expanded"] = 0
    let l:catalog_viewer["lines_expanded"] = 0

    " Populates the results list
    function! l:catalog_viewer.parse_search_command(command) dict
        if !empty(a:command)
            let [pattern, opts, pos_args] = s:_tokenize_command(a:command)
            if [pattern, opts, pos_args] == [-1, -1, -1]
                return 0
            endif
            if !empty(pattern)
                let self.search_pattern = pattern
            else
                let self.search_pattern = '*'
            endif
            if !empty(opts)
                let self.search_path_filters = []
                let self.search_opts = s:_split_and_strip(opts, ",")

                " if g:filesearch_ignore_hidden
                "     call add(self.search_path_filters, '^\.')
                " endif
                " call extend(self.search_path_filters, s:filesearch_default_filetype_filters)

                for sopt in self.search_opts
                    if has_key(s:filesearch_filetype_filters, sopt)
                        call add(self.search_path_filters, s:filesearch_filetype_filters[sopt])
                    else
                        call s:_filesearch_messenger.send_info("Invalid search option '" . sopt . "'")
                        return 0
                    endif
                endfor

            else
                let self.search_path_filters = []
                let self.search_opts = []
            endif
            if !empty(pos_args)
                let self.search_paths = [pos_args]
            else
                let self.search_paths = []
            endif
            if empty(self.search_paths)
                let self.search_paths = ['**']
            endif
        else
            " do nothing
        endif
        return 1
    endfunction

    " Populates the results list
    function! l:catalog_viewer.update_catalog_info(...) dict
        let self.search_results_catalog = []
        return 1
    endfunction

    " Opens the buffer for viewing, creating it if needed.
    " First argument, if given, should be a search command of
    function! l:catalog_viewer.open() dict

        " store calling buffer
        if (a:0 > 0 && a:1 > 0) "|| b:filesearch_catalog_viewer != self
            let self.calling_bufnum = a:1
        else
            let self.calling_bufnum = bufnr("%")
        endif

        let l:found_matches = self.update_catalog_info()
        if l:found_matches
            if self.bufnum < 0 || !bufexists(self.bufnum)
                call self.create_buffer()
            else
                call self.activate_viewport()
                call self.render_buffer()
            endif
        else
            if self.bufnum >= 0 && bufexists(self.bufnum)
                execute("silent keepalt keepjumps sb " . self.bufnum)
                call self.clear_buffer()
                call self.close()
            endif
        endif

        " populate data
        " let l:success = self.update_catalog_info()
        " if l:success
        "     " get buffer number of the catalog view buffer, creating it if neccessary
        "     if self.bufnum < 0 || !bufexists(self.bufnum)
        "         call self.create_buffer()
        "     else
        "         call self.activate_viewport()
        "         call self.render_buffer()
        "     endif
        " endif

    endfunction

    " populates search attributes

    " Opens viewer if closed, closes viewer if open.
    function! l:catalog_viewer.toggle() dict
        " get buffer number of the catalog view buffer, creating it if neccessary
        if self.bufnum < 0 || !bufexists(self.bufnum)
            call self.open()
        else
            let l:bfwn = bufwinnr(self.bufnum)
            if l:bfwn >= 0
                call self.close()
            else
                call self.open()
            endif
        endif
    endfunction

    " Creates a new buffer, renders and opens it.
    function! l:catalog_viewer.create_buffer() dict
        " get a new buf reference
        let self.bufnum = bufnr(self.bufname, 1)
        " get a viewport onto it
        call self.activate_viewport()
        " initialize it (includes "claiming" it)
        call self.initialize_buffer()
        " render it
        call self.render_buffer()
    endfunction

    " Opens a viewport on the buffer according, creating it if neccessary
    " according to the spawn mode. Valid buffer number must already have been
    " obtained before this is called.
    function! l:catalog_viewer.activate_viewport() dict
        let l:bfwn = bufwinnr(self.bufnum)
        if l:bfwn == winnr()
            " viewport wth buffer already active and current
            return
        elseif l:bfwn >= 0
            " viewport with buffer exists, but not current
            execute(l:bfwn . " wincmd w")
        else
            " create viewport
            let self.split_mode = s:_get_split_mode()
            call self.expand_screen()
            execute("silent keepalt keepjumps " . self.split_mode . " " . self.bufnum)
            if g:filesearch_viewport_split_policy =~ '[RrLl]' && g:filesearch_split_size
                execute("vertical resize " . g:filesearch_split_size)
            elseif g:filesearch_viewport_split_policy =~ '[TtBb]' && g:filesearch_split_size
                execute("resize " . g:filesearch_split_size)
            endif
        endif
    endfunction

    " Sets up buffer environment.
    function! l:catalog_viewer.initialize_buffer() dict
        call self.claim_buffer()
        call self.setup_buffer_opts()
        call self.setup_buffer_syntax()
        call self.setup_buffer_commands()
        call self.setup_buffer_keymaps()
        call self.setup_buffer_folding()
        call self.setup_buffer_statusline()
    endfunction

    " Sets buffer status line.
    function! l:catalog_viewer.setup_buffer_statusline() dict
        setlocal statusline=%{FilesearchStatusLine()}
    endfunction

    " 'Claims' a buffer by setting it to point at self.
    function! l:catalog_viewer.claim_buffer() dict
        call setbufvar("%", self.bufclaim, 1)
        call setbufvar("%", "filesearch_catalog_viewer", self)
        call setbufvar("%", "filesearch_last_render_time", 0)
        call setbufvar("%", "filesearch_cur_line", 0)
    endfunction

    " 'Unclaims' a buffer by stripping all filesearch vars
    function! l:catalog_viewer.unclaim_buffer() dict
        for l:var in ["is_filesearch_buffer",
                    \ "filesearch_catalog_viewer",
                    \ "filesearch_last_render_time",
                    \ "filesearch_cur_line"
                    \ ]
            if exists("b:" . l:var)
                unlet b:{l:var}
            endif
        endfor
    endfunction

    " Sets buffer options.
    function! l:catalog_viewer.setup_buffer_opts() dict
        setlocal buftype=nofile
        setlocal noswapfile
        setlocal nowrap
        set bufhidden=hide
        setlocal nobuflisted
        setlocal nolist
        setlocal noinsertmode
        setlocal nonumber
        setlocal cursorline
        setlocal nospell
    endfunction

    " Sets buffer syntax.
    function! l:catalog_viewer.setup_buffer_syntax() dict
        if has("syntax")
            syntax clear
            highlight! def FilesearchCurrentEntry gui=reverse cterm=reverse term=reverse
        endif
    endfunction

    " Sets buffer commands.
    function! l:catalog_viewer.setup_buffer_commands() dict
        " command! -bang -nargs=* Bdfilter :call b:filesearch_catalog_viewer.set_filter('<bang>', <q-args>)
        augroup FilesearchCatalogViewer
            au!
            autocmd CursorHold,CursorHoldI,CursorMoved,CursorMovedI,BufEnter,BufLeave <buffer> call b:filesearch_catalog_viewer.highlight_current_line()
            autocmd BufLeave <buffer> let s:_filesearch_last_catalog_viewed = b:filesearch_catalog_viewer
        augroup END
    endfunction

    " Sets buffer key maps.
    function! l:catalog_viewer.setup_buffer_keymaps() dict

        """" Disabling of unused modification keys
        for key in [".", "p", "P", "C", "x", "X", "r", "R", "i", "I", "a", "A", "D", "S", "U"]
            try
                execute "nnoremap <buffer> " . key . " <NOP>"
            catch //
            endtry
        endfor

        """" Catalog management
        noremap <buffer> <silent> cs          :call b:filesearch_catalog_viewer.cycle_sort_regime()<CR>
        noremap <buffer> <silent> cd          :call b:filesearch_catalog_viewer.cycle_display_regime()<CR>
        noremap <buffer> <silent> r           :call b:filesearch_catalog_viewer.rebuild_catalog()<CR>
        noremap <buffer> <silent> q           :call b:filesearch_catalog_viewer.close()<CR>

        """"" Selection: show target and switch focus
        noremap <buffer> <silent> <CR>        :call b:filesearch_catalog_viewer.visit_target(!g:filesearch_autodismiss_on_select, 0, "")<CR>
        noremap <buffer> <silent> o           :call b:filesearch_catalog_viewer.visit_target(!g:filesearch_autodismiss_on_select, 0, "")<CR>
        noremap <buffer> <silent> s           :call b:filesearch_catalog_viewer.visit_target(!g:filesearch_autodismiss_on_select, 0, "vert split")<CR>
        noremap <buffer> <silent> i           :call b:filesearch_catalog_viewer.visit_target(!g:filesearch_autodismiss_on_select, 0, "split")<CR>
        noremap <buffer> <silent> t           :call b:filesearch_catalog_viewer.visit_target(!g:filesearch_autodismiss_on_select, 0, "tabedit")<CR>

        """"" Preview: show target , keeping focus on catalog
        noremap <buffer> <silent> O           :call b:filesearch_catalog_viewer.visit_target(1, 1, "")<CR>
        noremap <buffer> <silent> go          :call b:filesearch_catalog_viewer.visit_target(1, 1, "")<CR>
        noremap <buffer> <silent> S           :call b:filesearch_catalog_viewer.visit_target(1, 1, "vert split")<CR>
        noremap <buffer> <silent> gs          :call b:filesearch_catalog_viewer.visit_target(1, 1, "vert split")<CR>
        noremap <buffer> <silent> I           :call b:filesearch_catalog_viewer.visit_target(1, 1, "split")<CR>
        noremap <buffer> <silent> gi          :call b:filesearch_catalog_viewer.visit_target(1, 1, "split")<CR>
        noremap <buffer> <silent> T           :call b:filesearch_catalog_viewer.visit_target(1, 1, "tabedit")<CR>
        noremap <buffer> <silent> <SPACE>     :<C-U>call b:filesearch_catalog_viewer.goto_index_entry("n", 1, 1)<CR>
        noremap <buffer> <silent> <C-SPACE>   :<C-U>call b:filesearch_catalog_viewer.goto_index_entry("p", 1, 1)<CR>
        noremap <buffer> <silent> <C-@>       :<C-U>call b:filesearch_catalog_viewer.goto_index_entry("p", 1, 1)<CR>

        " jump to next/prev key entry
        noremap <buffer> <silent> <C-N>  :<C-U>call b:filesearch_catalog_viewer.goto_index_entry("n", 0, 1)<CR>
        noremap <buffer> <silent> <C-P>  :<C-U>call b:filesearch_catalog_viewer.goto_index_entry("p", 0, 1)<CR>

        " jump to next/prev file entry
        noremap <buffer> <silent> ]f     :<C-U>call b:filesearch_catalog_viewer.goto_file_start("n", 0, 1)<CR>
        noremap <buffer> <silent> [f     :<C-U>call b:filesearch_catalog_viewer.goto_file_start("p", 0, 1)<CR>

        " other
        noremap <buffer> <silent> A           :call b:filesearch_catalog_viewer.toggle_zoom()<CR>

    endfunction

    " Sets buffer folding.
    function! l:catalog_viewer.setup_buffer_folding() dict
        " if has("folding")
        "     "setlocal foldcolumn=3
        "     setlocal foldmethod=syntax
        "     setlocal foldlevel=4
            setlocal nofoldenable
        "     setlocal foldtext=FilesearchFoldText()
        "     " setlocal fillchars=fold:\ "
        "     setlocal fillchars=fold:.
        " endif
    endfunction

    " Populates the buffer with the catalog index.

    " Appends a line to the buffer and registers it in the line log.
    function! l:catalog_viewer.append_line(text, filepath, linenum) dict
        let l:line_map = {
                    \ "target" : [a:filepath, a:linenum],
                    \ }
        if a:0 > 0
            call extend(l:line_map, a:1)
        endif
        let self.jump_map[line("$")] = l:line_map
        call append(line("$")-1, a:text)
    endfunction

    " Close and quit the viewer.
    function! l:catalog_viewer.close() dict
        if self.bufnum < 0 || !bufexists(self.bufnum)
            return
        endif
        call self.contract_screen()
        execute("bwipe " . self.bufnum)
    endfunction

    function! l:catalog_viewer.expand_screen() dict
        if has("gui_running") && g:filesearch_autoexpand_on_split && g:filesearch_split_size
            if g:filesearch_viewport_split_policy =~ '[RL]'
                let self.pre_expand_columns = &columns
                let &columns += g:filesearch_split_size
                let self.columns_expanded = &columns - self.pre_expand_columns
            else
                let self.columns_expanded = 0
            endif
            if g:filesearch_viewport_split_policy =~ '[TB]'
                let self.pre_expand_lines = &lines
                let &lines += g:filesearch_split_size
                let self.lines_expanded = &lines - self.pre_expand_lines
            else
                let self.lines_expanded = 0
            endif
        endif
    endfunction

    function! l:catalog_viewer.contract_screen() dict
        if self.columns_expanded
                    \ && &columns - self.columns_expanded > 20
            let new_size  = &columns - self.columns_expanded
            if new_size < self.pre_expand_columns
                let new_size = self.pre_expand_columns
            endif
            let &columns = new_size
        endif
        if self.lines_expanded
                    \ && &lines - self.lines_expanded > 20
            let new_size  = &lines - self.lines_expanded
            if new_size < self.pre_expand_lines
                let new_size = self.pre_expand_lines
            endif
            let &lines = new_size
        endif
    endfunction

    function! l:catalog_viewer.highlight_current_line()
        " if line(".") != b:filesearch_cur_line
            let l:prev_line = b:filesearch_cur_line
            let b:filesearch_cur_line = line(".")
            3match none
            exec '3match FilesearchCurrentEntry /^\%'. b:filesearch_cur_line .'l.*/'
        " endif
    endfunction

    " Clears the buffer contents.
    function! l:catalog_viewer.clear_buffer() dict
        call cursor(1, 1)
        exec 'silent! normal! "_dG'
    endfunction

    " from NERD_Tree, via VTreeExplorer: determine the number of windows open
    " to this buffer number.
    function! l:catalog_viewer.num_viewports_on_buffer(bnum) dict
        let cnt = 0
        let winnum = 1
        while 1
            let bufnum = winbufnr(winnum)
            if bufnum < 0
                break
            endif
            if bufnum ==# a:bnum
                let cnt = cnt + 1
            endif
            let winnum = winnum + 1
        endwhile
        return cnt
    endfunction

    " from NERD_Tree: find the window number of the first normal window
    function! l:catalog_viewer.first_usable_viewport() dict
        let i = 1
        while i <= winnr("$")
            let bnum = winbufnr(i)
            if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
                        \ && !getwinvar(i, '&previewwindow')
                        \ && (!getbufvar(bnum, '&modified') || &hidden)
                return i
            endif

            let i += 1
        endwhile
        return -1
    endfunction

    " from NERD_Tree: returns 0 if opening a file from the tree in the given
    " window requires it to be split, 1 otherwise
    function! l:catalog_viewer.is_usable_viewport(winnumber) dict
        "gotta split if theres only one window (i.e. the NERD tree)
        if winnr("$") ==# 1
            return 0
        endif
        let oldwinnr = winnr()
        execute(a:winnumber . "wincmd p")
        let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
        let modified = &modified
        execute(oldwinnr . "wincmd p")
        "if its a special window e.g. quickfix or another explorer plugin then we
        "have to split
        if specialWindow
            return 0
        endif
        if &hidden
            return 1
        endif
        return !modified || self.num_viewports_on_buffer(winbufnr(a:winnumber)) >= 2
    endfunction

    " Acquires a viewport to show the source buffer. Returns the split command
    " to use when switching to the buffer.
    function! l:catalog_viewer.acquire_viewport(split_cmd)
        if self.split_mode == "buffer" && empty(a:split_cmd)
            " filesearch used original buffer's viewport,
            " so the the filesearch viewport is the viewport to use
            return ""
        endif
        if !self.is_usable_viewport(winnr("#")) && self.first_usable_viewport() ==# -1
            " no appropriate viewport is available: create new using default
            " split mode
            " TODO: maybe use g:filesearch_viewport_split_policy?
            if empty(a:split_cmd)
                return "sb"
            else
                return a:split_cmd
            endif
        else
            try
                if !self.is_usable_viewport(winnr("#"))
                    execute(self.first_usable_viewport() . "wincmd w")
                else
                    execute('wincmd p')
                endif
            catch /^Vim\%((\a\+)\)\=:E37/
                echo v:exception
            catch /^Vim\%((\a\+)\)\=:/
                echo v:exception
            endtry
            return a:split_cmd
        endif
    endfunction

    " Visits the specified buffer in the previous window, if it is already
    " visible there. If not, then it looks for the first window with the
    " buffer showing and visits it there. If no windows are showing the
    " buffer, ... ?
    function! l:catalog_viewer.visit_buffer(targetname, split_cmd) dict
        " acquire window
        let l:split_cmd = self.acquire_viewport(a:split_cmd)
        " switch to buffer in acquired window
        let l:old_switch_buf = &switchbuf
        if empty(l:split_cmd)
            " explicit split command not given: switch to buffer in current
            " window
            let &switchbuf="useopen"
            execute("silent keepalt keepjumps edit " . a:targetname)
        else
            " explcit split command given: split current window
            let &switchbuf="split"
            execute("silent keepalt keepjumps " . l:split_cmd . " " . a:targetname)
        endif
        let new_buf_num = bufnr('%')
        let &switchbuf=l:old_switch_buf
        return new_buf_num
    endfunction

    " Go to the selected buffer.
    function! l:catalog_viewer.visit_target(keep_catalog, refocus_catalog, split_cmd) dict
        let l:cur_line = line(".")
        if !has_key(l:self.jump_map, l:cur_line)
            call s:_filesearch_messenger.send_info("Not a valid navigation line")
            return 0
        endif
        let [l:jump_to_targetname, l:jump_to_lnum] = self.jump_map[l:cur_line].target
        let l:cur_tab_num = tabpagenr()
        if !a:keep_catalog
            call self.close()
        endif
        let l:jump_to_buf_num = self.visit_buffer(l:jump_to_targetname, a:split_cmd)
        " call setpos('.', [l:jump_to_buf_num, l:jump_to_lnum, 1, 0])
        call cursor(l:jump_to_lnum, 1)
        execute("normal! zt")
        if a:keep_catalog && a:refocus_catalog
            execute("tabnext " . l:cur_tab_num)
            execute(bufwinnr(self.bufnum) . "wincmd w")
        endif
        call s:_filesearch_messenger.send_info(expand(bufname(l:jump_to_targetname)))
    endfunction

    " Finds next line with occurrence of a file pattern.
    function! l:catalog_viewer.goto_file_start(direction, visit_target, refocus_catalog) dict
        let l:ok = self.goto_pattern('^\S', a:direction)
        execute("normal! zz")
        if l:ok && a:visit_target
            call self.visit_target(1, a:refocus_catalog, "")
        endif
    endfunction

    " Finds next occurrence of specified pattern.
    function! l:catalog_viewer.goto_pattern(pattern, direction) dict range
        if a:direction == "b" || a:direction == "p"
            let l:flags = "b"
            " call cursor(line(".")-1, 0)
        else
            let l:flags = ""
            " call cursor(line(".")+1, 0)
        endif
        if g:filesearch_move_wrap
            let l:flags .= "W"
        else
            let l:flags .= "w"
        endif
        let l:flags .= "e"
        let l:lnum = -1
        for i in range(v:count1)
            if search(a:pattern, l:flags) < 0
                break
            else
                let l:lnum = 1
            endif
        endfor
        if l:lnum < 0
            if l:flags[0] == "b"
                call s:_filesearch_messenger.send_info("No previous results")
            else
                call s:_filesearch_messenger.send_info("No more results")
            endif
            return 0
        else
            return 1
        endif
    endfunction

    " Cycles sort regime.
    function! l:catalog_viewer.cycle_sort_regime() dict
        let l:cur_regime = index(s:filesearch_catalog_sort_regimes, self.sort_regime)
        let l:cur_regime += 1
        if l:cur_regime < 0 || l:cur_regime >= len(s:filesearch_catalog_sort_regimes)
            let self.sort_regime = s:filesearch_catalog_sort_regimes[0]
        else
            let self.sort_regime = s:filesearch_catalog_sort_regimes[l:cur_regime]
        endif
        call self.open()
        let l:sort_desc = get(s:filesearch_catalog_sort_regime_desc, self.sort_regime, ["??", "in unspecified order"])[1]
        call s:_filesearch_messenger.send_info("sorted " . l:sort_desc)
    endfunction

    " Cycles display regime.
    function! l:catalog_viewer.cycle_display_regime() dict
        let l:cur_regime = index(s:filesearch_catalog_display_regimes, self.display_regime)
        let l:cur_regime += 1
        if l:cur_regime < 0 || l:cur_regime >= len(s:filesearch_catalog_display_regimes)
            let self.display_regime = s:filesearch_catalog_display_regimes[0]
        else
            let self.display_regime = s:filesearch_catalog_display_regimes[l:cur_regime]
        endif
        call self.open()
        let l:display_desc = get(s:filesearch_catalog_display_regime_desc, self.display_regime, ["??", "in unspecified order"])[1]
        call s:_filesearch_messenger.send_info("displaying " . l:display_desc)
    endfunction

    " Rebuilds catalog.
    function! l:catalog_viewer.rebuild_catalog() dict
        call self.open()
    endfunction

    " Zooms/unzooms window.
    function! l:catalog_viewer.toggle_zoom() dict
        let l:bfwn = bufwinnr(self.bufnum)
        if l:bfwn < 0
            return
        endif
        if self.is_zoomed
            " if s:_is_full_height_window(l:bfwn) && !s:_is_full_width_window(l:bfwn)
            if g:filesearch_viewport_split_policy =~ '[RrLl]'
                if !g:filesearch_split_size
                    let l:new_size = &columns / 3
                else
                    let l:new_size = g:filesearch_split_size
                endif
                if l:new_size > 0
                    execute("vertical resize " . string(l:new_size))
                endif
                let self.is_zoomed = 0
            " elseif s:_is_full_width_window(l:bfwn) && !s:_is_full_height_window(l:bfwn)
            elseif g:filesearch_viewport_split_policy =~ '[TtBb]'
                if !g:filesearch_split_size
                    let l:new_size = &lines / 3
                else
                    let l:new_size = g:filesearch_split_size
                endif
                if l:new_size > 0
                    execute("resize " . string(l:new_size))
                endif
                let self.is_zoomed = 0
            endif
        else
            " if s:_is_full_height_window(l:bfwn) && !s:_is_full_width_window(l:bfwn)
            if g:filesearch_viewport_split_policy =~ '[RrLl]'
                if &columns > 20
                    execute("vertical resize " . string(&columns-10))
                    let self.is_zoomed = 1
                endif
            " elseif s:_is_full_width_window(l:bfwn) && !s:_is_full_height_window(l:bfwn)
            elseif g:filesearch_viewport_split_policy =~ '[TtBb]'
                if &lines > 20
                    execute("resize " . string(&lines-10))
                    let self.is_zoomed = 1
                endif
            endif
        endif
    endfunction

    function! l:catalog_viewer.get_filepaths(glob_pattern, path_regexp_filters, search_paths, escape_paths) dict
        let filepaths_list = []
        let joined_search_paths = join(a:search_paths, ",")
        let filepaths_string = globpath(joined_search_paths, a:glob_pattern)
        if len(filepaths_string) > 0
            call extend(filepaths_list, split(filepaths_string, "\n"))
        endif
        if !empty(a:path_regexp_filters)
            let rxp = '\(' . join(a:path_regexp_filters, '\|') . '\)'
            call filter(filepaths_list, "v:val =~ '" . rxp . "'")
        endif
        if a:escape_paths
            let new_list = []
            for item in filepaths_list
                call add(new_list, s:_format_escaped_filename(fnamemodify(item, ":p")))
                " call add(new_list, substitute(item, " ", '\ ', "g"))
            endfor
            return new_list
        else
            return filepaths_list
        endif
    endfunction

    " return object
    return l:catalog_viewer

endfunction

" 1}}}

" FilesearchFindViewer {{{1
" ============================================================================

function! s:NewFilesearchFindViewer()

    " initialize
    let l:catalog_viewer = s:NewCatalogViewer("filesearch")

    function! l:catalog_viewer.populate_filepath_list() dict
        " implemented by derived classes
        self.filepath_list = []
    endfunction

    function! l:catalog_viewer.update_catalog_info() dict
        call self.populate_filepath_list()
        let self.search_results_catalog = []
        for fpath in self.filepath_list
            let fullfpath = fnamemodify(fpath, ":p")
            let ftype = getftype(fpath)
            if !(ftype == "file" || ftype == "link")
                continue
            endif
            let entry = {
                        \ 'fullfilepath': fullfpath,
                        \ 'relfilepath': fnamemodify(fpath, ":."),
                        \ 'basename': fnamemodify(fpath, ":t"),
                        \ 'parentdir': fnamemodify(fpath, ":p:h"),
                        \ 'extension': fnamemodify(fpath, ":e"),
                        \ 'escapedfilepath' : s:_format_escaped_filename(fullfpath),
                        \ 'type' : ftype,
                        \ 'linenum' : 1,
                        \ 'linetext' : "",
                        \}
            call add(self.search_results_catalog, entry)
        endfor
        if len(self.search_results_catalog) == 0
            call s:_filesearch_messenger.send_info("No matches")
            return 0
        endif
        let l:sort_func = "s:_compare_dicts_by_" . self.sort_regime
        call sort(self.search_results_catalog, l:sort_func)
        return 1
    endfunction

    function! l:catalog_viewer.render_buffer() dict
        setlocal modifiable
        call self.claim_buffer()
        call self.clear_buffer()
        call self.setup_buffer_syntax()
        let self.jump_map = {}
        let l:initial_line = 1
        for l:fileinfo in self.search_results_catalog
            let l:line = ""
            if self.display_regime == "basename"
                let l:line .= s:_format_align_left(l:fileinfo.basename, 30, " ")
                let l:line .= l:fileinfo.parentdir
            elseif self.display_regime == "fullfilepath"
                let l:line .= l:fileinfo.fullfilepath
            elseif self.display_regime == "relfilepath"
                let l:line .= l:fileinfo.relfilepath
            else
                throw s:_filesearch_messenger.format_exception("Invalid display regime: '" . self.display_regime . "'")
            endif
            call self.append_line(l:line, l:fileinfo.escapedfilepath, 1)
        endfor
        let b:filesearch_last_render_time = localtime()
        try
            " remove extra last line
            execute('normal! GV"_X')
        catch //
        endtry
        setlocal nomodifiable
        call cursor(l:initial_line, 1)
        " call self.goto_index_entry("n", 0, 1)
    endfunction

    " Finds next line with occurrence of a rendered index
    function! l:catalog_viewer.goto_index_entry(direction, visit_target, refocus_catalog) dict
        let l:ok = self.goto_pattern('^.', a:direction)
        execute("normal! zz")
        if l:ok && a:visit_target
            call self.visit_target(1, a:refocus_catalog, "")
        endif
    endfunction

    return l:catalog_viewer

endfunction

" 1}}}

" FilesearchFindGlobViewer {{{1
" ============================================================================

function! s:NewFilesearchFindGlobViewer()

    let l:catalog_viewer = s:NewFilesearchFindViewer()

    function! l:catalog_viewer.populate_filepath_list() dict
        if empty(self.search_pattern)
            let _search_pattern = "*"
        else
            let _search_pattern = self.search_pattern
        endif
        if empty(self.search_paths)
            let _search_paths = ["**"]
        else
            let _search_paths = self.search_paths
        endif
        let self.filepath_list = self.get_filepaths(_search_pattern, self.search_path_filters, _search_paths, 0)
        return self.filepath_list
    endfunction

    return l:catalog_viewer

endfunction

" 1}}}

" FilesearchFindRxViewer {{{1
" ============================================================================

function! s:NewFilesearchFindRxViewer()

    let l:catalog_viewer = s:NewFilesearchFindViewer()

    function! l:catalog_viewer.populate_filepath_list() dict
        if empty(self.search_paths)
            let _search_paths = ["**"]
        else
            let _search_paths = self.search_paths
        endif
        let self.filepath_list = self.get_filepaths("*", self.search_path_filters, _search_paths, 0)
        if !empty(self.search_pattern)
            call filter(self.filepath_list, "v:val =~ '" . self.search_pattern . "'")
        endif
        return self.filepath_list
    endfunction

    return l:catalog_viewer

endfunction

" 1}}}


" FilesearchGrepViewer {{{1
" ============================================================================
function! s:NewFilesearchGrepViewer()

    let l:catalog_viewer = s:NewCatalogViewer("filesearch")

    function! l:catalog_viewer.update_catalog_info() dict
        let flist = self.get_filepaths("*", self.search_path_filters, self.search_paths, 0)
        call filter(flist, 'getftype(v:val) == "file"')
        let self.filepath_list = []
        for fpath in flist
            call add(self.filepath_list, s:_format_escaped_filename(fpath))
        endfor
        let self.search_results_catalog = []
        if empty(self.search_pattern)
            call s:_filesearch_messenger.send_error("No search patterns defined")
            return 0
        endif
        let vgpattern = s:_wrap_search_pattern(self.search_pattern)
        if empty(self.filepath_list)
            call s:_filesearch_messenger.send_info("No matching/valid files found on path")
            return 0
        endif
        let path_args = " " . join(self.filepath_list, " ")
        let oldqflist = getqflist()
        try
            execute("noautocmd silent vimgrep " . vgpattern . "gj" . path_args)
        catch /E683/
            call s:_filesearch_messenger.send_error("Invalid path names: " . join(self.filepath_list, " "))
            call setqflist(oldqflist)
            return 0
        catch /E480/
            call s:_filesearch_messenger.send_info("No matches")
            call setqflist(oldqflist)
            return 0
        endtry
        let qfresults = getqflist()
        call setqflist(oldqflist)
        for result in qfresults
            let fpath = bufname(result['bufnr'])
            let fullfpath = fnamemodify(fpath, ":p")
            let entry = {
                        \ 'fullfilepath': fullfpath,
                        \ 'relfilepath': fnamemodify(fpath, ":."),
                        \ 'basename': fnamemodify(fpath, ":t"),
                        \ 'parentdir': fnamemodify(fpath, ":p:h"),
                        \ 'extension': fnamemodify(fpath, ":e"),
                        \ 'escapedfilepath' : fnameescape(fpath),
                        \ 'linenum' : result['lnum'],
                        \ 'linetext' : result['text'],
                        \}
            call add(self.search_results_catalog, entry)
        endfor
        let l:sort_func = "s:_compare_dicts_by_" . self.sort_regime
        call sort(self.search_results_catalog, l:sort_func)
        return 1
    endfunction


    " Sets buffer syntax.
    function! l:catalog_viewer.setup_buffer_syntax() dict
        if has("syntax")
            syntax clear
            syn match FilesearchSyntaxFileGroupTitle             '^\S.*$'                   nextgroup=FilesearchSyntaxUncontextedLineNum
            " syn match FilesearchSyntaxKey                        '^  \zs\[\s\{-}.\{-1,}\s\{-}\]\ze'       nextgroup=FilesearchSyntaxUncontextedLineNum
            syn match FilesearchSyntaxUncontextedLineNum         '\s\+\s*\zs\d\+\ze:'                nextgroup=FilesearchSyntaxUncontextedLineText
            highlight! link FilesearchSyntaxFileGroupTitle       Title
            " highlight! link FilesearchSyntaxKey                  Identifier
            highlight! link FilesearchSyntaxUncontextedLineNum   Question
            highlight! link FilesearchSyntaxUncontextedLineText  Normal
            highlight! def FilesearchCurrentEntry gui=reverse cterm=reverse term=reverse
        endif
    endfunction

    function! l:catalog_viewer.render_buffer() dict
        setlocal modifiable
        call self.claim_buffer()
        call self.clear_buffer()
        call self.setup_buffer_syntax()
        let self.jump_map = {}
        let l:initial_line = 1
        let l:filepath_group = ""
        for l:fileinfo in self.search_results_catalog
            if self.display_regime == "basename"
                let l:display_filepath = s:_format_align_left(l:fileinfo.basename, 30, " ")
                let l:display_filepath .= l:fileinfo.parentdir
            elseif self.display_regime == "fullfilepath"
                let l:display_filepath = l:fileinfo.fullfilepath
            elseif self.display_regime == "relfilepath"
                let l:display_filepath = l:fileinfo.relfilepath
            else
                throw s:_filesearch_messenger.format_exception("Invalid display regime: '" . self.display_regime . "'")
            endif
            if l:display_filepath != l:filepath_group
                let l:filepath_group = l:display_filepath
                call self.append_line(l:display_filepath,
                            \ l:fileinfo.escapedfilepath,
                            \ 1)
            endif
            let l:lnum_field = s:_format_align_right(l:fileinfo.linenum, 5, " ")
            let l:line = "  " .l:lnum_field . ': ' . l:fileinfo.linetext
            call self.append_line(l:line, l:fileinfo.escapedfilepath, l:fileinfo.linenum)
        endfor
        let b:filesearch_last_render_time = localtime()
        try
            " remove extra last line
            execute("normal! GVX")
        catch //
        endtry
        setlocal nomodifiable
        call cursor(l:initial_line, 1)
        " call self.goto_index_entry("n", 0, 1)
    endfunction

    " Finds next line with occurrence of a rendered index
    function! l:catalog_viewer.goto_index_entry(direction, visit_target, refocus_catalog) dict
        let l:ok = self.goto_pattern('^\s\+\d', a:direction)
        execute("normal! zz")
        if l:ok && a:visit_target
            call self.visit_target(1, a:refocus_catalog, "")
        endif
    endfunction

    return l:catalog_viewer

endfunction
" 1}}}

" Global Functions {{{1
" ==============================================================================
function! FilesearchStatusLine()
    let l:line = line(".")
    let l:status_line = "[[filesearch]]"
    if has_key(b:filesearch_catalog_viewer.jump_map, l:line)
        let l:status_line .= " Result " . string(l:line) . " of " . string(len(b:filesearch_catalog_viewer.search_results_catalog))
    endif
    return l:status_line
endfunction
" 1}}}

" Global Initialization {{{1
" ==============================================================================
if exists("s:_filesearch_messenger")
    unlet s:_filesearch_messenger
endif
let s:_filesearch_messenger = s:NewMessenger("")
let s:_filesearch_find_glob = s:NewFilesearchFindGlobViewer()
let s:_filesearch_find_rx = s:NewFilesearchFindRxViewer()
let s:_filesearch_grep = s:NewFilesearchGrepViewer()
" 1}}}

" Functions Supporting User Commands {{{1
" ==============================================================================

function! filesearch#OpenFilesearchFindGlob(command)
    let search_success = 1
    if !empty(a:command)
        let search_success = s:_filesearch_find_glob.parse_search_command(a:command)
    endif
    if search_success
        call s:_filesearch_find_glob.open()
    endif
endfunction

function! filesearch#OpenFilesearchFindRx(command)
    let search_success = 1
    if !empty(a:command)
        let search_success = s:_filesearch_find_rx.parse_search_command(a:command)
    endif
    if search_success
        call s:_filesearch_find_rx.open()
    endif
endfunction

function! filesearch#OpenFilesearchGrep(command)
    let search_success = 1
    if !empty(a:command)
        let search_success = s:_filesearch_grep.parse_search_command(a:command)
    endif
    if search_success
        call s:_filesearch_grep.open()
    endif
endfunction

" 1}}}

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" 1}}}

" vim:foldlevel=4:
