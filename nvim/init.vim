" Syntax colors
syntax on

" Whitespaces
set listchars=eol:$,tab:>-,trail:·,extends:>,precedes:<,space:· 
set list

" Line numbers
set number
nmap <C-N><C-N> :set invnumber<CR>

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4

" 80 column mark
set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

" Scroll wheel navigating
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Load vim-plug
if empty(glob("~/.local/share/nvim/site/autoload/plug.vim"))
    execute 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')
" Git wrapper
Plug 'tpope/vim-fugitive'
" Line up text
Plug 'godlygeek/tabular'
" Markdown stuff
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
" Rename files
Plug 'danro/rename.vim'
" Project tree
Plug 'scrooloose/nerdtree'
call plug#end()

