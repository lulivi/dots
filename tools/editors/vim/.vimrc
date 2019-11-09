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
set number
nmap <C-N><C-N> :set invnu<CR>:set invlist<CR>

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4

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

