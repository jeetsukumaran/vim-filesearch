Filesearch is a plugin for searching the local filesystem for files by name or
content. The searches can be done using either glob patterns (searching for
filenames only) or regular expression patterns (searching for filenames or file
content).

Three commands are provided:

    :Fsglob /{glob}/[filetype-options] [paths]

        Search filesystem for files with names matching the glob pattern
        given by {glob}, which can include wildcard characters.

    :Fsfind /{pattern}/[filetype-options] [paths]

        Search filesystem for files with names matching the regular expression
        pattern given by {pattern}.

    :Fsgrep /{pattern}/[filetype-options] [paths]

        Search filesystem for files with lines of content matching the regular
        expression pattern {pattern}.

By default searches are carried out recursively starting from the current
directory, but the search paths can be adjusted through the use of optional
arguments. Searches can also be restricted to specific filetypes through the
use of filetype filter options (e.g., "py" for Python files, "cpp" for C++
source and header files).

Results will be shown in new buffer (the "catalog viewer"). They can be
browsed using all the normal Vim movement keys, and can be selected for
viewing the in main (previous) window, a new vertical or horizontal split
window, or new tab page.

Detailed usage description is given in the help file, which can be viewed
on-line here:

    http://github.com/jeetsukumaran/vim-filesearch/blob/master/doc/filesearch.txt

The public source code repository can be found here:

    http://github.com/jeetsukumaran/vim-filesearch

