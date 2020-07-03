" Syntax colors
syntax on

" Whitespaces
set listchars=eol:$,tab:>-,trail:·,extends:>,precedes:<,space:·
set list

if !exists(':TrimWhitespace')
    command TrimWhitespace :%s/\s\+$//e
endif

if !exists(':Black')
    command Black :!black -l 79 %:p
endif

" Line numbers
set rnu nu
nmap <C-N><C-N> :set invrnu<CR>:set invnu<CR>:set invlist<CR>

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4

" Smart indent
set smartindent

" 80 column mark
set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

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
