" Syntax colors
syntax on

" Whitespaces
let listchars_str = 'eol:$,tab:>-,trail:·,extends:>,precedes:<'
if has("patch-7.4.710")
    let listchars_str .= ',space:·'
endif
exe 'set listchars=' . listchars_str
set list

if !exists(':TrimWhitespace')
    command TrimWhitespace :%s/\s\+$//e
endif

if !exists(':Black')
    command Black :!black -l 79 %:p
endif

" Line numbers
set nu
let line_numbers_str = ':set invnu<CR>:set invlist<CR>'
if v:version > 703
    set rnu
    let line_numbers_str .= ':set invrnu <CR>'
endif
exe 'nmap <C-N><C-N> ' . line_numbers_str

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4

" Smart indent
set smartindent

" 80 column mark
if has("patch-7.3.799")
    set colorcolumn=80
    highlight ColorColumn ctermbg=darkgray
endif

" Folding
set nofoldenable "enable with zc

" Scroll wheel navigating
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Autocmd
autocmd BufNewFile,BufRead *.texw set syntax=tex

" Status line
set laststatus=2
set statusline=
set statusline+=%2*\ %l
set statusline+=\ %*
set statusline+=%1*\ ‹‹\ 
set statusline+=%1*%F%*
set statusline+=%1*\ ››\ 
set statusline+=%=
set statusline+=%3*\ ‹‹\ 
set statusline+=%3*w-%{wordcount().words}
set statusline+=%3*\ ::\ 
set statusline+=%3*l-%l,\ c-%c
set statusline+=%3*\ ››\ %*

hi User1 guifg=#FFFFFF guibg=#191f26 gui=BOLD
hi User2 guifg=#000000 guibg=#959ca6
hi User3 guifg=#000000 guibg=#4cbf99
